###############################################################################
# Application layer
# Azure Container Apps host the chat UI / orchestration tier. The environment
# is VNet-injected into the delegated container apps subnet with an internal
# load balancer, so the app is only reachable from inside the network (e.g.
# fronted by Application Gateway / APIM developer portal in a full build-out).
###############################################################################

resource "azurerm_container_app_environment" "this" {
  name                           = "cae-${var.name_suffix}"
  location                       = var.location
  resource_group_name            = var.resource_group_name
  log_analytics_workspace_id     = var.log_analytics_workspace_id
  infrastructure_subnet_id       = var.container_apps_subnet_id
  internal_load_balancer_enabled = true
  zone_redundancy_enabled        = true
  tags                           = var.tags

  workload_profile {
    name                  = "Consumption"
    workload_profile_type = "Consumption"
  }
}

resource "azurerm_private_endpoint" "container_apps_environment" {
  name                = "pep-cae-${var.name_suffix}"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.private_endpoints_subnet_id
  tags                = var.tags

  private_service_connection {
    name                           = "psc-cae"
    private_connection_resource_id = azurerm_container_app_environment.this.id
    subresource_names              = ["managedEnvironments"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "cae-dns"
    private_dns_zone_ids = [var.container_apps_environment_private_dns_zone_id]
  }
}

resource "azurerm_user_assigned_identity" "chat" {
  name                = "id-ca-chatui-${var.name_suffix}"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

resource "azurerm_role_assignment" "chat_acr_pull" {
  scope                = var.container_registry_id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_user_assigned_identity.chat.principal_id

  skip_service_principal_aad_check = true
}

resource "azurerm_role_assignment" "container_app_openai_user" {
  scope                = var.foundry_account_id
  role_definition_name = "Cognitive Services OpenAI User"
  principal_id         = azurerm_user_assigned_identity.chat.principal_id

  skip_service_principal_aad_check = true
}

resource "azurerm_container_app" "chat" {
  name                         = "ca-chatui-${var.name_suffix}"
  container_app_environment_id = azurerm_container_app_environment.this.id
  resource_group_name          = var.resource_group_name
  revision_mode                = "Single"
  workload_profile_name        = "Consumption"
  tags                         = var.tags

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.chat.id]
  }

  registry {
    server   = var.container_registry_login_server
    identity = azurerm_user_assigned_identity.chat.id
  }

  template {
    min_replicas = 1
    max_replicas = 10

    container {
      name   = "chatui"
      image  = "${var.container_registry_login_server}/${var.app_image_name}:${var.app_image_tag}"
      cpu    = 0.5
      memory = "1Gi"

      env {
        name  = "AZURE_OPENAI_ENDPOINT"
        value = var.azure_openai_endpoint
      }
      env {
        name  = "AZURE_OPENAI_DEPLOYMENT"
        value = var.azure_openai_deployment
      }
      env {
        name  = "AZURE_OPENAI_API_VERSION"
        value = var.azure_openai_api_version
      }
      env {
        name  = "AZURE_CLIENT_ID"
        value = azurerm_user_assigned_identity.chat.client_id
      }
      env {
        name        = "APPLICATIONINSIGHTS_CONNECTION_STRING"
        secret_name = "appinsights-connection-string"
      }
    }

    http_scale_rule {
      name                = "http-scale"
      concurrent_requests = 50
    }
  }

  secret {
    name  = "appinsights-connection-string"
    value = var.app_insights_connection_string
  }

  ingress {
    external_enabled = true
    target_port      = 50505
    transport        = "auto"

    traffic_weight {
      latest_revision = true
      percentage      = 100
    }
  }

  depends_on = [
    azurerm_role_assignment.chat_acr_pull,
    azurerm_role_assignment.container_app_openai_user,
  ]
}

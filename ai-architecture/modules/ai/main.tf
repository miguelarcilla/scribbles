###############################################################################
# AI layer
# Microsoft Foundry (account + project) with the Foundry Agent Service, an
# Azure AI Search knowledge store, and a model deployment. All inference and
# management traffic is private; the agent egresses through the delegated
# subnet (routed through Azure Firewall by the network layer).
###############################################################################

locals {
  foundry_account_name = "aif-${var.name_suffix}-${var.random_suffix}"
  foundry_project_name = "proj-${var.name_suffix}"
  search_name          = "srch-${var.name_suffix}-${var.random_suffix}"
}

###############################################################################
# Azure AI Search (knowledge / vector store for the agent)
###############################################################################
resource "azurerm_search_service" "this" {
  name                          = local.search_name
  location                      = var.location
  resource_group_name           = var.resource_group_name
  sku                           = "standard"
  replica_count                 = 2
  partition_count               = 1
  public_network_access_enabled = false
  local_authentication_enabled  = false
  tags                          = var.tags

  identity {
    type = "SystemAssigned"
  }
}

resource "azurerm_private_endpoint" "search" {
  name                = "pep-search-${var.name_suffix}"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.private_endpoints_subnet_id
  tags                = var.tags

  private_service_connection {
    name                           = "psc-search"
    private_connection_resource_id = azurerm_search_service.this.id
    subresource_names              = ["searchService"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "search-dns"
    private_dns_zone_ids = [var.private_dns_zone_ids.search]
  }
}

###############################################################################
# Microsoft Foundry account (Cognitive Services AIServices with project mgmt)
# Network injection binds the Foundry Agent Service to the delegated egress
# subnet so that agent traffic stays inside the virtual network.
###############################################################################
resource "azapi_resource" "foundry" {
  type      = "Microsoft.CognitiveServices/accounts@2025-06-01"
  name      = local.foundry_account_name
  location  = var.location
  parent_id = "/subscriptions/${data.azurerm_client_config.current.subscription_id}/resourceGroups/${var.resource_group_name}"
  tags      = var.tags

  identity {
    type = "SystemAssigned"
  }

  body = {
    kind = "AIServices"
    sku = {
      name = "S0"
    }
    properties = {
      allowProjectManagement = true
      customSubDomainName    = local.foundry_account_name
      publicNetworkAccess    = "Disabled"
      disableLocalAuth       = true
      networkInjections = [
        {
          scenario                   = "agent"
          subnetArmId                = var.agents_egress_subnet_id
          useMicrosoftManagedNetwork = false
        }
      ]
    }
  }

  response_export_values = ["identity.principalId", "properties.endpoint"]
}

resource "azurerm_private_endpoint" "foundry" {
  name                = "pep-foundry-${var.name_suffix}"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.private_endpoints_subnet_id
  tags                = var.tags

  private_service_connection {
    name                           = "psc-foundry"
    private_connection_resource_id = azapi_resource.foundry.id
    subresource_names              = ["account"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name = "foundry-dns"
    private_dns_zone_ids = [
      var.private_dns_zone_ids.cognitiveservices,
      var.private_dns_zone_ids.openai,
      var.private_dns_zone_ids.aiservices,
    ]
  }
}

###############################################################################
# Model deployment exposed through the account (and load balanced by APIM)
###############################################################################
resource "azurerm_cognitive_deployment" "gpt" {
  name                 = var.gpt_model.name
  cognitive_account_id = azapi_resource.foundry.id

  model {
    format  = "OpenAI"
    name    = var.gpt_model.name
    version = var.gpt_model.version
  }

  sku {
    name     = var.gpt_model.sku_name
    capacity = var.gpt_model.capacity
  }
}

###############################################################################
# Foundry project + bring-your-own dependency connections + capability host
###############################################################################
resource "azapi_resource" "project" {
  type      = "Microsoft.CognitiveServices/accounts/projects@2025-06-01"
  name      = local.foundry_project_name
  location  = var.location
  parent_id = azapi_resource.foundry.id
  tags      = var.tags

  identity {
    type = "SystemAssigned"
  }

  body = {
    properties = {
      displayName = "Foundry baseline chat project"
      description = "Project hosting the prompt-based chat agent."
    }
  }

  response_export_values = ["identity.principalId"]
}

# Account-level connections to the BYO dependencies (AAD / managed identity auth).
resource "azapi_resource" "conn_cosmos" {
  type      = "Microsoft.CognitiveServices/accounts/connections@2025-06-01"
  name      = "cosmosdb-connection"
  parent_id = azapi_resource.foundry.id

  body = {
    properties = {
      category      = "CosmosDb"
      target        = var.cosmosdb_account_id
      authType      = "AAD"
      isSharedToAll = true
      metadata = {
        ApiType    = "Azure"
        ResourceId = var.cosmosdb_account_id
      }
    }
  }
}

resource "azapi_resource" "conn_storage" {
  type      = "Microsoft.CognitiveServices/accounts/connections@2025-06-01"
  name      = "storage-connection"
  parent_id = azapi_resource.foundry.id

  body = {
    properties = {
      category      = "AzureStorageAccount"
      target        = var.storage_account_id
      authType      = "AAD"
      isSharedToAll = true
      metadata = {
        ApiType    = "Azure"
        ResourceId = var.storage_account_id
      }
    }
  }
}

resource "azapi_resource" "conn_search" {
  type      = "Microsoft.CognitiveServices/accounts/connections@2025-06-01"
  name      = "search-connection"
  parent_id = azapi_resource.foundry.id

  body = {
    properties = {
      category      = "CognitiveSearch"
      target        = "https://${azurerm_search_service.this.name}.search.windows.net"
      authType      = "AAD"
      isSharedToAll = true
      metadata = {
        ApiType    = "Azure"
        ResourceId = azurerm_search_service.this.id
      }
    }
  }
}

# Capability host wires the agent's thread store (Cosmos), file store (Storage)
# and vector store (Search) to the project, completing the BYO setup.
resource "azapi_resource" "project_capability_host" {
  type      = "Microsoft.CognitiveServices/accounts/projects/capabilityHosts@2025-06-01"
  name      = "agents-capabilityhost"
  parent_id = azapi_resource.project.id

  schema_validation_enabled = false

  body = {
    properties = {
      capabilityHostKind       = "Agents"
      threadStorageConnections = [azapi_resource.conn_cosmos.name]
      storageConnections       = [azapi_resource.conn_storage.name]
      vectorStoreConnections   = [azapi_resource.conn_search.name]
    }
  }

  depends_on = [
    azurerm_role_assignment.project_cosmos_contributor,
    azurerm_role_assignment.project_storage_blob,
    azurerm_role_assignment.project_search_index,
    azurerm_role_assignment.project_search_service,
  ]
}

###############################################################################
# Role assignments - project managed identity -> BYO dependencies (data plane)
###############################################################################
locals {
  project_principal_id = azapi_resource.project.output.identity.principalId
}

resource "azurerm_role_assignment" "project_storage_blob" {
  scope                = var.storage_account_id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = local.project_principal_id
}

resource "azurerm_role_assignment" "project_cosmos_contributor" {
  scope                = var.cosmosdb_account_id
  role_definition_name = "Cosmos DB Operator"
  principal_id         = local.project_principal_id
}

resource "azurerm_role_assignment" "project_search_index" {
  scope                = azurerm_search_service.this.id
  role_definition_name = "Search Index Data Contributor"
  principal_id         = local.project_principal_id
}

resource "azurerm_role_assignment" "project_search_service" {
  scope                = azurerm_search_service.this.id
  role_definition_name = "Search Service Contributor"
  principal_id         = local.project_principal_id
}

# Allow the Foundry account identity to read from Search for grounding queries.
resource "azurerm_role_assignment" "foundry_search_reader" {
  scope                = azurerm_search_service.this.id
  role_definition_name = "Search Index Data Reader"
  principal_id         = azapi_resource.foundry.output.identity.principalId
}

###############################################################################
# Diagnostics
###############################################################################
resource "azurerm_monitor_diagnostic_setting" "foundry" {
  name                       = "diag-foundry"
  target_resource_id         = azapi_resource.foundry.id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  enabled_log {
    category = "Audit"
  }
  enabled_log {
    category = "RequestResponse"
  }
  enabled_metric {
    category = "AllMetrics"
  }
}

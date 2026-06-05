###############################################################################
# API Management layer (exposure + scale-out)
# APIM is deployed into the VNet in Internal mode, fronts the Microsoft Foundry
# inference endpoint, and load balances across backend instances using a
# round-robin policy. It authenticates to Foundry with its managed identity
# (Cognitive Services OpenAI User), removing keys from the application tier.
###############################################################################

resource "azurerm_api_management" "this" {
  name                = "apim-${var.name_suffix}"
  location            = var.location
  resource_group_name = var.resource_group_name
  publisher_name      = var.publisher_name
  publisher_email     = var.publisher_email

  # Developer tier supports Internal VNet injection for non-production reference
  # deployments. Use Premium (with zones) for production.
  sku_name = "Developer_1"

  virtual_network_type = "Internal"
  virtual_network_configuration {
    subnet_id = var.apim_subnet_id
  }

  identity {
    type = "SystemAssigned"
  }

  tags = var.tags
}

# APIM managed identity is granted least-privilege inference access to Foundry.
resource "azurerm_role_assignment" "apim_openai_user" {
  scope                = var.foundry_account_id
  role_definition_name = "Cognitive Services OpenAI User"
  principal_id         = azurerm_api_management.this.identity[0].principal_id
}

# Named backends representing the Foundry inference instances to balance across.
# In a multi-region / multi-instance design each backend targets a different
# Foundry account; here they illustrate the round-robin pool topology.
resource "azurerm_api_management_backend" "foundry" {
  for_each = toset(["foundry-1", "foundry-2"])

  name                = each.value
  resource_group_name = var.resource_group_name
  api_management_name = azurerm_api_management.this.name
  protocol            = "http"
  url                 = "${trimsuffix(var.foundry_inference_endpoint, "/")}/openai"
}

# OpenAI-compatible API surface exposed to consumers.
resource "azurerm_api_management_api" "openai" {
  name                  = "azure-openai"
  resource_group_name   = var.resource_group_name
  api_management_name   = azurerm_api_management.this.name
  revision              = "1"
  display_name          = "Azure OpenAI (Foundry)"
  path                  = "openai"
  protocols             = ["https"]
  subscription_required = true
  service_url           = "${trimsuffix(var.foundry_inference_endpoint, "/")}/openai"
}

# Catch-all operation so all OpenAI routes flow through the load-balancing policy.
resource "azurerm_api_management_api_operation" "passthrough" {
  operation_id        = "passthrough"
  api_name            = azurerm_api_management_api.openai.name
  api_management_name = azurerm_api_management.this.name
  resource_group_name = var.resource_group_name
  display_name        = "OpenAI passthrough"
  method              = "POST"
  url_template        = "/*"
  description         = "Routes all Azure OpenAI requests to the Foundry backend pool."
}

# Round-robin load balancing + managed identity auth + retry on failure.
resource "azurerm_api_management_api_policy" "openai" {
  api_name            = azurerm_api_management_api.openai.name
  api_management_name = azurerm_api_management.this.name
  resource_group_name = var.resource_group_name

  xml_content = <<XML
<policies>
  <inbound>
    <base />
    <!-- Acquire a token for Foundry using APIM's managed identity. -->
    <authentication-managed-identity resource="https://cognitiveservices.azure.com" output-token-variable-name="msi-access-token" ignore-error="false" />
    <set-header name="Authorization" exists-action="override">
      <value>@("Bearer " + (string)context.Variables["msi-access-token"])</value>
    </set-header>
    <!-- Static round-robin selection across the backend pool. -->
    <set-variable name="backendIndex" value="@(new Random().Next(1, 3))" />
    <choose>
      <when condition="@(context.Variables.GetValueOrDefault<int>("backendIndex") == 1)">
        <set-backend-service backend-id="foundry-1" />
      </when>
      <otherwise>
        <set-backend-service backend-id="foundry-2" />
      </otherwise>
    </choose>
  </inbound>
  <backend>
    <retry condition="@(context.Response != null &amp;&amp; (context.Response.StatusCode == 429 || context.Response.StatusCode >= 500))" count="2" interval="1" first-fast-retry="true">
      <forward-request buffer-request-body="true" />
    </retry>
  </backend>
  <outbound>
    <base />
  </outbound>
  <on-error>
    <base />
  </on-error>
</policies>
XML

  depends_on = [
    azurerm_api_management_backend.foundry,
    azurerm_api_management_api_operation.passthrough,
  ]
}

###############################################################################
# Observability
###############################################################################
resource "azurerm_api_management_logger" "appinsights" {
  name                = "appinsights-logger"
  api_management_name = azurerm_api_management.this.name
  resource_group_name = var.resource_group_name
  resource_id         = var.app_insights_id

  application_insights {
    instrumentation_key = var.app_insights_instrumentation_key
  }
}

resource "azurerm_monitor_diagnostic_setting" "apim" {
  name                       = "diag-apim"
  target_resource_id         = azurerm_api_management.this.id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  enabled_log {
    category = "GatewayLogs"
  }
  enabled_metric {
    category = "AllMetrics"
  }
}

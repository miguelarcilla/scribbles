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

###############################################################################
# Named Values - Configuration for Foundry API integration
###############################################################################

resource "azurerm_api_management_named_value" "foundry_api_version" {
  name                = "FoundryApiVersion"
  api_management_name = azurerm_api_management.this.name
  resource_group_name = var.resource_group_name
  display_name        = "Foundry-API-Version"
  value               = var.foundry_api_version
}

resource "azurerm_api_management_named_value" "foundry_endpoint_base" {
  name                = "FoundryEndpointBase"
  api_management_name = azurerm_api_management.this.name
  resource_group_name = var.resource_group_name
  display_name        = "Foundry-Endpoint-Base-URL"
  value               = trimsuffix(var.foundry_inference_endpoint, "/")
  secret              = false
}

###############################################################################
# Backends - Foundry inference instances for load balancing
###############################################################################

resource "azurerm_api_management_backend" "foundry_primary" {
  name                = "foundry-primary"
  resource_group_name = var.resource_group_name
  api_management_name = azurerm_api_management.this.name
  protocol            = "http"
  url                 = "${trimsuffix(var.foundry_inference_endpoint, "/")}/openai"

  description = "Primary Foundry inference backend"
}

resource "azurerm_api_management_backend" "foundry_secondary" {
  name                = "foundry-secondary"
  resource_group_name = var.resource_group_name
  api_management_name = azurerm_api_management.this.name
  protocol            = "http"
  url                 = "${trimsuffix(var.foundry_inference_endpoint, "/")}/openai"

  description = "Secondary Foundry inference backend (same endpoint for resilience)"
}

###############################################################################
# Azure OpenAI API - Imported from Foundry resource
###############################################################################

resource "azurerm_api_management_api" "azure_openai" {
  name                  = "azure-openai"
  resource_group_name   = var.resource_group_name
  api_management_name   = azurerm_api_management.this.name
  revision              = "1"
  display_name          = "Azure OpenAI (via Foundry)"
  path                  = "openai"
  protocols             = ["https"]
  subscription_required = true
  service_url           = "${trimsuffix(var.foundry_inference_endpoint, "/")}/openai"
  description           = "Azure OpenAI API surface proxied through Foundry with managed identity authentication"

  depends_on = [
    azurerm_api_management_backend.foundry_primary,
    azurerm_api_management_backend.foundry_secondary,
  ]
}

###############################################################################
# API Operations - Core Azure OpenAI endpoints
###############################################################################

# Chat Completions endpoint
resource "azurerm_api_management_api_operation" "chat_completions" {
  operation_id        = "CreateChatCompletion"
  api_name            = azurerm_api_management_api.azure_openai.name
  api_management_name = azurerm_api_management.this.name
  resource_group_name = var.resource_group_name
  display_name        = "Create Chat Completion"
  method              = "POST"
  url_template        = "/deployments/{deployment-id}/chat/completions"
  description         = "Creates a chat completion for the provided prompt and parameters."

  template_parameter {
    name        = "deployment-id"
    description = "Deployment ID of the model"
    required    = true
    type        = "string"
  }
}

# Embeddings endpoint
resource "azurerm_api_management_api_operation" "embeddings" {
  operation_id        = "CreateEmbedding"
  api_name            = azurerm_api_management_api.azure_openai.name
  api_management_name = azurerm_api_management.this.name
  resource_group_name = var.resource_group_name
  display_name        = "Create Embeddings"
  method              = "POST"
  url_template        = "/deployments/{deployment-id}/embeddings"
  description         = "Creates an embedding vector representing the input text."

  template_parameter {
    name        = "deployment-id"
    description = "Deployment ID of the embedding model"
    required    = true
    type        = "string"
  }
}

# List Models endpoint
resource "azurerm_api_management_api_operation" "list_models" {
  operation_id        = "ListModels"
  api_name            = azurerm_api_management_api.azure_openai.name
  api_management_name = azurerm_api_management.this.name
  resource_group_name = var.resource_group_name
  display_name        = "List Available Models"
  method              = "GET"
  url_template        = "/models"
  description         = "Lists the currently available models and their details."
}

###############################################################################
# API Policies - Global and operation-specific routing
###############################################################################

# Global API policy with managed identity authentication and load balancing
resource "azurerm_api_management_api_policy" "azure_openai_global" {
  api_name            = azurerm_api_management_api.azure_openai.name
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
    <!-- Round-robin load balancing between Foundry backends. -->
    <set-variable name="backendIndex" value="@(new Random().Next(0, 2))" />
    <choose>
      <when condition="@(context.Variables.GetValueOrDefault<int>("backendIndex") == 0)">
        <set-backend-service backend-id="foundry-primary" />
      </when>
      <otherwise>
        <set-backend-service backend-id="foundry-secondary" />
      </otherwise>
    </choose>
  </inbound>
  <backend>
    <!-- Retry on throttle (429) or server errors (5xx). -->
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
    azurerm_api_management_api_operation.chat_completions,
    azurerm_api_management_api_operation.embeddings,
    azurerm_api_management_api_operation.list_models,
  ]
}

# Operation policy for chat completions - specific request/response handling
resource "azurerm_api_management_api_operation_policy" "chat_completions_policy" {
  api_name            = azurerm_api_management_api.azure_openai.name
  api_management_name = azurerm_api_management.this.name
  resource_group_name = var.resource_group_name
  operation_id        = azurerm_api_management_api_operation.chat_completions.operation_id

  xml_content = <<XML
<policies>
  <inbound>
    <base />
  </inbound>
  <backend>
    <base />
  </backend>
  <outbound>
    <base />
  </outbound>
  <on-error>
    <base />
  </on-error>
</policies>
XML
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

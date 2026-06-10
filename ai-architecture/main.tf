###############################################################################
# Root module - Microsoft Foundry baseline secured with Private Endpoints,
# exposed and scaled out via Azure API Management.
#
# Layer composition:
#   network     -> VNet, subnets, NSGs, route table, Private DNS zones
#   management  -> Log Analytics, Application Insights, Key Vault
#   data        -> Storage account, Cosmos DB (Foundry Agent Service BYO deps)
#   ai          -> Microsoft Foundry account/project, AI Search, model deployment
#   application -> Azure Container Apps (VNet injected)
#   apim        -> API Management (internal) with round-robin load balancing
###############################################################################

data "azurerm_client_config" "current" {}

resource "random_string" "suffix" {
  length  = 5
  upper   = false
  special = false
}

locals {
  name_suffix = "${var.workload_name}-${var.environment}"
  base_tags = merge(var.tags, {
    environment = var.environment
  })
}

resource "azurerm_resource_group" "this" {
  name     = "rg-${local.name_suffix}"
  location = var.location
  tags     = local.base_tags
}

module "network" {
  source = "./modules/network"

  resource_group_name = azurerm_resource_group.this.name
  location            = var.location
  name_suffix         = local.name_suffix
  vnet_address_space  = var.vnet_address_space
  tags                = local.base_tags
}

module "management" {
  source = "./modules/management"

  resource_group_name         = azurerm_resource_group.this.name
  location                    = var.location
  name_suffix                 = local.name_suffix
  random_suffix               = random_string.suffix.result
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  private_endpoints_subnet_id = module.network.private_endpoints_subnet_id
  keyvault_dns_zone_id        = module.network.private_dns_zone_ids["vault"]
  tags                        = local.base_tags
}

module "data" {
  source = "./modules/data"

  resource_group_name         = azurerm_resource_group.this.name
  location                    = var.location
  name_suffix                 = local.name_suffix
  random_suffix               = random_string.suffix.result
  private_endpoints_subnet_id = module.network.private_endpoints_subnet_id
  log_analytics_workspace_id  = module.management.log_analytics_workspace_id
  private_dns_zone_ids = {
    blob       = module.network.private_dns_zone_ids["blob"]
    cosmos_sql = module.network.private_dns_zone_ids["cosmos_sql"]
  }
  tags = local.base_tags
}

module "ai" {
  source = "./modules/ai"

  resource_group_name         = azurerm_resource_group.this.name
  location                    = var.location
  search_location             = var.search_location
  name_suffix                 = local.name_suffix
  random_suffix               = random_string.suffix.result
  private_endpoints_subnet_id = module.network.private_endpoints_subnet_id
  agents_egress_subnet_id     = module.network.agents_egress_subnet_id
  log_analytics_workspace_id  = module.management.log_analytics_workspace_id

  gpt_model = var.gpt_model

  # Bring-your-own Foundry Agent Service dependencies.
  storage_account_id  = module.data.storage_account_id
  cosmosdb_account_id = module.data.cosmosdb_account_id

  private_dns_zone_ids = {
    cognitiveservices = module.network.private_dns_zone_ids["cognitiveservices"]
    openai            = module.network.private_dns_zone_ids["openai"]
    aiservices        = module.network.private_dns_zone_ids["aiservices"]
    search            = module.network.private_dns_zone_ids["search"]
  }

  tags = local.base_tags
}

module "application" {
  source = "./modules/application"

  resource_group_name            = azurerm_resource_group.this.name
  location                       = var.location
  name_suffix                    = local.name_suffix
  container_apps_subnet_id       = module.network.container_apps_subnet_id
  log_analytics_workspace_id     = module.management.log_analytics_workspace_id
  app_insights_connection_string = module.management.app_insights_connection_string

  # The app talks to Foundry over the APIM gateway endpoint.
  ai_gateway_endpoint      = module.apim.gateway_url
  foundry_project_endpoint = module.ai.foundry_project_endpoint

  tags = local.base_tags
}

module "apim" {
  source = "./modules/apim"

  resource_group_name              = azurerm_resource_group.this.name
  location                         = var.location
  name_suffix                      = local.name_suffix
  apim_subnet_id                   = module.network.apim_subnet_id
  log_analytics_workspace_id       = module.management.log_analytics_workspace_id
  app_insights_id                  = module.management.app_insights_id
  app_insights_instrumentation_key = module.management.app_insights_instrumentation_key

  publisher_name  = var.publisher_name
  publisher_email = var.publisher_email

  # Backends to load balance across (Foundry / OpenAI inference endpoints).
  foundry_account_id         = module.ai.foundry_account_id
  foundry_inference_endpoint = module.ai.foundry_inference_endpoint

  tags = local.base_tags

  depends_on = [module.network]
}

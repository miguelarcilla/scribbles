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

  jumpbox_subnet_id = module.network.jumpbox_subnet_id
  virtual_network_id = module.network.vnet_id

  jumpbox_admin_username = var.jumpbox_admin_username
  jumpbox_admin_password = var.jumpbox_admin_password

  jumpbox_vm_size      = var.jumpbox_vm_size
  jumpbox_license_type = var.jumpbox_license_type

  jumpbox_os_disk_storage_account_type = var.jumpbox_os_disk_storage_account_type
  jumpbox_os_disk_size_gb              = var.jumpbox_os_disk_size_gb

  jumpbox_image_reference = {
    publisher = var.jumpbox_image_publisher
    offer     = var.jumpbox_image_offer
    sku       = var.jumpbox_image_sku
    version   = var.jumpbox_image_version
  }

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
  storage_account_id    = module.data.storage_account_id
  storage_blob_endpoint = module.data.storage_blob_endpoint
  cosmosdb_account_id   = module.data.cosmosdb_account_id

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

  resource_group_name                            = azurerm_resource_group.this.name
  location                                       = var.location
  name_suffix                                    = local.name_suffix
  container_apps_subnet_id                       = module.network.container_apps_subnet_id
  private_endpoints_subnet_id                    = module.network.private_endpoints_subnet_id
  container_apps_environment_private_dns_zone_id = module.network.private_dns_zone_ids["container_apps"]
  log_analytics_workspace_id                     = module.management.log_analytics_workspace_id
  app_insights_connection_string                 = module.management.app_insights_connection_string
  container_registry_id                          = module.management.container_registry_id
  container_registry_login_server                = module.management.container_registry_login_server
  app_image_name                                 = var.app_image_name
  app_image_tag                                  = var.app_image_tag
  foundry_account_id                             = module.ai.foundry_account_id
  apim_id                                        = module.apim.apim_id
  apim_gateway_url                               = module.apim.gateway_url

  azure_openai_endpoint    = module.ai.foundry_inference_endpoint
  azure_openai_deployment  = var.gpt_model.name
  azure_openai_api_version = var.azure_openai_api_version

  tags = local.base_tags

  depends_on = [module.apim]
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
  foundry_api_version        = var.azure_openai_api_version

  tags = local.base_tags

  depends_on = [module.network]
}

###############################################################################
# Storage & data layer
# These resources are the "bring-your-own" dependencies that the Microsoft
# Foundry Agent Service manages (chat memory + agent state + file storage).
# Both are network isolated and reachable only through private endpoints.
#
# Resources created:
#   - azurerm_storage_account            — blob storage for Foundry agent files
#   - azurerm_private_endpoint           — private endpoint for blob storage
#   - azurerm_cosmosdb_account           — Cosmos DB (SQL API) for agent thread
#                                          memory and chat state
#   - azurerm_private_endpoint           — private endpoint for Cosmos DB
#   - azurerm_monitor_diagnostic_setting — Storage account diagnostics
#   - azurerm_monitor_diagnostic_setting — Cosmos DB diagnostics
###############################################################################

# ---- Azure Storage (Foundry agent file/blob storage) ----
resource "azurerm_storage_account" "this" {
  name                            = "st${substr(replace(var.name_suffix, "-", ""), 0, 14)}${var.random_suffix}"
  location                        = var.location
  resource_group_name             = var.resource_group_name
  account_tier                    = "Standard"
  account_replication_type        = "ZRS"
  account_kind                    = "StorageV2"
  min_tls_version                 = "TLS1_2"
  https_traffic_only_enabled      = true
  public_network_access_enabled   = false
  allow_nested_items_to_be_public = false
  shared_access_key_enabled       = false
  tags                            = var.tags

  network_rules {
    default_action = "Deny"
    bypass         = ["AzureServices"]
  }

}

resource "azurerm_private_endpoint" "blob" {
  name                = "pep-blob-${var.name_suffix}"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.private_endpoints_subnet_id
  tags                = var.tags

  private_service_connection {
    name                           = "psc-blob"
    private_connection_resource_id = azurerm_storage_account.this.id
    subresource_names              = ["blob"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "blob-dns"
    private_dns_zone_ids = [var.private_dns_zone_ids.blob]
  }
}

# ---- Azure Cosmos DB (Foundry agent chat-memory / thread store) ----
resource "azurerm_cosmosdb_account" "this" {
  name                          = "cosmos-${var.name_suffix}-${var.random_suffix}"
  location                      = var.location
  resource_group_name           = var.resource_group_name
  offer_type                    = "Standard"
  kind                          = "GlobalDocumentDB"
  public_network_access_enabled = false
  local_authentication_enabled  = false
  automatic_failover_enabled    = true
  tags                          = var.tags

  consistency_policy {
    consistency_level = "Session"
  }

  geo_location {
    location          = var.location
    failover_priority = 0
    zone_redundant    = false
  }

  capabilities {
    name = "EnableServerless"
  }
}

resource "azurerm_private_endpoint" "cosmos" {
  name                = "pep-cosmos-${var.name_suffix}"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.private_endpoints_subnet_id
  tags                = var.tags

  private_service_connection {
    name                           = "psc-cosmos"
    private_connection_resource_id = azurerm_cosmosdb_account.this.id
    subresource_names              = ["Sql"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "cosmos-dns"
    private_dns_zone_ids = [var.private_dns_zone_ids.cosmos_sql]
  }
}

# ---- Diagnostics ----
resource "azurerm_monitor_diagnostic_setting" "storage" {
  name                       = "diag-storage"
  target_resource_id         = "${azurerm_storage_account.this.id}/blobServices/default"
  log_analytics_workspace_id = var.log_analytics_workspace_id

  enabled_log {
    category = "StorageRead"
  }
  enabled_log {
    category = "StorageWrite"
  }
  enabled_metric {
    category = "Transaction"
  }
}

resource "azurerm_monitor_diagnostic_setting" "cosmos" {
  name                       = "diag-cosmos"
  target_resource_id         = azurerm_cosmosdb_account.this.id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  enabled_log {
    category = "DataPlaneRequests"
  }
  enabled_metric {
    category = "Requests"
  }
}

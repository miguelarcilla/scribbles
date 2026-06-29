###############################################################################
# Management layer
# Shared observability and secrets services: Log Analytics, Application
# Insights, and a network-isolated Key Vault.
###############################################################################

resource "azurerm_log_analytics_workspace" "this" {
  name                = "log-${var.name_suffix}"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = "PerGB2018"
  retention_in_days   = 30
  tags                = var.tags
}

resource "azurerm_application_insights" "this" {
  name                = "appi-${var.name_suffix}"
  location            = var.location
  resource_group_name = var.resource_group_name
  workspace_id        = azurerm_log_analytics_workspace.this.id
  application_type    = "web"
  tags                = var.tags
}

resource "azurerm_container_registry" "this" {
  name                = "acr${substr(replace(var.name_suffix, "-", ""), 0, 20)}${var.random_suffix}"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = "Standard"
  admin_enabled       = true
  tags                = var.tags
}

resource "azurerm_key_vault" "this" {
  name                          = "kv-${substr(replace(var.name_suffix, "-", ""), 0, 16)}${var.random_suffix}"
  location                      = var.location
  resource_group_name           = var.resource_group_name
  tenant_id                     = var.tenant_id
  sku_name                      = "standard"
  rbac_authorization_enabled    = true
  purge_protection_enabled      = true
  soft_delete_retention_days    = 7
  public_network_access_enabled = false
  tags                          = var.tags

  network_acls {
    default_action = "Deny"
    bypass         = "AzureServices"
  }
}

resource "azurerm_monitor_diagnostic_setting" "key_vault" {
  name                       = "diag-keyvault"
  target_resource_id         = azurerm_key_vault.this.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.this.id

  enabled_log {
    category = "AuditEvent"
  }

  enabled_metric {
    category = "AllMetrics"
  }
}

###############################################################################
# Private endpoint for Key Vault
###############################################################################

resource "azurerm_private_endpoint" "key_vault" {
  name                = "pep-kv-${var.name_suffix}"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.private_endpoints_subnet_id
  tags                = var.tags

  private_service_connection {
    name                           = "psc-kv"
    private_connection_resource_id = azurerm_key_vault.this.id
    subresource_names              = ["vault"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "kv-dns"
    private_dns_zone_ids = [var.keyvault_dns_zone_id]
  }
}

###############################################################################
# Jumpbox resources (moved from dedicated jumpbox module)
###############################################################################

resource "azurerm_network_interface" "jumpbox" {
  name                = "nic-jumpbox-${var.name_suffix}"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = var.jumpbox_subnet_id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_windows_virtual_machine" "jumpbox" {
  name                = "jumpbox"
  computer_name       = "jumpbox"
  location            = var.location
  resource_group_name = var.resource_group_name
  size                = var.jumpbox_vm_size
  admin_username      = var.jumpbox_admin_username
  admin_password      = var.jumpbox_admin_password
  network_interface_ids = [
    azurerm_network_interface.jumpbox.id,
  ]

  license_type               = var.jumpbox_license_type
  automatic_updates_enabled  = true
  provision_vm_agent         = true
  patch_mode                 = "AutomaticByOS"
  secure_boot_enabled        = true
  vtpm_enabled               = true
  tags                       = var.tags

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = var.jumpbox_os_disk_storage_account_type
    disk_size_gb         = var.jumpbox_os_disk_size_gb
  }

  source_image_reference {
    publisher = var.jumpbox_image_reference.publisher
    offer     = var.jumpbox_image_reference.offer
    sku       = var.jumpbox_image_reference.sku
    version   = var.jumpbox_image_reference.version
  }

  identity {
    type = "SystemAssigned"
  }

  boot_diagnostics {}
}

resource "azurerm_bastion_host" "developer" {
  name                = "bas-${var.name_suffix}"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = "Developer"
  virtual_network_id  = var.virtual_network_id
  tags                = var.tags
}

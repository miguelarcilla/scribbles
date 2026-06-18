###############################################################################
# Jumpbox layer
# Windows management VM in the dedicated jumpbox subnet, accessed through
# Azure Bastion Developer SKU attached to the workload virtual network.
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
  size                = var.vm_size
  admin_username      = var.admin_username
  admin_password      = var.admin_password
  network_interface_ids = [
    azurerm_network_interface.jumpbox.id,
  ]

  license_type                  = var.license_type
  automatic_updates_enabled     = true
  provision_vm_agent            = true
  patch_mode                    = "AutomaticByOS"
  secure_boot_enabled           = true
  vtpm_enabled                  = true
  tags                          = var.tags

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = var.os_disk_storage_account_type
    disk_size_gb         = var.os_disk_size_gb
  }

  source_image_reference {
    publisher = var.image_reference.publisher
    offer     = var.image_reference.offer
    sku       = var.image_reference.sku
    version   = var.image_reference.version
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

output "jumpbox_vm_id" {
  value = azurerm_windows_virtual_machine.jumpbox.id
}

output "jumpbox_private_ip" {
  value = azurerm_network_interface.jumpbox.ip_configuration[0].private_ip_address
}

output "bastion_id" {
  value = azurerm_bastion_host.developer.id
}

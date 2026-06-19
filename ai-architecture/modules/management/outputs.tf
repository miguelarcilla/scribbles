output "log_analytics_workspace_id" {
  value = azurerm_log_analytics_workspace.this.id
}

output "app_insights_id" {
  value = azurerm_application_insights.this.id
}

output "app_insights_connection_string" {
  value     = azurerm_application_insights.this.connection_string
  sensitive = true
}

output "app_insights_instrumentation_key" {
  value     = azurerm_application_insights.this.instrumentation_key
  sensitive = true
}

output "container_registry_id" {
  value = azurerm_container_registry.this.id
}

output "container_registry_name" {
  value = azurerm_container_registry.this.name
}

output "container_registry_login_server" {
  value = azurerm_container_registry.this.login_server
}

output "key_vault_id" {
  value = azurerm_key_vault.this.id
}

output "key_vault_uri" {
  value = azurerm_key_vault.this.vault_uri
}

output "jumpbox_vm_id" {
  value = azurerm_windows_virtual_machine.jumpbox.id
}

output "jumpbox_private_ip" {
  value = azurerm_network_interface.jumpbox.ip_configuration[0].private_ip_address
}

output "bastion_id" {
  value = azurerm_bastion_host.developer.id
}

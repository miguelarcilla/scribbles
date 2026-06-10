output "container_app_environment_id" {
  value = azurerm_container_app_environment.this.id
}

output "container_app_fqdn" {
  value = azurerm_container_app.chat.ingress[0].fqdn
}

output "container_app_principal_id" {
  value = azurerm_container_app.chat.identity[0].principal_id
}

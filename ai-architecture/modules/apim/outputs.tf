output "apim_id" {
  value = azurerm_api_management.this.id
}

output "apim_name" {
  value = azurerm_api_management.this.name
}

output "gateway_url" {
  description = "APIM gateway URL fronting Foundry inference."
  value       = azurerm_api_management.this.gateway_url
}

output "apim_principal_id" {
  value = azurerm_api_management.this.identity[0].principal_id
}

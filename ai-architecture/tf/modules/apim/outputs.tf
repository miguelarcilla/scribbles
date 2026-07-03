output "apim_id" {
  value       = azurerm_api_management.this.id
  description = "Resource ID of API Management instance"
}

output "apim_name" {
  value       = azurerm_api_management.this.name
  description = "Name of API Management instance"
}

output "gateway_url" {
  description = "APIM gateway URL fronting Foundry inference."
  value       = azurerm_api_management.this.gateway_url
}

output "apim_principal_id" {
  value       = azurerm_api_management.this.identity[0].principal_id
  description = "Principal ID of APIM's system-assigned managed identity"
}

output "azure_openai_api_url" {
  description = "Full URL for the Azure OpenAI API through APIM"
  value       = "${azurerm_api_management.this.gateway_url}${azurerm_api_management_api.azure_openai.path}"
}

output "azure_openai_chat_completions_url" {
  description = "Chat Completions endpoint URL"
  value       = "${azurerm_api_management.this.gateway_url}${azurerm_api_management_api.azure_openai.path}/deployments/{deployment-id}/chat/completions"
}

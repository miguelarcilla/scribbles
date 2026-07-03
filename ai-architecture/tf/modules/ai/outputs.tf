output "foundry_account_id" {
  value = azurerm_cognitive_account.foundry.id
}

output "foundry_account_name" {
  value = local.foundry_account_name
}

output "foundry_inference_endpoint" {
  description = "OpenAI-compatible inference endpoint of the Foundry account (private)."
  value       = "https://${local.foundry_account_name}.openai.azure.com/"
}

output "foundry_project_endpoint" {
  description = "Foundry project endpoint (reachable through private endpoint only)."
  value       = "https://${local.foundry_account_name}.services.ai.azure.com/api/projects/${local.foundry_project_name}"
}

output "search_service_id" {
  value = azurerm_search_service.this.id
}

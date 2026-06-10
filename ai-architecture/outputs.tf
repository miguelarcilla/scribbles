output "resource_group_name" {
  description = "Name of the resource group containing the workload."
  value       = azurerm_resource_group.this.name
}

output "vnet_id" {
  description = "Resource ID of the workload virtual network."
  value       = module.network.vnet_id
}

output "apim_gateway_url" {
  description = "API Management gateway URL that fronts Microsoft Foundry inference."
  value       = module.apim.gateway_url
}

output "foundry_account_name" {
  description = "Microsoft Foundry account name."
  value       = module.ai.foundry_account_name
}

output "foundry_project_endpoint" {
  description = "Microsoft Foundry project endpoint (reachable via private endpoint only)."
  value       = module.ai.foundry_project_endpoint
}

output "container_app_fqdn" {
  description = "Ingress FQDN of the chat application container app."
  value       = module.application.container_app_fqdn
}

output "container_registry_name" {
  description = "Azure Container Registry name used by the application module."
  value       = module.management.container_registry_name
}

output "container_registry_login_server" {
  description = "Azure Container Registry login server used for image pulls."
  value       = module.management.container_registry_login_server
}

output "key_vault_uri" {
  description = "Key Vault URI for the workload secrets."
  value       = module.management.key_vault_uri
}

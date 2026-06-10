output "vnet_id" {
  value = azurerm_virtual_network.this.id
}

output "vnet_name" {
  value = azurerm_virtual_network.this.name
}

output "container_apps_subnet_id" {
  value = azurerm_subnet.container_apps.id
}

output "apim_subnet_id" {
  value = azurerm_subnet.apim.id
}

output "agents_egress_subnet_id" {
  value = azurerm_subnet.agents_egress.id
}

output "private_endpoints_subnet_id" {
  value = azurerm_subnet.private_endpoints.id
}

output "data_subnet_id" {
  value = azurerm_subnet.data.id
}

# output "firewall_private_ip" {
#   value = azurerm_firewall.this.ip_configuration[0].private_ip_address
# }

output "private_dns_zone_ids" {
  description = "Map of private DNS zone key -> zone resource ID."
  value       = { for k, z in azurerm_private_dns_zone.this : k => z.id }
}

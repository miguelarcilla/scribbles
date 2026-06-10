output "storage_account_id" {
  value = azurerm_storage_account.this.id
}

output "storage_account_name" {
  value = azurerm_storage_account.this.name
}

output "cosmosdb_account_id" {
  value = azurerm_cosmosdb_account.this.id
}

output "cosmosdb_account_name" {
  value = azurerm_cosmosdb_account.this.name
}

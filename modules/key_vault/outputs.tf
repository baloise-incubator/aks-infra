output "key_vault_id" {
  description = "Key Vault ID"
  value       = azurerm_key_vault.default.id
  sensitive   = true
}

output "key_vault_name" {
  description = "Key Vault Name"
  value       = azurerm_key_vault.default.name
  sensitive   = true
}

output "key_vault_url" {
  description = "Key Vault URI"
  value       = azurerm_key_vault.default.vault_uri
  sensitive   = true
}

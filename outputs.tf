output "aks_name" {
  value       = module.aks.aks_name
  description = "Name of the AKS cluster"
}

output "keyvault_name" {
  value       = module.keyvault.key_vault_name
  sensitive   = true
  description = "Name of the Azure Key Vault"
}

output "log_analytics_name" {
  value       = module.log_analytics.name
  description = "Name of the Log Analytics workspace"
}

output "rg_name" {
  value       = module.resource_group.name
  description = "Name of the Resource Group"
}

output "rg_location" {
  value       = module.resource_group.location
  description = "Location of the Resource Group"
}


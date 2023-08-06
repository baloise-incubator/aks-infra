resource "random_pet" "prefix" {}

module "resource_group" {
  source = "./modules/resource_group"

  location = var.location
  name     = "rg-${random_pet.prefix.id}"
}

module "keyvault" {
  source = "./modules/key_vault"

  name                = "kv-${random_pet.prefix.id}"
  location            = var.location
  resource_group_name = module.resource_group.name
}

module "log_analytics" {
  source = "./modules/log_analytics"

  app_name            = random_pet.prefix.id
  resource_group_name = module.resource_group.name
  location            = var.location
}

module "aks" {
  source = "./modules/aks"

  resource_group_name  = module.resource_group.name
  app_name             = random_pet.prefix.id
  location             = var.location

  key_vault_id     = module.keyvault.key_vault_id
  key_vault_name     = module.keyvault.key_vault_name
  log_analytics_id = module.log_analytics.id

  ### AKS configuration params ###
  kubernetes_version  = var.kubernetes_version
  vm_size_node_pool   = var.vm_size_node_pool

}


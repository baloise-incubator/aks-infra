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

  enabled_for_deployment          = "true"
  enabled_for_disk_Encryption     = "true"
  enabled_for_template_deployment = "true"
}

module "vnet" {
  source = "./modules/vnet"

  name                = "vnet-${random_pet.prefix.id}"
  resource_group_name = module.resource_group.name
  location            = var.location
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
  virtual_network_name = module.vnet.name

  key_vault_id     = module.keyvault.key_vault_id
  key_vault_name     = module.keyvault.key_vault_name
  log_analytics_id = module.log_analytics.id

  ### AKS configuration params ###
  kubernetes_version  = var.kubernetes_version
  vm_size_node_pool   = var.vm_size_node_pool
  node_pool_min_count = var.node_pool_min_count
  node_pool_max_count = var.node_pool_max_count

}


# Create Application Gateway
module "appgw" {
  source = "./modules/appgw"

  resource_group       = { "name" : module.resource_group.name, "id" : module.resource_group.id }
  app_name             = random_pet.prefix.id
  location             = var.location
  virtual_network_name = module.vnet.name
  aks_object_id        = module.aks.kubelet_identity
  aks_config           = module.aks.aks_config
  domain_name_label    = var.domain_name_label

}


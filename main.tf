terraform {

  required_version = ">=1.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>3.59"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~>2.7"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~>2.16"
    }
    kustomization = {
      source  = "kbst/kustomization"
      version = "~>0.9.4"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~>2.31.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~>3.0"
    }
  }
}

resource "random_pet" "prefix" {}

data "azurerm_client_config" "current" {}

data "azurerm_subscription" "current" {}

resource "azurerm_resource_group" "default" {
  name     = "rg-${random_pet.prefix.id}"
  location = var.location
}

resource "azurerm_kubernetes_cluster" "aks" {
  name                      = "aks-${random_pet.prefix.id}"
  location                  = var.location
  resource_group_name       = azurerm_resource_group.default.name
  dns_prefix                = "aks-dns-${random_pet.prefix.id}"
  kubernetes_version        = var.kubernetes_version
  oidc_issuer_enabled       = true
  workload_identity_enabled = true

  default_node_pool {
    type            = "VirtualMachineScaleSets"
    name            = "default"
    node_count      = 2
    vm_size         = var.vm_size_node_pool
    os_disk_size_gb = 30
  }

  azure_active_directory_role_based_access_control {
    managed            = true
    azure_rbac_enabled = true
  }

  identity {
    type = "SystemAssigned"
  }
}

resource "azurerm_user_assigned_identity" "aso" {
  location            = var.location
  name                = "mid-${random_pet.prefix.id}-aso"
  resource_group_name = azurerm_resource_group.default.name
}

resource "azurerm_role_assignment" "aso" {
  scope                = data.azurerm_subscription.current.id
  role_definition_name = "Owner"
  principal_id         = azurerm_user_assigned_identity.aso.principal_id
}

resource "azurerm_federated_identity_credential" "aso" {
  name                = "fedid-${random_pet.prefix.id}-aso"
  resource_group_name = azurerm_resource_group.default.name
  parent_id           = azurerm_user_assigned_identity.aso.id
  audience            = ["api://AzureADTokenExchange"]
  issuer              = azurerm_kubernetes_cluster.aks.oidc_issuer_url
  subject             = "system:serviceaccount:azureserviceoperator-system:azureserviceoperator-default"
}


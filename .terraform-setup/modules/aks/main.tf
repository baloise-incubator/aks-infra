# Subnet
terraform {

  required_providers {
    azapi = {
      source  = "azure/azapi"
      version = "~>1.5"
    }
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
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = ">= 1.14.0"
    }
    kustomization = {
      source  = "kbst/kustomization"
      version = "~>0.9.0"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~>2.31.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~>3.0"
    }
    time = {
      source  = "hashicorp/time"
      version = "~>0.9.1"
    }
  }
}
resource "azurerm_subnet" "aks_subnet" {
  name                 = "snet-${var.app_name}-aks"
  resource_group_name  = var.resource_group_name
  virtual_network_name = var.virtual_network_name
  address_prefixes     = ["10.100.1.0/24"]
}

resource "azurerm_role_assignment" "aks_subnet_rbac" {
  scope                = azurerm_subnet.aks_subnet.id
  role_definition_name = "Network Contributor"
  principal_id         = azurerm_kubernetes_cluster.aks.kubelet_identity.0.object_id
}

resource "azurerm_kubernetes_cluster" "aks" {
  name                      = "aks-${var.app_name}"
  location                  = var.location
  resource_group_name       = var.resource_group_name
  dns_prefix                = "aks-${var.app_name}"
  kubernetes_version        = var.kubernetes_version
  oidc_issuer_enabled       = true
  workload_identity_enabled = true

  default_node_pool {
    type                = "VirtualMachineScaleSets"
    name                = "default"
    node_count          = var.node_pool_min_count
    vm_size             = var.vm_size_node_pool
    os_disk_size_gb     = 30
    vnet_subnet_id      = azurerm_subnet.aks_subnet.id
    enable_auto_scaling = true
    max_count           = var.node_pool_max_count
    min_count           = var.node_pool_min_count
  }

  network_profile {
    network_plugin = "azure"
  }

  identity {
    type = "SystemAssigned"
  }
}

resource "azuread_application" "default" {
  display_name = "aks-${var.app_name}-service-principal"
}

resource "azuread_service_principal" "default" {
  application_id               = azuread_application.default.application_id
  app_role_assignment_required = false
}

resource "azuread_application_federated_identity_credential" "default" {
  application_object_id = azuread_application.default.object_id
  display_name          = "kubernetes-federated-credential"
  description           = "Kubernetes service account federated credential"
  audiences             = ["api://AzureADTokenExchange"]
  issuer                = azurerm_kubernetes_cluster.aks.oidc_issuer_url
  subject               = "system:serviceaccount:${var.app_name}:${var.service_account_name}"
}

### Connect to Kubernetes with Interpoation

data "azurerm_key_vault" "main" {
  name                = var.key_vault_name
  resource_group_name = var.resource_group_name
}

data "azurerm_kubernetes_cluster" "main" {
  name                = "aks-${var.app_name}"
  resource_group_name = var.resource_group_name
}

### App Registration for the Workload Identity

resource "kubernetes_service_account" "default" {
  metadata {
    name        = var.service_account_name
    namespace   = var.app_name
    annotations = {
      "azure.workload.identity/client-id" = azuread_application.default.application_id
    }
    labels = {
      "azure.workload.identity/use" : "true"
    }
  }
}

data "azurerm_client_config" "current" {}

resource "helm_release" "awi_webhook" {
  name       = "azure-workload-identity"
  repository = "https://azure.github.io/azure-workload-identity/charts"
  chart      = "workload-identity-webhook"
  version    = "1.1.0"

  namespace        = var.app_name
  create_namespace = true

  set {
    name  = "azureTenantID"
    value = data.azurerm_client_config.current.tenant_id
  }
}

data "kustomization_build" "test" {
  path              = "${path.module}/../../../argocd"
}

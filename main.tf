terraform {

  required_version = ">=1.0"

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
    time = {
      source  = "hashicorp/time"
      version = "~>0.9.1"
    }
  }
}

resource "random_pet" "prefix" {}

data "azurerm_client_config" "current" {}

resource "azurerm_resource_group" "default" {
  name     = "rg-${random_pet.prefix.id}"
  location = var.location

  lifecycle {
    ignore_changes = [
      tags
    ]
  }
}

resource "azurerm_key_vault" "default" {
  name                       = "kv-${random_pet.prefix.id}"
  location                   = var.location
  resource_group_name        = azurerm_resource_group.default.name
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  sku_name                   = "standard"
  soft_delete_retention_days = 7
  purge_protection_enabled   = false
}

# Create a Default Azure Key Vault access policy with Admin permissions
# This policy must be kept for a proper run of the "destroy" process
resource "azurerm_key_vault_access_policy" "default_policy" {
  key_vault_id = azurerm_key_vault.default.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = data.azurerm_client_config.current.object_id

  lifecycle {
    create_before_destroy = true
  }

  key_permissions = [
    "Backup", "Create", "Decrypt", "Delete", "Encrypt", "Get", "Import", "List", "Purge",
    "Recover", "Restore", "Sign", "UnwrapKey", "Update", "Verify", "WrapKey"
  ]
  secret_permissions      = ["Backup", "Delete", "Get", "List", "Purge", "Recover", "Restore", "Set"]
  certificate_permissions = [
    "Create", "Delete", "DeleteIssuers", "Get", "GetIssuers", "Import", "List", "ListIssuers",
    "ManageContacts", "ManageIssuers", "Purge", "Recover", "SetIssuers", "Update", "Backup", "Restore"
  ]
  storage_permissions = [
    "Backup", "Delete", "DeleteSAS", "Get", "GetSAS", "List", "ListSAS",
    "Purge", "Recover", "RegenerateKey", "Restore", "Set", "SetSAS", "Update"
  ]

}

resource "azurerm_key_vault_access_policy" "superadmin" {
  key_vault_id = azurerm_key_vault.default.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = data.azurerm_client_config.current.object_id

  secret_permissions = ["Backup", "Delete", "Get", "List", "Purge", "Recover", "Restore", "Set"]
}

resource "azurerm_key_vault_access_policy" "aks" {
  key_vault_id = azurerm_key_vault.default.id

  tenant_id = data.azurerm_client_config.current.tenant_id
  object_id = azuread_service_principal.default.object_id

  secret_permissions = [
    "Get"
  ]
}

resource "azurerm_kubernetes_cluster" "aks" {
  name                      = "aks-my-app"
  location                  = var.location
  resource_group_name       = azurerm_resource_group.default.name
  dns_prefix                = "aks-my-app"
  kubernetes_version        = var.kubernetes_version
  oidc_issuer_enabled       = true
  workload_identity_enabled = true
  role_based_access_control_enabled = true

  default_node_pool {
    type                = "VirtualMachineScaleSets"
    name                = "default"
    node_count          = 2
    vm_size             = var.vm_size_node_pool
    os_disk_size_gb     = 30
  }

  network_profile {
    network_plugin = "azure"
  }

  azure_active_directory_role_based_access_control {
    managed                = true
    admin_group_object_ids = ["327e7dc6-3229-4094-b884-fb853419e493"]
    azure_rbac_enabled     = true
  }

  identity {
    type = "SystemAssigned"
  }
}

resource "azurerm_role_assignment" "admin" {
  for_each = toset(["327e7dc6-3229-4094-b884-fb853419e493"])
  scope = azurerm_kubernetes_cluster.aks.id
  role_definition_name = "Azure Kubernetes Service Cluster User Role"
  principal_id = each.value
}

resource "azuread_application" "default" {
  display_name = "aks-${kubernetes_namespace.default.metadata[0].name}-service-principal"
}

resource "azuread_service_principal" "default" {
  application_id               = azuread_application.default.application_id
}

resource "azuread_application_federated_identity_credential" "default" {
  application_object_id = azuread_application.default.object_id
  display_name          = "kubernetes-federated-credential"
  description           = "Kubernetes service account federated credential"
  audiences             = ["api://AzureADTokenExchange"]
  issuer                = azurerm_kubernetes_cluster.aks.oidc_issuer_url
  subject               = "system:serviceaccount:${kubernetes_namespace.default.metadata[0].name}:${kubernetes_service_account.default.metadata[0].name}"
}

resource "kubernetes_namespace" "default" {
  metadata {
    name = "my-app"
  }
  depends_on = [azurerm_kubernetes_cluster.aks]
}

resource "kubernetes_service_account" "default" {
  metadata {
    name             = "my-app-sa"
    namespace        = "my-app"
    annotations      = {
      "azure.workload.identity/client-id" = azuread_application.default.application_id
    }
    labels = {
      "azure.workload.identity/use" : "true"
    }
  }
  depends_on = [kubernetes_namespace.default]
}

resource "helm_release" "azure-workload-identity" {
  name       = "azure-workload-identity"
  repository = "https://azure.github.io/azure-workload-identity/charts"
  chart      = "workload-identity-webhook"
  version    = "1.1.0"

  namespace = "azure-workload-identity-system"
  create_namespace = true

  set {
    name  = "azureTenantID"
    value = data.azurerm_client_config.current.tenant_id
  }

  depends_on = [kubernetes_service_account.default]
}

data "kustomization_build" "test" {
  path = "./argocd"
}

# first loop through resources in ids_prio[0]
resource "kustomization_resource" "p0" {
  for_each = data.kustomization_build.test.ids_prio[0]

  manifest = (
  contains(["_/Secret"], regex("(?P<group_kind>.*/.*)/.*/.*", each.value)["group_kind"])
  ? sensitive(data.kustomization_build.test.manifests[each.value])
  : data.kustomization_build.test.manifests[each.value]
  )
}

# then loop through resources in ids_prio[1]
# and set an explicit depends_on on kustomization_resource.p0
# wait 2 minutes for any deployment or daemonset to become ready
resource "kustomization_resource" "p1" {
  for_each = data.kustomization_build.test.ids_prio[1]

  manifest = (
  contains(["_/Secret"], regex("(?P<group_kind>.*/.*)/.*/.*", each.value)["group_kind"])
  ? sensitive(data.kustomization_build.test.manifests[each.value])
  : data.kustomization_build.test.manifests[each.value]
  )
  wait = true
  timeouts {
    create = "2m"
    update = "2m"
  }

  depends_on = [kustomization_resource.p0]
}

# finally, loop through resources in ids_prio[2]
# and set an explicit depends_on on kustomization_resource.p1
resource "kustomization_resource" "p2" {
  for_each = data.kustomization_build.test.ids_prio[2]

  manifest = (
  contains(["_/Secret"], regex("(?P<group_kind>.*/.*)/.*/.*", each.value)["group_kind"])
  ? sensitive(data.kustomization_build.test.manifests[each.value])
  : data.kustomization_build.test.manifests[each.value]
  )

  depends_on = [kustomization_resource.p1]
}

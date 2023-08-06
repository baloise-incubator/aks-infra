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

data "azurerm_client_config" "current" {}

resource "azurerm_key_vault_access_policy" "aks" {
  key_vault_id = var.key_vault_id

  tenant_id = data.azurerm_client_config.current.tenant_id
  object_id = azuread_service_principal.default.object_id

  secret_permissions = [
    "Get"
  ]
}

resource "kubernetes_namespace" "default" {
  metadata {
    name = var.app_name
  }
  depends_on = [azurerm_kubernetes_cluster.aks]
}

resource "kubernetes_service_account" "default" {
  metadata {
    name             = var.service_account_name
    namespace        = var.app_name
    annotations      = {
      "azure.workload.identity/client-id" = azuread_application.default.application_id
    }
    labels = {
      "azure.workload.identity/use" : "true"
    }
  }
  depends_on = [kubernetes_namespace.default]
}

resource "helm_release" "awi_webhook" {
  name       = "azure-workload-identity"
  repository = "https://azure.github.io/azure-workload-identity/charts"
  chart      = "workload-identity-webhook"
  version    = "1.1.0"

  namespace = var.app_name
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

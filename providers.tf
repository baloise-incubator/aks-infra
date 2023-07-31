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

# Configure the Azure Provider
provider "azurerm" {
  skip_provider_registration = true
  features {}
}

# Data

# Provides client_id, tenant_id, subscription_id and object_id variables
data "azurerm_client_config" "current" {}
variable "location" {
  type        = string
  description = "Azure region where to create resources."
  default     = "West Europe"
}

variable "domain_name_label" {
  type        = string
  description = "Unique domain name label for AKS Cluster / Application Gateway"
  default     = "aks-cluster-test"
}

### AKS configuration params ###
variable "kubernetes_version" {
  type        = string
  description = "Kubernetes version of the node pool"
  default     = "1.27.1"
}

variable "vm_size_node_pool" {
  type        = string
  description = "VM Size of the node pool"
  default     = "Standard_D2s_v3"
}
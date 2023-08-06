variable "resource_group_name" {
  type        = string
  description = "The name of an existing Resource Group"
}

variable "location" {
  type        = string
  description = "Define the region the Azure Key Vault should be Created, you should use the Resource Group location"
}

variable "name" {
  type        = string
  description = "The name of the Azure Key Vault"
}

variable "kv-key-permissions-full" {
  type        = list(string)
  description = "List of full key permissions, must be one or more from the following: Backup, Create, Decrypt, Delete, Encrypt, Get, Import, List, Purge, Recover, Restore, Sign, UnwrapKey, Update, Verify and WrapKey."
  default = ["Backup", "Create", "Decrypt", "Delete", "Encrypt", "Get", "Import", "List", "Purge",
  "Recover", "Restore", "Sign", "UnwrapKey", "Update", "Verify", "WrapKey"]
}

variable "kv-secret-permissions-full" {
  type        = list(string)
  description = "List of full secret permissions, must be one or more from the following: Backup, Delete, Get, List, Purge, Recover, Restore and Set"
  default     = ["Backup", "Delete", "Get", "List", "Purge", "Recover", "Restore", "Set"]
}

variable "kv-certificate-permissions-full" {
  type        = list(string)
  description = "List of full certificate permissions, must be one or more from the following: Backup, Create, Delete, DeleteIssuers, Get, GetIssuers, Import, List, ListIssuers, ManageContacts, ManageIssuers, Purge, Recover, Restore, SetIssuers and Update"
  default = ["Create", "Delete", "DeleteIssuers", "Get", "GetIssuers", "Import", "List", "ListIssuers",
  "ManageContacts", "ManageIssuers", "Purge", "Recover", "SetIssuers", "Update", "Backup", "Restore"]
}

variable "kv-storage-permissions-full" {
  type        = list(string)
  description = "List of full storage permissions, must be one or more from the following: Backup, Delete, DeleteSAS, Get, GetSAS, List, ListSAS, Purge, Recover, RegenerateKey, Restore, Set, SetSAS and Update"
  default = ["Backup", "Delete", "DeleteSAS", "Get", "GetSAS", "List", "ListSAS",
  "Purge", "Recover", "RegenerateKey", "Restore", "Set", "SetSAS", "Update"]
}

variable "kv-key-permissions-read" {
  type        = list(string)
  description = "List of read key permissions, must be one or more from the following: Backup, Create, Decrypt, Delete, Encrypt, Get, Import, List, Purge, Recover, Restore, Sign, UnwrapKey, Update, Verify and WrapKey"
  default     = ["Get", "List"]
}

variable "kv-secret-permissions-read" {
  type        = list(string)
  description = "List of full secret permissions, must be one or more from the following: Backup, Delete, Get, List, Purge, Recover, Restore and Set"
  default     = ["Get", "List"]
}

variable "kv-certificate-permissions-read" {
  type        = list(string)
  description = "List of full certificate permissions, must be one or more from the following: Backup, Create, Delete, DeleteIssuers, Get, GetIssuers, Import, List, ListIssuers, ManageContacts, ManageIssuers, Purge, Recover, Restore, SetIssuers and Update"
  default     = ["Get", "GetIssuers", "List", "ListIssuers"]
}

variable "kv-storage-permissions-read" {
  type        = list(string)
  description = "List of read storage permissions, must be one or more from the following: Backup, Delete, DeleteSAS, Get, GetSAS, List, ListSAS, Purge, Recover, RegenerateKey, Restore, Set, SetSAS and Update"
  default     = ["Get", "GetSAS", "List", "ListSAS"]
}

variable "policies" {
  type = map(object({
    tenant_id               = string
    object_id               = string
    key_permissions         = list(string)
    secret_permissions      = list(string)
    certificate_permissions = list(string)
    storage_permissions     = list(string)
  }))
  description = "Define a Azure Key Vault access policy"
  default     = {}
}

variable "secrets" {
  type = map(object({
    value = string
  }))
  description = "Define Azure Key Vault secrets"
  default     = {}
}
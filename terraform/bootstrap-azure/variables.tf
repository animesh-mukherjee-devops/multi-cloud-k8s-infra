variable "resource_group_name" {
  description = "Name of the resource group to create for backend"
  type        = string
  default     = "tfstate-rg"
}

variable "location" {
  description = "Azure region to create backend resources"
  type        = string
  default     = "eastus"
}

variable "storage_account_prefix" {
  description = "Prefix for storage account name (must be lowercase letters/numbers only)"
  type        = string
  default     = "tfstate"
}

variable "container_name" {
  description = "Name of the blob container for state files"
  type        = string
  default     = "tfstate"
}

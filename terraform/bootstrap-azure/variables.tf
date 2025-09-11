variable "resource_group_name" {
  type    = string
  default = "tfstate-rg"
}

variable "location" {
  type    = string
  default = "eastus"
}

variable "storage_account_prefix" {
  type    = string
  default = "tfstate"
}

variable "container_name" {
  type    = string
  default = "tfstate"
}

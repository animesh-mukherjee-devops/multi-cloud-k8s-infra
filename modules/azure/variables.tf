variable "resource_group_name" {
  description = "Resource group for AKS cluster"
  type        = string
  default     = "aks-rg"
}

variable "cluster_name" {
  description = "Name of AKS cluster"
  type        = string
  default     = "aks-cluster"
}

variable "location" {
  description = "Azure region"
  type        = string
  default     = "East US"
}

variable "node_count" {
  description = "Number of worker nodes"
  type        = number
  default     = 2
}

variable "node_size" {
  description = "VM size for AKS nodes"
  type        = string
  default     = "Standard_DS2_v2"
}

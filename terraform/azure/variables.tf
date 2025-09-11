variable "resource_group_name" {
  type    = string
  default = "aks-rg"
}
variable "cluster_name" {
  type    = string
  default = "aks-cluster"
}
variable "location" {
  type    = string
  default = "East US"
}
variable "node_count" {
  type    = number
  default = 2
}
variable "node_size" {
  type    = string
  default = "Standard_DS2_v2"
}

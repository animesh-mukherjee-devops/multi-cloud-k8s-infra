variable "digitalocean_token" {
  type = string
}

variable "cluster_name" {
  type    = string
  default = "do-terraform-cluster"
}

variable "region" {
  type    = string
  default = "nyc3"
}

variable "node_size" {
  type    = string
  default = "s-2vcpu-4gb"
}

variable "node_count" {
  type    = number
  default = 2
}

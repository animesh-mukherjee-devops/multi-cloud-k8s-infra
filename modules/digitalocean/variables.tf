variable "digitalocean_token" {
  type = string
}

variable "region" {
  type    = string
  default = "nyc3"
}

variable "cluster_name" {
  type    = string
  default = "do-terraform-cluster"
}

variable "node_size" {
  type    = string
  default = "s-2vcpu-4gb"
}

variable "node_count" {
  type    = number
  default = 2
}

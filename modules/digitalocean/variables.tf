variable "digitalocean_token" {
  description = "DigitalOcean API token"
  type        = string
}

variable "region" {
  description = "Region for Kubernetes cluster"
  type        = string
  default     = "nyc3"
}

variable "cluster_name" {
  description = "Kubernetes cluster name"
  type        = string
  default     = "do-terraform-cluster"
}

variable "node_size" {
  description = "Size of worker nodes"
  type        = string
  default     = "s-2vcpu-4gb"
}

variable "node_count" {
  description = "Number of nodes"
  type        = number
  default     = 2
}

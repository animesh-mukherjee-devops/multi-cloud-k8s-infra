variable "digitalocean_token" {
  type        = string
  description = "DigitalOcean API token"
}

variable "spaces_access_key" {
  type        = string
  description = "Spaces access key"
}

variable "spaces_secret_key" {
  type        = string
  description = "Spaces secret key"
}

variable "region" {
  type        = string
  default     = "nyc3"
  description = "DO Spaces region"
}

variable "spaces_bucket_name" {
  type        = string
  description = "Spaces bucket name"
}

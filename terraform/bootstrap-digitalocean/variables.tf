variable "digitalocean_token" {
  description = "DigitalOcean personal access token"
  type        = string
}

variable "spaces_access_key" {
  description = "Spaces access key"
  type        = string
}

variable "spaces_secret_key" {
  description = "Spaces secret key"
  type        = string
}

variable "region" {
  description = "Region for Spaces bucket"
  type        = string
  default     = "nyc3"
}

variable "spaces_bucket_name" {
  description = "Spaces bucket name"
  type        = string
}

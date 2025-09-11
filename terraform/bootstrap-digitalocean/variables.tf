variable "digitalocean_token" {
  description = "DigitalOcean personal access token"
  type        = string
}

variable "region" {
  type    = string
  default = "nyc3"
}

variable "spaces_bucket_name" {
  description = "Spaces bucket name"
  type        = string
}

terraform {
  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = ">= 2.0.0"
    }
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.0.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.4"
    }
  }
}

# DigitalOcean API provider
provider "digitalocean" {
  token = var.digitalocean_token
}

# Spaces provider (S3-compatible)
provider "aws" {
  region                      = "us-east-1" # dummy AWS region
  access_key                  = var.spaces_access_key
  secret_key                  = var.spaces_secret_key
  skip_credentials_validation = true
  skip_requesting_account_id  = true
  skip_metadata_api_check     = true

  endpoints {
    s3 = "https://${var.region}.digitaloceanspaces.com"
  }
}

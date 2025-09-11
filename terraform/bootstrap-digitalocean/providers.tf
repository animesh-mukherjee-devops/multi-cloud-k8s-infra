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
  }
}

provider "digitalocean" {
  token = var.digitalocean_token
}

provider "aws" {
  region                      = "us-east-1" # dummy, DO Spaces requires valid AWS region
  access_key                  = var.spaces_access_key
  secret_key                  = var.spaces_secret_key
  skip_credentials_validation = true
  skip_requesting_account_id  = true
  skip_metadata_api_check     = true

  endpoints {
    s3 = "https://${var.region}.digitaloceanspaces.com"
  }
}

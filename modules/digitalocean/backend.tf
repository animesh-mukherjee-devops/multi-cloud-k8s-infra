terraform {
  backend "s3" {
    bucket = "do-tfstate-bucket"
    key    = "doks/terraform.tfstate"
    region = "nyc3"
    endpoints = {
      s3 = "https://nyc3.digitaloceanspaces.com"
    }

    skip_credentials_validation = true
    skip_metadata_api_check     = true
    skip_region_validation      = true
  }
}

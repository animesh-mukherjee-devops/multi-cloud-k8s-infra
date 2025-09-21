terraform {
  required_version = ">= 1.6"

  
  backend "s3" {
    # Backend configuration will be provided via init command
  }
}
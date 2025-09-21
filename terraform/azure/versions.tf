terraform {
  required_version = ">= 1.6"

  backend "azurerm" {
    # Backend configuration will be provided via init command
  }
}
terraform {
  required_providers {
    azapi = {
      source  = "azure/azapi"
      version = "~> 2.8.0"
    }
  }
  backend "azurerm" {
  }
}

provider "azapi" {
  # Configuration options
}
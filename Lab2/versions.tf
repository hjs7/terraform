terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.57.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6.3"
    }
  }
}

provider "azurerm" {
  features {}
  subscription_id  = "60819aab-bfaa-48c9-b2fa-1fafcf60b819"
}

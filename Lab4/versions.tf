terraform {
    required_providers {
      azurerm = {
        source = "hashicorp/azurerm"
        version = "~> 4.8.0"
      }
      random = {
        source = "hashicorp/random"
        version = "~> 3.6.3"
      }
    }

    backend "azurerm" {
      resource_group_name  = "rg-terraform-state-dev"
      storage_account_name = "yourstorageaccount"
      container_name       = "tfstate"
      key                  = "devops-dev"
  }
}

provider "azurerm" {
  features {}
}
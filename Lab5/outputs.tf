terraform {

  backend "azurerm" {
    resource_group_name  = "rg-terraform-state-dev"
    storage_account_name = "yourstorageaccountname"
    container_name       = "tfstate"
    key                  = "network-dev"
  }

}

provider "azurerm" {
  features {}
  subscription_id = "your-subscription-id"
}
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.77"
    }
    azapi = {
      source  = "Azure/azapi"
      version = "~> 2.2"
    }
  }
}

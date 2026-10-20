terraform {
  required_version = "1.16.6"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "5.10.0"
    }
  }

  backend "azurerm" {
    key              = "ascendant.prd.tfstate"
    use_azuread_auth = true
  }
}

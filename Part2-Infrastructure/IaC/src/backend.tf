terraform {
  backend "azurerm" {
    resource_group_name  = "rg-infra"
    storage_account_name = "infranonprod" # infra=Infrastructure, nonprod=Non Production environment
    container_name       = "terraform-state"
    key                  = "dev-01.terraform-utils.tfstate"
  }

  required_providers {
    azurerm = {
      version = "3.11.0"
    }

    azuread = {
      source  = "hashicorp/azuread"
      version = "2.25.0"
    }

    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.11.0"
    }

    helm = {
      source  = "hashicorp/helm"
      version = "2.6.0"
    }
  }
}

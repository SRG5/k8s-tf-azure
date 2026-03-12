terraform {
  required_version = ">= 1.6.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.63"
    }

    time = {
      source  = "hashicorp/time"
      version = "~> 0.13"
    }

    null = {
      source  = "hashicorp/null"
      version = "~> 3.2"
    }
  }
}

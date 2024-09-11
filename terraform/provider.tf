terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "3.106.1"
    }
  }
}

provider "azurerm" {
  #alias = "staging"
  #subscription_id = "1fa76e2f-fc0b-4baa-bd83-9716710e3a91"
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
}

provider "azurerm" {
  alias = "connectivity"
  subscription_id = "91743078-d0fc-4aae-98bd-d57da1ae7f19"
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
}

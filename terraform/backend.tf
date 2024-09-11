
terraform {
  backend "azurerm" {
    resource_group_name  = "rg-stg-core-west3-001"       # Can be passed via `-backend-config=`"resource_group_name=<resource group name>"` in the `init` command.
    storage_account_name = "terraformstates011"        # Can be passed via `-backend-config=`"storage_account_name=<storage account name>"` in the `init` command.
    container_name       = "terraformtfstatefiles"            # Can be passed via `-backend-config=`"container_name=<container name>"` in the `init` command.
    key                  = "terraform.tfstate" # Can be passed via `-backend-config=`"key=<blob key name>"` in the `init` command.
  }
}


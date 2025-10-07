# Azure Infrastructure Module

This directory contains a modular Terraform configuration for deploying an AKS cluster on Azure.

## Remote State Backend

By default, when running this module directly, Terraform will store its state in a local file named `terraform.tfstate`. To use a remote backend for state storage (recommended for any collaborative or production environment), you can configure an Azure Storage backend.

A sample backend configuration is provided in `backend.tf`. To enable it:

1.  **Uncomment the code** in the `modules/azure/backend.tf` file.
2.  **Fill in the placeholder values** for `resource_group_name` and `storage_account_name`.
3.  **Run `terraform init`** from within the `modules/azure/` directory. Terraform will prompt you to migrate your state to the new backend.

```hcl
# modules/azure/backend.tf

terraform {
  backend "azurerm" {
    resource_group_name  = "your-terraform-storage-rg"     # <-- Replace with your resource group name
    storage_account_name = "yourterraformstateaccount" # <-- Replace with your storage account name
    container_name       = "tfstate"
    key                  = "azure-module/terraform.tfstate"
  }
}
```

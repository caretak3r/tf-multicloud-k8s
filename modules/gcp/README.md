# GCP Infrastructure Module

This directory contains a modular Terraform configuration for deploying a GKE cluster on GCP.

## Remote State Backend

By default, when running this module directly, Terraform will store its state in a local file named `terraform.tfstate`. To use a remote backend for state storage (recommended for any collaborative or production environment), you can configure a Google Cloud Storage (GCS) backend.

A sample backend configuration is provided in `backend.tf`. To enable it:

1.  **Uncomment the code** in the `modules/gcp/backend.tf` file.
2.  **Fill in the placeholder value** for `bucket`.
3.  **Run `terraform init`** from within the `modules/gcp/` directory. Terraform will prompt you to migrate your state to the new backend.

```hcl
# modules/gcp/backend.tf

terraform {
  backend "gcs" {
    bucket  = "your-terraform-state-bucket-name" # <-- Replace with your GCS bucket name
    prefix  = "gcp-module/terraform.tfstate"
  }
}
```

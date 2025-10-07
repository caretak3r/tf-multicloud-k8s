# Project Overview

This project provides a secure, production-ready Terraform template for deploying Kubernetes clusters on Azure AKS and AWS EKS, with nascent support for GCP GKE. It's designed with a modular approach, allowing for consistent configuration and security best practices across cloud providers.

**Main Technologies:**

*   Terraform
*   Kubernetes (AWS EKS, Azure AKS, GCP GKE)
*   AWS, Azure, GCP

**Architecture:**

The project is structured using Terraform modules to separate concerns for each cloud provider. A root `main.tf` file selects the appropriate module based on the `cloud_provider` variable. Configuration is managed through `.tfvars` files, with pre-configured examples for different environments (dev, perf, prod).

# Building and Running

**Prerequisites:**

*   Terraform >= 1.0
*   Azure CLI (for Azure deployments)
*   AWS CLI (for AWS deployments)
*   GCP CLI (for Google Cloud deployments)
*   `kubectl`

**Key Commands:**

1.  **Initialization:**
    ```bash
    terraform init
    ```

2.  **Planning:**
    ```bash
    # For a specific environment
    terraform plan -var-file="environments/dev-azure.tfvars"
    ```

3.  **Applying:**
    ```bash
    # For a specific environment
    terraform apply -var-file="environments/dev-azure.tfvars"
    ```

4.  **Destroying:**
    ```bash
    terraform destroy
    ```

**TODO:** The `outputs.tf` file is empty. It would be beneficial to output key information like the cluster endpoint, kubeconfig commands, and other relevant details.

# Development Conventions

*   **Modular Design:** The project is organized into modules for each cloud provider (`aws`, `azure`, `gcp`).
*   **Environment-specific Configurations:** Use the `environments` directory to store `.tfvars` files for different deployment environments.
*   **Variable Definitions:** All configurable options are defined in `variables.tf`.
*   **Size-based Configurations:** The `node_size_config` variable allows for deploying clusters with different resource allocations (small, medium, large).

### Committing Changes

Before committing any changes, please run the pre-commit hooks to ensure your code adheres to the project's quality standards. This will automatically format and lint your code.

```bash
pre-commit run --all-files
```

### Cleaning Up
Once all testing is completed and is successful, remove any terraform artifacts and directories like `.terraform` `.terraform.lock.hcl` and any state files.

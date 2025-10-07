# Testing Guide

This document provides instructions on how to run and extend the infrastructure tests for this project.

## Overview

We use [Terratest](https://terratest.gruntwork.io/), a Go library, to run integration tests on our Terraform code. This allows us to provision real infrastructure, verify its configuration, and tear it down automatically.

Each cloud provider has its own test file located in the `test/` directory.

## Prerequisites

1.  **Go:** You must have Go installed (version 1.18 or newer).
2.  **Cloud Provider Authentication:** You must be authenticated to the cloud provider you wish to test. This is typically done via the provider's CLI:
    *   **AWS:** `aws configure`
    *   **Azure:** `az login`
    *   **GCP:** `gcloud auth application-default login`

## Running Tests

All test commands should be run from the root directory of the project.

### GCP Project ID

Before running the GCP test, you **must** edit the `test/gcp_gke_test.go` file and replace the placeholder `"your-gcp-project-id"` with your actual GCP Project ID.

### Run All Tests

To run the tests for all cloud providers, use the following command. A long timeout is recommended as provisioning a Kubernetes cluster can take 20-30 minutes.

```bash
go test -v -timeout 45m ./test
```

### Run a Specific Test

You can run a single test using the `-run` flag, which accepts a regular expression. For example, to run only the AWS test:

```bash
go test -v -timeout 30m -run TestAWSEKSModule ./test
```

## Adding a New Test

To add a new test, it is easiest to copy one of the existing test files (`aws_eks_test.go`, `azure_aks_test.go`, or `gcp_gke_test.go`) and modify it.

### Test File Structure

A typical test function looks like this:

```go
package test

import (
	"testing"

	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/require"
)

func TestNewModule(t *testing.T) {
	t.Parallel() // Run tests in parallel

	terraformOptions := &terraform.Options{
		// The path to where our Terraform code is located
		TerraformDir: "../",

		// Variables to pass to our Terraform code
		Vars: map[string]interface{}{
			"cloud_provider": "aws", // or "azure", "gcp"
			// ... other variables ...
		},
	}

	// Destroy the infrastructure at the end of the test
	defer terraform.Destroy(t, terraformOptions)

	// Apply the Terraform configuration
	terraform.InitAndApply(t, terraformOptions)

	// Add assertions here to verify the infrastructure
	// For example, get an output variable and check its value.
	// clusterEndpoint := terraform.Output(t, terraformOptions, "cluster_endpoint")
	// require.NotEmpty(t, clusterEndpoint)
}
```

### Key Points

*   **`TerraformDir`**: This should almost always be `"../"` to point to the root of the project.
*   **`Vars`**: This map is where you define the input variables for your Terraform run. To test a new module or configuration, you will primarily change the values here.
*   **Assertions**: Use the `require` or `assert` packages from `testify` to validate the results of your deployment. You can fetch output variables from your Terraform module using `terraform.Output()` and write assertions against them.

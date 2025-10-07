package test

import (
	"testing"

	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/require"
)

func TestGCPGKEModule(t *testing.T) {
	t.Parallel()

	// IMPORTANT: You must replace "your-gcp-project-id" with your actual GCP project ID!
	projectID := "your-gcp-project-id"

	terraformOptions := &terraform.Options{
		// The path to where our Terraform code is located
		TerraformDir: "../",

		// Variables to pass to our Terraform code using -var options
		Vars: map[string]interface{}{
			"cloud_provider":     "gcp",
			"gcp_project_id":     projectID,
			"gcp_region":         "us-central1",
			"cluster_name":       "test-gke-cluster",
			"node_size_config":   "small",
			"kubernetes_version": "1.28",
			"vpc_cidr":           "10.2.0.0/16",
			"tags": map[string]string{
				"ManagedBy": "Terratest",
			},
		},
	}

	// At the end of the test, run `terraform destroy` to clean up any resources that were created
	defer terraform.Destroy(t, terraformOptions)

	// This will run `terraform init` and `terraform apply` and fail the test if there are any errors
	terraform.InitAndApply(t, terraformOptions)

	// For now, we'll just assert that the apply completed without error.
	require.True(t, true, "Terraform apply should complete without errors")
}

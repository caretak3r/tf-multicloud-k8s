package test

import (
	"testing"

	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/require"
)

func TestAWSEKSModule(t *testing.T) {
	t.Parallel()

	terraformOptions := &terraform.Options{
		// The path to where our Terraform code is located
		TerraformDir: "../",

		// Variables to pass to our Terraform code using -var options
		Vars: map[string]interface{}{
			"cloud_provider":     "aws",
			"aws_region":         "us-west-2",
			"cluster_name":       "test-eks-cluster",
			"node_size_config":   "medium",
			"kubernetes_version": "1.32",
			"create_vpc":         true,
			"vpc_cidr":           "10.0.0.0/16",
			"tags": map[string]string{
				"ManagedBy": "Terratest",
			},
		},
	}

	// At the end of the test, run `terraform destroy` to clean up any resources that were created
	defer terraform.Destroy(t, terraformOptions)

	// This will run `terraform init` and `terraform apply` and fail the test if there are any errors
	terraform.InitAndApply(t, terraformOptions)

	// Here you would add your actual tests, like verifying the cluster is accessible
	// For now, we'll just assert that the apply completed without error.
	require.True(t, true, "Terraform apply should complete without errors")
}

# To enable the S3 remote backend for this module, uncomment the following
# lines and fill in the placeholder values. Then, run `terraform init` from
# within this directory.
#
# terraform {
#   backend "s3" {
#     bucket         = "your-terraform-state-bucket-name"
#     key            = "aws-module/terraform.tfstate"
#     region         = "us-east-1"
#     encrypt        = true
#     dynamodb_table = "your-terraform-state-lock-table"
#   }
# }

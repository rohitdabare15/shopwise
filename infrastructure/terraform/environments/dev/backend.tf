# This file tells Terraform WHERE to store its state file.
# Replace 617162869021 with your actual account ID.

terraform {
  backend "s3" {
    bucket         = "shopwise-terraform-state-617162869021"
    key            = "dev/vpc/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "shopwise-terraform-locks"
    encrypt        = true  # State file is encrypted at rest in S3
  }
}

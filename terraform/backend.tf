terraform {
  required_version = ">= 1.3.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Partial backend config — supply values via `terraform init -backend-config=...`
  # or a backend.hcl file. Nothing is hardcoded here so the same module reuses
  # across projects/envs.
  backend "s3" {}
}

# Terraform AWS Infrastructure

Reusable Terraform modules and GitHub Actions workflows for deploying AWS resources. The root composition currently builds an EC2 instance, but the modules and CI pipeline are designed so adding new resource types (RDS, S3, ALB, ECS…) means dropping in another module — not rewriting the pipeline.

## Layout

```
.github/workflows/
  terraform-pr-check.yml     # validate + plan, comments on PR
  terraform-deploy.yml        # apply / destroy with env input
terraform/
  backend.tf                  # partial S3 backend (config injected at init)
  providers.tf                # AWS provider, default_tags
  main.tf                     # composes modules
  variables.tf  outputs.tf
  user_data.sh                # example user-data template
  backend-config/
    <env>.hcl                 # bucket / key / dynamodb_table per env
  envs/
    <env>.tfvars              # variable values per env
  modules/
    ec2/
    security_group/
```

`backend-config/*.hcl` and `envs/*.tfvars` are gitignored — copy from the `.example` files. Sensitive values (SSH keys, etc.) go through `TF_VAR_<name>` env vars from CI secrets, not into tfvars files.

## Prerequisites

One-time, per AWS account:

- **S3 bucket** for state (versioning + encryption enabled).
- **DynamoDB table** for state locking, partition key `LockID` (string).
- **IAM role** assumable by GitHub Actions via OIDC. Trust policy must allow `token.actions.githubusercontent.com` for your repo. Permissions: whatever the resources need + `s3:*` on the state bucket prefix + `dynamodb:*` on the lock table.

In each GitHub Environment (`development`, `dev`, `staging`, `prod`):

- Secret `AWS_ROLE_ARN` — the OIDC role ARN.
- Secret `EC2_SSH_PUBLIC_KEY` — optional, only if you want a key pair.

## Setup

```bash
# 1. Copy the per-env templates
cp terraform/backend-config/dev.hcl.example terraform/backend-config/dev.hcl
cp terraform/envs/dev.tfvars.example         terraform/envs/dev.tfvars

# 2. Edit the bucket / dynamodb_table in dev.hcl
# 3. Edit project_name, VPC/subnet, ingress_rules in dev.tfvars

# 4. Init (locally)
cd terraform
terraform init -backend-config=backend-config/dev.hcl

# 5. Plan
terraform plan -var-file=envs/dev.tfvars
```

Repeat for `prod`, `staging`, etc. Each environment has its own state file (the `key =` in the backend config) and its own tfvars.

## CI/CD

### PR check ([terraform-pr-check.yml](.github/workflows/terraform-pr-check.yml))

Runs on PRs touching `terraform/**`:

- `terraform fmt -check -recursive`
- `terraform init` with the dev backend config
- `terraform validate`
- `terraform plan` (uses `envs/dev.tfvars`)
- Posts the plan as a PR comment (truncated at 60k chars)
- Skips the comment for fork PRs (no write permission)
- Concurrency: superseded runs are cancelled per PR

### Deploy ([terraform-deploy.yml](.github/workflows/terraform-deploy.yml))

Runs on:

- **Push to `main`** — applies the `prod` config automatically.
- **Manual dispatch** — pick `action` (`apply` | `destroy`), `environment` (`dev` | `staging` | `prod`), and (for destroy) type the env name into `confirm`.

The workflow loads `backend-config/<env>.hcl` and `envs/<env>.tfvars` automatically and serializes runs per environment.

## Adding a new resource type

1. Create `terraform/modules/<thing>/` with `main.tf`, `variables.tf`, `outputs.tf`.
2. Take inputs only (no project-specific names, no hardcoded ports / AMIs).
3. Compose it in the root [main.tf](terraform/main.tf):

```hcl
module "rds" {
  source = "./modules/rds"

  name       = "${var.project_name}-${var.environment}"
  vpc_id     = local.resolved_vpc_id
  subnet_ids = var.private_subnet_ids
  # ...
  tags = local.common_tags
}
```

4. Reuse `modules/security_group` for its SG (pass in the rules).
5. Add any new inputs to `variables.tf` + the env tfvars.

## Module reference

### `modules/security_group`

Generic SG with per-rule resources (`aws_vpc_security_group_ingress_rule` / `_egress_rule`) so changing one rule doesn't replan the whole SG. Rules are a map keyed by a stable slug — Terraform addresses stay stable across rule reorderings.

| Input            | Type               | Notes                                                                   |
| ---------------- | ------------------ | ----------------------------------------------------------------------- |
| `name`           | string             | Must be unique in the VPC.                                              |
| `vpc_id`         | string             |                                                                         |
| `ingress_rules`  | `map(object(...))` | Exactly one of `cidr_ipv4`, `cidr_ipv6`, `referenced_security_group_id`, or `prefix_list_id` per rule (validated). |
| `egress_rules`   | `map(object(...))` | Defaults to allow-all-IPv4-out.                                         |
| `tags`           | `map(string)`      |                                                                         |

Outputs: `id`, `arn`, `name`.

### `modules/ec2`

EC2 instance with safe defaults: IMDSv2 required, root volume encrypted, gp3, `create_before_destroy` lifecycle.

Notable inputs:

- `ami_id`, `instance_type`, `security_group_ids` — required.
- `public_key` — null disables key-pair creation.
- `user_data` — raw script content; module handles base64.
- `user_data_replace_on_change` — defaults true (treat user-data as immutable).
- `imdsv2_required` (default true), `imds_hop_limit` (default 1, bump to 2 for containers).
- `root_volume_kms_key_id`, `detailed_monitoring`, `ebs_optimized`, `create_eip`.

Outputs: `instance_id`, `instance_arn`, `private_ip`, `public_ip`, `public_dns`, `key_name`, `eip_public_ip`.

## Security notes

- **OIDC, not access keys.** Workflows assume a role via `aws-actions/configure-aws-credentials@v4`; no long-lived AWS credentials in GitHub.
- **State is encrypted** (backend `encrypt = true`) and locked via DynamoDB.
- **No secrets in tfvars.** SSH keys and similar flow through `TF_VAR_*` env vars from secrets.
- **Destroy requires confirmation** — the `confirm` input must equal the environment name.
- **IMDSv2 enforced** by default on EC2.
- **Prod tfvars example omits SSH** — use SSM Session Manager.

## Local testing

```bash
cd terraform
terraform init -backend-config=backend-config/dev.hcl
terraform fmt -check -recursive
terraform validate
terraform plan -var-file=envs/dev.tfvars -out=tfplan
terraform apply tfplan
```

## Versions

- Terraform: `>= 1.3.0` (pinned to `1.7.0` in CI)
- AWS provider: `~> 5.0`

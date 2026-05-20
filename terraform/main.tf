locals {
  common_tags = merge(var.tags, {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
  })

  resolved_vpc_id = coalesce(var.vpc_id, one(data.aws_vpc.selected[*].id))
  resolved_ami_id = coalesce(var.ami_id, one(data.aws_ami.selected[*].id))

  rendered_user_data = var.user_data_template == null ? null : templatefile(
    var.user_data_template, var.user_data_vars
  )
}

# ---------------------------------------------------------------------------
# Optional data sources (only invoked when the corresponding var is null)
# ---------------------------------------------------------------------------
data "aws_vpc" "selected" {
  count   = var.vpc_id == null ? 1 : 0
  default = true
}

data "aws_ami" "selected" {
  count       = var.ami_id == null ? 1 : 0
  most_recent = true
  owners      = var.ami_owners

  dynamic "filter" {
    for_each = var.ami_filters
    content {
      name   = filter.value.name
      values = filter.value.values
    }
  }
}

# ---------------------------------------------------------------------------
# Modules
# ---------------------------------------------------------------------------
module "security_group" {
  source = "./modules/security_group"

  name          = "${var.project_name}-${var.environment}-sg"
  description   = "Security group for ${var.project_name} (${var.environment})"
  vpc_id        = local.resolved_vpc_id
  ingress_rules = var.ingress_rules
  egress_rules  = var.egress_rules
  tags          = local.common_tags
}

module "ec2" {
  source = "./modules/ec2"

  name                 = "${var.project_name}-${var.environment}"
  ami_id               = local.resolved_ami_id
  instance_type        = var.instance_type
  subnet_id            = var.subnet_id
  security_group_ids   = [module.security_group.id]
  iam_instance_profile = var.iam_instance_profile

  public_key = var.public_key
  user_data  = local.rendered_user_data

  root_volume_type       = var.root_volume_type
  root_volume_size       = var.root_volume_size
  root_volume_encrypted  = var.root_volume_encrypted
  root_volume_kms_key_id = var.root_volume_kms_key_id

  imdsv2_required     = var.imdsv2_required
  imds_hop_limit      = var.imds_hop_limit
  detailed_monitoring = var.detailed_monitoring

  create_eip = var.create_eip
  tags       = local.common_tags
}

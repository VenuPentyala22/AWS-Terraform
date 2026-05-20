variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string

  validation {
    condition     = can(regex("^[a-z]{2}-[a-z]+-[0-9]$", var.aws_region))
    error_message = "aws_region must look like \"us-east-1\"."
  }
}

variable "project_name" {
  description = "Name prefix for all resources (lowercase, dashes only)"
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{1,30}[a-z0-9]$", var.project_name))
    error_message = "project_name must be 3-32 chars, lowercase alphanumeric with dashes, start with a letter, end alphanumeric."
  }
}

variable "environment" {
  description = "Deployment environment (dev, staging, prod)"
  type        = string

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "environment must be one of: dev, staging, prod."
  }
}

variable "tags" {
  description = "Extra tags merged into the default tag set"
  type        = map(string)
  default     = {}
}

# ---------------------------------------------------------------------------
# Networking
# ---------------------------------------------------------------------------
variable "vpc_id" {
  description = "VPC ID. Null falls back to the account's default VPC."
  type        = string
  default     = null
}

variable "subnet_id" {
  description = "Subnet ID for the instance. Null lets AWS choose."
  type        = string
  default     = null
}

# ---------------------------------------------------------------------------
# AMI selection — either pin an AMI ID or describe a lookup
# ---------------------------------------------------------------------------
variable "ami_id" {
  description = "Pin a specific AMI ID. Null triggers a lookup using ami_owners + ami_filters."
  type        = string
  default     = null
}

variable "ami_owners" {
  description = "AMI owner IDs used when ami_id is null"
  type        = list(string)
  default     = ["amazon"]
}

variable "ami_filters" {
  description = "AMI filters used when ami_id is null"
  type = list(object({
    name   = string
    values = list(string)
  }))
  default = [
    { name = "name", values = ["al2023-ami-*-x86_64"] },
    { name = "virtualization-type", values = ["hvm"] },
  ]
}

# ---------------------------------------------------------------------------
# Instance
# ---------------------------------------------------------------------------
variable "instance_type" {
  description = "EC2 instance type"
  type        = string
}

variable "iam_instance_profile" {
  description = "IAM instance profile name to attach (optional)"
  type        = string
  default     = null
}

variable "public_key" {
  description = "SSH public key content. Null disables key-pair creation."
  type        = string
  default     = null
  sensitive   = true
}

variable "root_volume_type" {
  description = "Root EBS volume type"
  type        = string
  default     = "gp3"
}

variable "root_volume_size" {
  description = "Root EBS volume size in GB"
  type        = number
  default     = 20
}

variable "root_volume_encrypted" {
  description = "Encrypt the root EBS volume"
  type        = bool
  default     = true
}

variable "root_volume_kms_key_id" {
  description = "KMS key for root volume encryption. Null uses the AWS-managed key."
  type        = string
  default     = null
}

variable "imdsv2_required" {
  description = "Require IMDSv2 tokens"
  type        = bool
  default     = true
}

variable "imds_hop_limit" {
  description = "IMDS PUT response hop limit (set to 2 for container workloads on the host)"
  type        = number
  default     = 1
}

variable "detailed_monitoring" {
  description = "Enable detailed CloudWatch monitoring"
  type        = bool
  default     = false
}

variable "create_eip" {
  description = "Allocate and attach an Elastic IP"
  type        = bool
  default     = false
}

# ---------------------------------------------------------------------------
# User data — bring your own template + vars
# ---------------------------------------------------------------------------
variable "user_data_template" {
  description = "Path to a templatefile() user-data script (relative to the root config). Null skips user-data."
  type        = string
  default     = null
}

variable "user_data_vars" {
  description = "Variables passed into the user_data_template"
  type        = map(string)
  default     = {}
}

# ---------------------------------------------------------------------------
# Security group rules — see modules/security_group/variables.tf for shape
# ---------------------------------------------------------------------------
variable "ingress_rules" {
  description = "Ingress rules keyed by stable slug (e.g. \"ssh\", \"http\")."
  type = map(object({
    description                  = optional(string)
    protocol                     = string
    from_port                    = optional(number)
    to_port                      = optional(number)
    cidr_ipv4                    = optional(string)
    cidr_ipv6                    = optional(string)
    referenced_security_group_id = optional(string)
    prefix_list_id               = optional(string)
  }))
  default = {}
}

variable "egress_rules" {
  description = "Egress rules keyed by stable slug. Defaults to allow-all-outbound (set explicitly to override)."
  type = map(object({
    description                  = optional(string)
    protocol                     = string
    from_port                    = optional(number)
    to_port                      = optional(number)
    cidr_ipv4                    = optional(string)
    cidr_ipv6                    = optional(string)
    referenced_security_group_id = optional(string)
    prefix_list_id               = optional(string)
  }))
  default = {
    all = {
      description = "Allow all outbound IPv4"
      protocol    = "-1"
      cidr_ipv4   = "0.0.0.0/0"
    }
  }
}

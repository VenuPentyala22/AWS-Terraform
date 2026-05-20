variable "name" {
  description = "Name tag and key-pair prefix for the instance"
  type        = string
}

variable "ami_id" {
  description = "AMI ID to launch the instance from"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
}

variable "subnet_id" {
  description = "Subnet ID. Null lets AWS pick a default-VPC subnet."
  type        = string
  default     = null
}

variable "security_group_ids" {
  description = "Security group IDs to attach to the instance"
  type        = list(string)

  validation {
    condition     = length(var.security_group_ids) > 0
    error_message = "At least one security group ID is required."
  }
}

variable "iam_instance_profile" {
  description = "IAM instance profile name to attach (optional)"
  type        = string
  default     = null
}

variable "associate_public_ip_address" {
  description = "Whether to auto-assign a public IP. Null lets AWS use the subnet default."
  type        = bool
  default     = null
}

variable "public_key" {
  description = "SSH public key content. Null or empty disables key-pair creation."
  type        = string
  default     = null
  sensitive   = true
}

variable "root_volume_type" {
  description = "Root EBS volume type"
  type        = string
  default     = "gp3"

  validation {
    condition     = contains(["gp2", "gp3", "io1", "io2", "st1", "sc1", "standard"], var.root_volume_type)
    error_message = "root_volume_type must be one of gp2, gp3, io1, io2, st1, sc1, standard."
  }
}

variable "root_volume_size" {
  description = "Root EBS volume size in GB"
  type        = number
  default     = 20

  validation {
    condition     = var.root_volume_size >= 8 && var.root_volume_size <= 16384
    error_message = "root_volume_size must be between 8 and 16384 GB."
  }
}

variable "root_volume_encrypted" {
  description = "Whether the root EBS volume is encrypted"
  type        = bool
  default     = true
}

variable "root_volume_kms_key_id" {
  description = "KMS key ID/ARN for root volume encryption. Null uses the AWS-managed key."
  type        = string
  default     = null
}

variable "root_volume_delete_on_termination" {
  description = "Delete root volume on instance termination"
  type        = bool
  default     = true
}

variable "ebs_optimized" {
  description = "Enable EBS optimization. Null defers to the instance-type default."
  type        = bool
  default     = null
}

variable "detailed_monitoring" {
  description = "Enable detailed (1-minute) CloudWatch monitoring"
  type        = bool
  default     = false
}

variable "imdsv2_required" {
  description = "Require IMDSv2 tokens (recommended). Set false only for legacy workloads."
  type        = bool
  default     = true
}

variable "imds_hop_limit" {
  description = "IMDS PUT response hop limit. 2 is needed for containers reaching IMDS."
  type        = number
  default     = 1

  validation {
    condition     = var.imds_hop_limit >= 1 && var.imds_hop_limit <= 64
    error_message = "imds_hop_limit must be between 1 and 64."
  }
}

variable "create_eip" {
  description = "Whether to allocate and attach an Elastic IP"
  type        = bool
  default     = false
}

variable "tags" {
  description = "Tags applied to the instance, key pair, and EIP"
  type        = map(string)
  default     = {}
}

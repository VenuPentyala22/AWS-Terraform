variable "name" {
  description = "Security group name (must be unique within the VPC)"
  type        = string
}

variable "description" {
  description = "Security group description"
  type        = string
  default     = "Managed by Terraform"
}

variable "vpc_id" {
  description = "VPC ID where the security group lives"
  type        = string
}

# Map keyed by rule slug → stable Terraform addresses across rule reorderings.
# Exactly one of cidr_ipv4 / cidr_ipv6 / referenced_security_group_id / prefix_list_id
# should be set per rule (AWS requirement for vpc_security_group_*_rule).
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

  validation {
    condition = alltrue([
      for k, v in var.ingress_rules :
      length(compact([v.cidr_ipv4, v.cidr_ipv6, v.referenced_security_group_id, v.prefix_list_id])) == 1
    ])
    error_message = "Each ingress rule must set exactly one of cidr_ipv4, cidr_ipv6, referenced_security_group_id, or prefix_list_id."
  }
}

variable "egress_rules" {
  description = "Egress rules keyed by stable slug. Defaults to allow-all-outbound."
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

  validation {
    condition = alltrue([
      for k, v in var.egress_rules :
      length(compact([v.cidr_ipv4, v.cidr_ipv6, v.referenced_security_group_id, v.prefix_list_id])) == 1
    ])
    error_message = "Each egress rule must set exactly one of cidr_ipv4, cidr_ipv6, referenced_security_group_id, or prefix_list_id."
  }
}

variable "tags" {
  description = "Tags applied to the security group and its rules"
  type        = map(string)
  default     = {}
}

output "instance_id" {
  description = "EC2 instance ID"
  value       = module.ec2.instance_id
}

output "instance_public_ip" {
  description = "Public IP (EIP if attached, otherwise the instance's public IP)"
  value       = module.ec2.public_ip
}

output "instance_private_ip" {
  description = "Private IP of the instance"
  value       = module.ec2.private_ip
}

output "instance_public_dns" {
  description = "Public DNS of the instance"
  value       = module.ec2.public_dns
}

output "security_group_id" {
  description = "Security group ID attached to the instance"
  value       = module.security_group.id
}

output "ami_id" {
  description = "AMI ID actually used (pinned or resolved via lookup)"
  value       = local.resolved_ami_id
}

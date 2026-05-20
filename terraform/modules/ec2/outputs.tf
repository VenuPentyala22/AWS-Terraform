output "instance_id" {
  description = "EC2 instance ID"
  value       = aws_instance.this.id
}

output "instance_arn" {
  description = "EC2 instance ARN"
  value       = aws_instance.this.arn
}

output "private_ip" {
  description = "Private IP of the instance"
  value       = aws_instance.this.private_ip
}

output "public_ip" {
  description = "Public IP — EIP if attached, otherwise the instance's public IP"
  value       = var.create_eip ? aws_eip.this[0].public_ip : aws_instance.this.public_ip
}

output "public_dns" {
  description = "Public DNS of the instance"
  value       = aws_instance.this.public_dns
}

output "key_name" {
  description = "Name of the created key pair (null if not created)"
  value       = one(aws_key_pair.this[*].key_name)
}

output "eip_public_ip" {
  description = "Allocated EIP public IP (null when create_eip = false)"
  value       = one(aws_eip.this[*].public_ip)
}

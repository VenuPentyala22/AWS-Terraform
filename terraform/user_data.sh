#!/bin/bash
set -euo pipefail

# System updates
yum update -y

# Install common utilities
yum install -y \
  htop \
  git \
  curl \
  wget \
  unzip \
  jq

# Set hostname
hostnamectl set-hostname "${project_name}"

# Configure CloudWatch agent (optional – requires IAM role)
# yum install -y amazon-cloudwatch-agent

echo "Bootstrap complete for ${project_name}" >> /var/log/user-data.log

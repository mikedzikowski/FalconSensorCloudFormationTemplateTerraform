variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "cluster_name" {
  description = "Name of the ECS cluster"
  type        = string
}

variable "falcon_cid" {
  description = "CrowdStrike Falcon Customer ID"
  type        = string
}

variable "falcon_client_id" {
  description = "CrowdStrike Falcon API Client ID"
  type        = string
  sensitive   = true
}

variable "falcon_client_secret" {
  description = "CrowdStrike Falcon API Client Secret"
  type        = string
  sensitive   = true
}

variable "falcon_cloud_region" {
  description = "CrowdStrike Falcon Cloud Region"
  type        = string
  default     = "us-1"
}

variable "falcon_image_path" {
  description = "Path to Falcon sensor image in ECR"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "bottlerocket_ami_id" {
  description = "Bottlerocket AMI ID for ECS"
  type        = string
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "deployment_mode" {
  description = "Deployment mode: 'new_cluster' or 'existing_cluster'"
  type        = string
  default     = "new_cluster"
  validation {
    condition     = contains(["new_cluster", "existing_cluster"], var.deployment_mode)
    error_message = "deployment_mode must be either 'new_cluster' or 'existing_cluster'"
  }
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "existing_cluster_config" {
  description = "Configuration for existing cluster deployment"
  type = object({
    cluster_name = string
    vpc_id       = string
    subnet_ids   = list(string)
  })
  default = null
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "cluster_name" {
  description = "Name of the ECS cluster (for new cluster deployment)"
  type        = string
  default     = ""
}

variable "falcon_cid" {
  description = "CrowdStrike Falcon Customer ID"
  type        = string
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

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
}

variable "subnet_count" {
  description = "Number of subnets to create"
  type        = number
  default     = 2
}

variable "enable_nat_gateway" {
  description = "Enable NAT Gateway for private subnets"
  type        = bool
  default     = false
}

variable "asg_desired_capacity" {
  description = "Desired number of instances in ASG"
  type        = number
  default     = 2
}

variable "asg_max_size" {
  description = "Maximum number of instances in ASG"
  type        = number
  default     = 4
}

variable "asg_min_size" {
  description = "Minimum number of instances in ASG"
  type        = number
  default     = 1
}

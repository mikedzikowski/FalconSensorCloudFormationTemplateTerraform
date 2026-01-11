provider "aws" {
  region = var.aws_region
}

locals {
  create_new_cluster = var.deployment_mode == "new_cluster"
  cluster_name       = local.create_new_cluster ? var.cluster_name : var.existing_cluster_config.cluster_name
  vpc_id            = local.create_new_cluster ? aws_vpc.main[0].id : var.existing_cluster_config.vpc_id
  subnet_ids        = local.create_new_cluster ? aws_subnet.public[*].id : var.existing_cluster_config.subnet_ids
}

# VPC Resources - Only created for new cluster
resource "aws_vpc" "main" {
  count = local.create_new_cluster ? 1 : 0

  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(
    var.tags,
    {
      Name = "${var.environment}-ecs-vpc"
    }
  )
}

resource "aws_internet_gateway" "main" {
  count = local.create_new_cluster ? 1 : 0

  vpc_id = aws_vpc.main[0].id

  tags = merge(
    var.tags,
    {
      Name = "${var.environment}-ecs-igw"
    }
  )
}

resource "aws_subnet" "public" {
  count = local.create_new_cluster ? var.subnet_count : 0

  vpc_id                  = aws_vpc.main[0].id
  cidr_block             = cidrsubnet(var.vpc_cidr, 8, count.index)
  availability_zone      = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true

  tags = merge(
    var.tags,
    {
      Name = "${var.environment}-ecs-public-subnet-${count.index + 1}"
    }
  )
}

resource "aws_route_table" "public" {
  count = local.create_new_cluster ? 1 : 0

  vpc_id = aws_vpc.main[0].id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main[0].id
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.environment}-ecs-public-rt"
    }
  )
}

resource "aws_route_table_association" "public" {
  count = local.create_new_cluster ? var.subnet_count : 0

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public[0].id
}

# Security Group - Created for both modes
resource "aws_security_group" "ecs_instances" {
  name        = "${var.environment}-ecs-instances-sg"
  description = "Security group for ECS instances"
  vpc_id      = local.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.environment}-ecs-instances-sg"
    }
  )
}

# ECS Cluster - Only created for new cluster
resource "aws_ecs_cluster" "main" {
  count = local.create_new_cluster ? 1 : 0
  
  name = var.cluster_name

  tags = merge(
    var.tags,
    {
      Environment = var.environment
    }
  )
}

# CloudFormation stack for Falcon sensor - Created for both modes
resource "aws_cloudformation_stack" "falcon_sensor" {
  name = "${var.environment}-falcon-ecs-ec2-daemon"
  template_body = file("${path.module}/falcon-ecs-ec2-daemon.yaml")

  parameters = {
    ECSClusterName  = local.cluster_name
    FalconCID       = var.falcon_cid
    FalconImagePath = var.falcon_image_path
  }

  capabilities = ["CAPABILITY_IAM", "CAPABILITY_NAMED_IAM"]
}

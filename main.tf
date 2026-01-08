provider "aws" {
  region = var.aws_region
}

# Data source for availability zones
data "aws_availability_zones" "available" {
  state = "available"
}

# Create VPC for the ECS cluster
resource "aws_vpc" "main" {
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

# Create public subnets
resource "aws_subnet" "public" {
  count             = var.subnet_count
  vpc_id           = aws_vpc.main.id
  cidr_block       = cidrsubnet(var.vpc_cidr, 8, count.index)
  availability_zone = data.aws_availability_zones.available.names[count.index]
  
  map_public_ip_on_launch = !var.enable_nat_gateway

  tags = merge(
    var.tags,
    {
      Name = "${var.environment}-ecs-public-subnet-${count.index + 1}"
    }
  )
}

# Create Internet Gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = merge(
    var.tags,
    {
      Name = "${var.environment}-ecs-igw"
    }
  )
}

# Create route table
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.environment}-ecs-public-rt"
    }
  )
}

# Associate route table with subnets
resource "aws_route_table_association" "public" {
  count          = var.subnet_count
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# Create security group for ECS instances
resource "aws_security_group" "ecs_instances" {
  name        = "${var.environment}-ecs-instances-sg"
  description = "Security group for ECS instances"
  vpc_id      = aws_vpc.main.id

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

# Create ECS Cluster
resource "aws_ecs_cluster" "main" {
  name = var.cluster_name

  tags = merge(
    var.tags,
    {
      Environment = var.environment
    }
  )
}

# Create IAM role for ECS instances
resource "aws_iam_role" "ecs_instance_role" {
  name = "${var.environment}-ecs-instance-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = var.tags
}

# Attach ECS instance policy
resource "aws_iam_role_policy_attachment" "ecs_instance_role_policy" {
  role       = aws_iam_role.ecs_instance_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

# Create instance profile
resource "aws_iam_instance_profile" "ecs_instance_profile" {
  name = "${var.environment}-ecs-instance-profile"
  role = aws_iam_role.ecs_instance_role.name
}

# Deploy the CloudFormation stack for Falcon sensor
resource "aws_cloudformation_stack" "falcon_sensor" {
  name = "${var.environment}-falcon-ecs-ec2-daemon"
  template_body = file("${path.module}/falcon-ecs-ec2-daemon.yaml")

  parameters = {
    ECSClusterName  = aws_ecs_cluster.main.name
    FalconCID       = var.falcon_cid
    FalconImagePath = var.falcon_image_path
  }

  capabilities = ["CAPABILITY_IAM", "CAPABILITY_NAMED_IAM"]

  depends_on = [
    aws_ecs_cluster.main,
    aws_autoscaling_group.ecs
  ]
}

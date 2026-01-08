output "ecs_cluster_name" {
  description = "Name of the created ECS cluster"
  value       = aws_ecs_cluster.main.name
}

output "cloudformation_stack_name" {
  description = "Name of the Falcon sensor CloudFormation stack"
  value       = aws_cloudformation_stack.falcon_sensor.name
}

output "vpc_id" {
  description = "ID of the created VPC"
  value       = aws_vpc.main.id
}

output "public_subnet_ids" {
  description = "IDs of the public subnets"
  value       = aws_subnet.public[*].id
}

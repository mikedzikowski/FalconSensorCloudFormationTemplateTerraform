output "cluster_name" {
  description = "Name of the ECS cluster"
  value       = local.cluster_name
}

output "vpc_id" {
  description = "ID of the VPC"
  value       = local.vpc_id
}

output "subnet_ids" {
  description = "IDs of the subnets"
  value       = local.subnet_ids
}

output "security_group_id" {
  description = "ID of the ECS instances security group"
  value       = aws_security_group.ecs_instances.id
}

output "cloudformation_stack_name" {
  description = "Name of the Falcon sensor CloudFormation stack"
  value       = aws_cloudformation_stack.falcon_sensor.name
}

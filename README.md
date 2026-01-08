# ECS Bottlerocket Cluster with Falcon Sensor - Terraform

This repository provides Terraform configurations to deploy an ECS cluster using Bottlerocket OS and the CrowdStrike Falcon sensor. It transforms the official CrowdStrike AWS CloudFormation template into a comprehensive Terraform solution.

> This implementation is based on the official [CrowdStrike Falcon Sensor CloudFormation Template](https://github.com/CrowdStrike/aws-cloudformation-falcon-sensor-ecs) repository.

## Solution Overview

### Architecture Components

- VPC with configurable public subnets
- ECS Cluster running Bottlerocket OS
- Auto Scaling Group for EC2 instances
- CrowdStrike Falcon sensor running as ECS daemon service
- IAM roles and security groups
- Optional NAT Gateway configuration

### Original CloudFormation vs Terraform Implementation

The solution enhances the original CrowdStrike CloudFormation template by:
1. Maintaining the original Falcon sensor deployment logic
2. Adding complete infrastructure as code for the supporting components
3. Providing variable-driven configuration
4. Adding resource tagging support
5. Implementing monitoring and security features

## Prerequisites

1. AWS CLI configured with appropriate credentials
2. Terraform installed (version >= 1.0.0)
3. CrowdStrike Falcon credentials:
   - Customer ID (CID)
   - API Client ID
   - API Client Secret
4. Falcon sensor image in ECR repository

## Quick Start

1. Clone the repository:
```bash
git clone <repository-url>
cd <repository-name>
```

2. Create `terraform.tfvars` file with your values:
```hcl
aws_region           = "us-east-1"
environment          = "dev"
cluster_name         = "ecs-bottlerocket-cluster"
falcon_cid           = "YOUR_FALCON_CID"
falcon_client_id     = "YOUR_FALCON_CLIENT_ID"
falcon_client_secret = "YOUR_FALCON_CLIENT_SECRET"
falcon_image_path    = "YOUR_ECR_REPO/falconsensor:latest"
```

3. Initialize and apply Terraform:
```bash
terraform init
terraform plan
terraform apply
```

## Configuration Variables

### Network Configuration
| Variable | Description | Type | Default |
|----------|-------------|------|---------|
| vpc_cidr | CIDR block for VPC | string | "10.0.0.0/16" |
| subnet_count | Number of subnets to create | number | 2 |
| enable_nat_gateway | Enable NAT Gateway | bool | false |

### Instance Configuration
| Variable | Description | Type | Default |
|----------|-------------|------|---------|
| instance_type | EC2 instance type | string | "t3.micro" |
| enable_monitoring | Enable detailed monitoring | bool | true |
| root_volume_size | Size of root volume in GB | number | 30 |
| root_volume_type | Type of root volume | string | "gp3" |

### Auto Scaling Configuration
| Variable | Description | Type | Default |
|----------|-------------|------|---------|
| asg_desired_capacity | Desired number of instances | number | 2 |
| asg_max_size | Maximum number of instances | number | 4 |
| asg_min_size | Minimum number of instances | number | 1 |

## Verification Steps

1. Check ECS cluster status:
```bash
aws ecs list-container-instances \
    --cluster $(terraform output -raw ecs_cluster_name)
```

2. Verify Falcon sensor service:
```bash
aws ecs list-services \
    --cluster $(terraform output -raw ecs_cluster_name)
```

3. Check running tasks:
```bash
aws ecs list-tasks \
    --cluster $(terraform output -raw ecs_cluster_name) \
    --service-name crowdstrike-falcon-node-daemon
```

## Adding Nodes

To add nodes to your cluster:

1. Update the ASG desired capacity:
```hcl
# In terraform.tfvars
asg_desired_capacity = 3
```

2. Apply the changes:
```bash
terraform apply
```

3. Monitor new node registration:
```bash
watch -n 10 'aws ecs list-container-instances --cluster $(terraform output -raw ecs_cluster_name)'
```

## Troubleshooting

### Common Issues

1. Instances not joining ECS cluster:
   - Check security group rules
   - Verify IAM roles and policies
   - Review instance user data configuration

2. Falcon sensor not running:
   - Verify ECR permissions
   - Check CrowdStrike credentials
   - Review CloudFormation stack events

### Debugging Commands

```bash
# Check CloudFormation stack status
aws cloudformation describe-stack-events \
    --stack-name $(terraform output -raw cloudformation_stack_name)

# View ECS service events
aws ecs describe-services \
    --cluster $(terraform output -raw ecs_cluster_name) \
    --services crowdstrike-falcon-node-daemon

# Check ASG status
aws autoscaling describe-auto-scaling-groups \
    --auto-scaling-group-names $(terraform output -raw asg_name)
```

## Clean Up

To remove all resources:
```bash
terraform destroy
```

## Security Considerations

1. Network Security:
   - Instances are launched in public subnets by default
   - Security groups restrict inbound access
   - Optional NAT Gateway support for private subnets

2. Instance Security:
   - Bottlerocket OS provides enhanced security
   - Root volume encryption enabled
   - IMDSv2 supported
   - Optional termination protection

3. Credentials:
   - Sensitive variables marked as sensitive in Terraform
   - Credentials should be stored in terraform.tfvars (git ignored)
   - Consider using AWS Secrets Manager for production

## Contributing

1. Fork the repository
2. Create a feature branch
3. Commit your changes
4. Push to the branch
5. Create a Pull Request

## License
MIT License

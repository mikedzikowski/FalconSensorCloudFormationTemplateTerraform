# ECS Bottlerocket Cluster with Falcon Sensor - Terraform

This repository provides Terraform configurations to deploy an ECS cluster using Bottlerocket OS and the CrowdStrike Falcon sensor. It transforms the official CrowdStrike AWS CloudFormation template into a comprehensive Terraform solution.

> This implementation is based on the official [CrowdStrike Falcon Sensor CloudFormation Template](https://github.com/CrowdStrike/aws-cloudformation-falcon-sensor-ecs) repository.

## Quick Start with AWS CloudShell

### Prerequisites
- Access to AWS CloudShell
- CrowdStrike Falcon sensor image in ECR
- CrowdStrike Falcon credentials (CID)

### Deployment Steps
1. Clean up and clone repository:
```bash
# Go to home directory and remove existing repository
cd ~
rm -rf FalconSensorCloudFormationTemplateTerraform

# Clone repository
git clone https://github.com/mikedzikowski/FalconSensorCloudFormationTemplateTerraform.git
cd FalconSensorCloudFormationTemplateTerraform

# Get the official CrowdStrike YAML
curl -o falcon-ecs-ec2-daemon.yaml https://raw.githubusercontent.com/CrowdStrike/aws-cloudformation-falcon-sensor-ecs/main/falcon-sensor-ecs-ec2/falcon-ecs-ec2-daemon.yaml
```

2. Create terraform.tfvars:
```bash
cat << EOF > terraform.tfvars
# Region and Environment
aws_region  = "us-east-1"
environment = "test"

# Network Configuration
vpc_cidr            = "10.0.0.0/16"
subnet_count        = 2
enable_nat_gateway  = false

# ECS Cluster Configuration
cluster_name = "ecs-bottlerocket-test"

# CrowdStrike Falcon Configuration
falcon_cid           = "YOUR_FALCON_CID"
falcon_image_path    = "YOUR_ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/falconsensor:latest"

# Instance Configuration
instance_type        = "t3.micro"
bottlerocket_ami_id  = "ami-01663b95d1b411bf9"

# Resource Tags
tags = {
  Environment = "test"
  Project     = "falcon-ecs"
  Terraform   = "true"
}
EOF
```

3. Deploy:
```bash
terraform init
terraform plan
terraform apply
```

### Verification
```bash
# Check ECS tasks
aws ecs list-tasks \
    --cluster ecs-bottlerocket-test \
    --service-name crowdstrike-falcon-node-daemon

# Check EC2 instances
aws autoscaling describe-auto-scaling-groups \
    --auto-scaling-group-names test-ecs-asg
```

### Cleanup
```bash
terraform destroy
```

## Architecture

```
                                     ┌─────────────────┐
                                     │                 │
                                     │  Auto Scaling   │
                                     │     Group       │
                                     │                 │
                                     └────────┬────────┘
                                              │
                                              ▼
┌─────────────────┐                 ┌─────────────────┐
│                 │                 │                 │
│   ECS Cluster   │◄────────────────│  EC2 Instances  │
│                 │                 │  (Bottlerocket) │
│                 │                 │                 │
└────────┬────────┘                 └────────┬────────┘
         │                                   │
         │                                   ▼
         │                          ┌─────────────────┐
         │                          │                 │
         └─────────────────────────►│ Falcon Sensor  │
                                   │    (Daemon)     │
                                   │                 │
                                   └─────────────────┘
```

## CI/CD Pipeline Integration

This Terraform configuration can be used in CI/CD pipelines for Infrastructure as Code deployments. The repository includes all necessary configuration files for automated deployments through platforms like:
- GitHub Actions
- AWS CodePipeline
- Jenkins
- Azure DevOps

Required pipeline variables:
- AWS credentials
- CrowdStrike Falcon credentials
- Environment-specific configurations

## Troubleshooting

If you encounter "already exists" errors, manually clean up resources:
```bash
# Delete CloudFormation stack if it exists
aws cloudformation delete-stack --stack-name test-falcon-ecs-ec2-daemon

# Delete ASG if it exists
aws autoscaling delete-auto-scaling-group --auto-scaling-group-name test-ecs-asg --force-delete

# Clean up IAM resources if they exist
aws iam remove-role-from-instance-profile \
    --instance-profile-name test-ecs-instance-profile \
    --role-name test-ecs-instance-role
aws iam delete-instance-profile \
    --instance-profile-name test-ecs-instance-profile
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

3. Credentials:
   - Store sensitive values in terraform.tfvars (git ignored)
   - Use AWS Secrets Manager for production deployments
   - Follow least privilege principle for IAM roles

## License

MIT License

## Support

For issues related to:
- Infrastructure deployment: Open an issue in this repository
- Falcon sensor: Contact CrowdStrike support
- AWS services: Contact AWS support

# ECS Bottlerocket Cluster with Falcon Sensor - Terraform

This repository provides Terraform configurations to deploy an ECS cluster using Bottlerocket OS and the CrowdStrike Falcon sensor. It transforms the official CrowdStrike AWS CloudFormation template into a comprehensive Terraform solution.

> This implementation is based on the official [CrowdStrike Falcon Sensor CloudFormation Template](https://github.com/CrowdStrike/aws-cloudformation-falcon-sensor-ecs) repository.

## Quick Start with AWS CloudShell

### Prerequisites
- Access to AWS CloudShell
- CrowdStrike Falcon sensor image in ECR
  > **Important**: Follow [these instructions](https://github.com/CrowdStrike/aws-cloudformation-falcon-sensor-ecs/tree/main/falcon-sensor-ecs-ec2#step-1-get-the-falcon-sensor-image) to pull and push the Falcon sensor image to your ECR repository
- CrowdStrike Falcon credentials (CID)

The Falcon sensor image must be available in your ECR repository before deploying this solution. The image path in your `terraform.tfvars` should look like:
```hcl
falcon_image_path = "YOUR_ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/falconsensor:latest"
```

### Deployment Steps

1. Install Terraform in AWS CloudShell:
```bash
# Download Terraform
wget https://releases.hashicorp.com/terraform/1.6.6/terraform_1.6.6_linux_amd64.zip

# Install unzip if not already installed
sudo yum install -y unzip

# Unzip Terraform
unzip terraform_1.6.6_linux_amd64.zip

# Move Terraform to a directory in your PATH
sudo mv terraform /usr/local/bin/

# Verify installation
terraform version

# Clean up zip file
rm terraform_1.6.6_linux_amd64.zip
```

2. Clone repository and get CloudFormation template:
```bash
# Clone repository
git clone https://github.com/mikedzikowski/FalconSensorCloudFormationTemplateTerraform.git
cd FalconSensorCloudFormationTemplateTerraform

# Get the official CrowdStrike YAML
curl -o falcon-ecs-ec2-daemon.yaml https://raw.githubusercontent.com/CrowdStrike/aws-cloudformation-falcon-sensor-ecs/main/falcon-sensor-ecs-ec2/falcon-ecs-ec2-daemon.yaml
```

3. Create terraform.tfvars:
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

4. Deploy:
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

### Testing Auto-Deployment
To verify the Falcon sensor auto-deploys to new nodes:

```bash
# 1. Check current nodes
aws ecs list-container-instances \
    --cluster ecs-bottlerocket-test

# 2. Add a node by increasing ASG capacity
aws autoscaling update-auto-scaling-group \
    --auto-scaling-group-name test-ecs-asg \
    --desired-capacity 3

# 3. Monitor deployment
aws ecs list-container-instances \
    --cluster ecs-bottlerocket-test

# 4. Check Falcon sensor deployment
aws ecs list-tasks \
    --cluster ecs-bottlerocket-test \
    --service-name crowdstrike-falcon-node-daemon
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
```



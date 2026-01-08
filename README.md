# ECS Bottlerocket Cluster with Falcon Sensor - Terraform

This repository provides Terraform configurations to deploy an ECS cluster using Bottlerocket OS and the CrowdStrike Falcon sensor. It's based on the official CrowdStrike AWS CloudFormation template but reimplemented using Terraform for better infrastructure management.

## Solution Overview

### Original CloudFormation vs Terraform Implementation

The original solution uses AWS CloudFormation template (`falcon-ecs-ec2-daemon.yaml`) to:
- Create an ECS task definition for the Falcon sensor
- Deploy it as a daemon service on ECS

Our Terraform implementation:
1. Maintains the original CloudFormation template for the Falcon sensor deployment
2. Adds infrastructure as code for:
   - VPC and networking components
   - ECS cluster with Bottlerocket OS
   - Auto Scaling Group configuration
   - Security groups and IAM roles
3. Uses variables for environment-specific configurations

## Prerequisites

1. AWS CLI configured with appropriate credentials
2. Terraform installed (version >= 1.0.0)
3. CrowdStrike Falcon credentials:
   - Customer ID (CID)
   - API Client ID
   - API Client Secret
4. Falcon sensor image in ECR repository

## Deployment Steps

1. Clone the repository:
```bash
git clone <repository-url>
cd ecs-bottlerocket-falcon
```

2. Create `terraform.tfvars` file with your values:
```hcl
aws_region           = "us-east-1"
environment          = "dev"
vpc_cidr            = "10.0.0.0/16"
cluster_name         = "ecs-bottlerocket-cluster"
falcon_cid           = "YOUR_FALCON_CID"
falcon_client_id     = "YOUR_FALCON_CLIENT_ID"
falcon_client_secret = "YOUR_FALCON_CLIENT_SECRET"
falcon_cloud_region  = "us-1"
falcon_image_path    = "YOUR_ECR_REPO/falconsensor:latest"
instance_type        = "t3.micro"
bottlerocket_ami_id  = "ami-01663b95d1b411bf9"  # Update with latest Bottlerocket AMI
asg_desired_capacity = 2
asg_max_size        = 4
asg_min_size        = 1
```

3. Initialize Terraform:
```bash
terraform init
```

4. Review the deployment plan:
```bash
terraform plan
```

5. Apply the configuration:
```bash
terraform apply
```

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
    --cluster $(terraform output -raw ecs_cluster_name)
```

4. View task details:
```bash
TASK_ARN=$(aws ecs list-tasks \
    --cluster $(terraform output -raw ecs_cluster_name) \
    --service-name crowdstrike-falcon-node-daemon \
    --query 'taskArns[0]' --output text)

aws ecs describe-tasks \
    --cluster $(terraform output -raw ecs_cluster_name) \
    --tasks $TASK_ARN
```

5. Verify EC2 instances:
```bash
aws autoscaling describe-auto-scaling-groups \
    --auto-scaling-group-names $(terraform output -raw ecs_cluster_name)-asg
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

## Clean Up

To remove all resources:
```bash
terraform destroy
```

## Troubleshooting

1. If instances aren't joining the ECS cluster:
   - Check security group rules
   - Verify IAM roles and policies
   - Review instance user data configuration

2. If Falcon sensor isn't running:
   - Check ECR permissions
   - Verify CrowdStrike credentials
   - Review CloudFormation stack events

3. Common issues:
   ```bash
   # Check CloudFormation stack status
   aws cloudformation describe-stack-events \
       --stack-name $(terraform output -raw cloudformation_stack_name)

   # View ECS service events
   aws ecs describe-services \
       --cluster $(terraform output -raw ecs_cluster_name) \
       --services crowdstrike-falcon-node-daemon
   ```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Commit your changes
4. Push to the branch
5. Create a Pull Request

## License

MIT License
```

Would you like me to:
1. Add more troubleshooting steps?
2. Include additional verification commands?
3. Expand any specific section?

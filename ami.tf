data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_ami" "bottlerocket_ami" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["bottlerocket-aws-ecs-1-*-x86_64"]
  }
}

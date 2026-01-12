# Data source for Bottlerocket AMI
data "aws_ami" "bottlerocket_ami" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "image-id"
    values = [var.bottlerocket_ami_id]
  }
}
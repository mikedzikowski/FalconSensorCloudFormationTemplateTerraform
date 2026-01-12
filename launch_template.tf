# Create launch template
resource "aws_launch_template" "ecs" {
  name_prefix   = "${var.environment}-ecs-template"
  image_id      = data.aws_ami.bottlerocket_ami.id
  instance_type = var.instance_type

  monitoring {
    enabled = var.enable_monitoring
  }

  user_data = base64encode(<<-EOF
    [settings.ecs]
    cluster = "${aws_ecs_cluster.main.name}"
    [settings.host-containers.admin]
    enabled = true
    [settings.host-containers.control]
    enabled = true
    EOF
  )

  network_interfaces {
    associate_public_ip_address = !var.enable_nat_gateway
    security_groups            = [aws_security_group.ecs_instances.id]
  }

  iam_instance_profile {
    name = aws_iam_instance_profile.ecs_instance_profile.name
  }

  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      volume_size = var.root_volume_size
      volume_type = var.root_volume_type
      encrypted   = true
    }
  }

  tag_specifications {
    resource_type = "instance"
    tags = merge(
      var.tags,
      {
        Name = "${var.environment}-ecs-instance"
      }
    )
  }

  tags = var.tags
}

# Create Auto Scaling Group
resource "aws_autoscaling_group" "ecs" {
  name                = "${var.environment}-ecs-asg"
  desired_capacity    = var.asg_desired_capacity
  max_size           = var.asg_max_size
  min_size           = var.asg_min_size
  target_group_arns  = []
  vpc_zone_identifier = aws_subnet.public[*].id

  launch_template {
    id      = aws_launch_template.ecs.id
    version = "$Latest"
  }

  dynamic "tag" {
    for_each = merge(
      var.tags,
      {
        AmazonECSManaged = "true"
      }
    )
    content {
      key                 = tag.key
      value              = tag.value
      propagate_at_launch = true
    }
  }

  protect_from_scale_in = var.enable_termination_protection
}
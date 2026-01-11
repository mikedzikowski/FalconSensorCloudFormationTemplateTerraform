# Launch template and ASG - Only created for new cluster
resource "aws_launch_template" "ecs" {
  count = local.create_new_cluster ? 1 : 0

  name_prefix   = "${var.environment}-ecs-template"
  image_id      = data.aws_ami.bottlerocket_ami.id
  instance_type = var.instance_type

  user_data = base64encode(<<-EOF
    [settings.ecs]
    cluster = "${local.cluster_name}"
    [settings.host-containers.admin]
    enabled = true
    [settings.host-containers.control]
    enabled = true
    EOF
  )

  network_interfaces {
    associate_public_ip_address = true
    security_groups            = [aws_security_group.ecs_instances.id]
  }

  iam_instance_profile {
    name = aws_iam_instance_profile.ecs_instance_profile.name
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
}

resource "aws_autoscaling_group" "ecs" {
  count = local.create_new_cluster ? 1 : 0

  name                = "${var.environment}-ecs-asg"
  desired_capacity    = var.asg_desired_capacity
  max_size           = var.asg_max_size
  min_size           = var.asg_min_size
  target_group_arns  = []
  vpc_zone_identifier = local.subnet_ids

  launch_template {
    id      = aws_launch_template.ecs[0].id
    version = "$Latest"
  }

  tag {
    key                 = "AmazonECSManaged"
    value              = "true"
    propagate_at_launch = true
  }

  dynamic "tag" {
    for_each = var.tags
    content {
      key                 = tag.key
      value              = tag.value
      propagate_at_launch = true
    }
  }
}

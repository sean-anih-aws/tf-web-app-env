# Launch Template
resource "aws_launch_template" "my_template" {
  name          = "your-launch-template"
  image_id      = "ami-012967cc5a8c9f891"
  instance_type = var.instance_type

  vpc_security_group_ids = [aws_security_group.app_instance.id]

  tag_specifications {
    resource_type = "instance"

    tags = {
      Name = "Launch Template Instance"
    }
  }
}

# Auto Scaling Group
resource "aws_autoscaling_group" "private_instance_asg" {
  desired_capacity = var.asg_instance_desired_size
  max_size         = var.asg_instance_max_size
  min_size         = var.asg_instance_min_size

  launch_template {
    id = aws_launch_template.my_template.id
  }
  vpc_zone_identifier = [aws_subnet.private_subnet_a.id, aws_subnet.private_subnet_b.id]

  tag {
    key                 = "Name"
    value               = "PrivateInstance"
    propagate_at_launch = true
  }
}
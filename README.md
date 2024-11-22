## Introduction

This project demonstrates the deployment of a scalable web application using Terraform, featuring an Application Load Balancer, Auto Scaling Group, and secure networking across public and private subnets.

---

### Configuration Overview

#### Terraform Configuration

```
terraform {
  required_providers {
    aws = {
      version = "~> 5.0"
    }
  }
  backend "s3" {
    bucket         = "your-bucket-name"
    key            = "backend.tfstate"
    region         = "us-east-1"
    dynamodb_table = "your-table-name"
  }
}

provider "aws" {
  region = "us-east-1"
}
```

_Variables aren't allowed in the Terraform block, so you have to create the S3 bucket and DynamoDB table separately and paste the information here._

_Also, Terraform needs your `AWS Access Key ID` and `Secret Access Key` in order to access your account. You can hardcode them into the `provider` block, load them as environment variables, or add them to your `.aws/config` file._

- **Provider:** Specifies AWS as the provider with a required version `~> 5.0`.
- **Backend:** Configures remote state management using:
  - **S3 Bucket:** `your-bucket-name` to store the state file.
  - **Key:** `backend.tfstate` to uniquely identify the state file.
  - **Region:** `us-east-1` for the S3 bucket and DynamoDB table.
  - **DynamoDB Table:** `your-table-name` for state locking and consistency.

#### AWS Provider

- **Region:** Sets the deployment region to `us-east-1`.

---

### Variables

```
variable "vpc_cidr" {
  default = "10.0.0.0/16"
}

variable "public_subnet_a_cidr" {
  default = "10.0.1.0/24"
}

variable "public_subnet_b_cidr" {
  default = "10.0.2.0/24"
}

variable "private_subnet_a_cidr" {
  default = "10.0.3.0/24"
}

variable "private_subnet_b_cidr" {
  default = "10.0.4.0/24"
}

variable "instance_type" {
  default = "t2.micro"
}

variable "asg_instance_min_size" {
  default = 1
}

variable "asg_instance_desired_size" {
  default = 2
}

variable "asg_instance_max_size" {
  default = 3
}
```

These are the variables needed to configure various resources. You can keep the default values or change them to fit your needs.

---

### Networking Configuration

```
resource "aws_vpc" "intern_vpc" {
  cidr_block = var.vpc_cidr

  tags = {
    Name = "Internship-VPC"
  }
}

resource "aws_subnet" "public_subnet_a" {
  vpc_id                  = aws_vpc.intern_vpc.id
  cidr_block              = var.public_subnet_a_cidr
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "public subnet A"
  }
}

resource "aws_subnet" "public_subnet_b" {
  vpc_id                  = aws_vpc.intern_vpc.id
  cidr_block              = var.public_subnet_b_cidr
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = true

  tags = {
    Name = "public subnet B"
  }
}

resource "aws_subnet" "private_subnet_a" {
  vpc_id            = aws_vpc.intern_vpc.id
  cidr_block        = var.private_subnet_a_cidr
  availability_zone = "us-east-1a"

  tags = {
    Name = "private subnet A"
  }
}

resource "aws_subnet" "private_subnet_b" {
  vpc_id            = aws_vpc.intern_vpc.id
  cidr_block        = var.private_subnet_b_cidr
  availability_zone = "us-east-1b"

  tags = {
    Name = "private subnet B"
  }
}

resource "aws_internet_gateway" "ig" {
  vpc_id = aws_vpc.intern_vpc.id
}

resource "aws_route_table" "route_table" {
  vpc_id = aws_vpc.intern_vpc.id

  route {
    # traffic LEAVING the route table to any IP over the internet
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.ig.id
  }
}
```

This Terraform configuration establishes the foundational networking resources for a scalable web application. It creates a Virtual Private Cloud (VPC) with public and private subnets distributed across two availability zones. The public subnets are configured to assign public IP addresses to instances on launch, while the private subnets remain isolated. An Internet Gateway enables outbound internet access, and a route table directs traffic from the public subnets to the internet.

---

### Security Groups Configuration

```
resource "aws_security_group" "lb_sg" {
  name        = "allow_tls"
  description = "load balancer security group"
  vpc_id      = aws_vpc.intern_vpc.id

  tags = {
    Name = "allow_tls"
  }
}

resource "aws_vpc_security_group_ingress_rule" "lb_sg_ingress" {
  security_group_id = aws_security_group.lb_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  ip_protocol       = "tcp"
  to_port           = 80
}

resource "aws_security_group" "app_instance" {
  name        = "app_instance"
  description = "app instance security group"
  vpc_id      = aws_vpc.intern_vpc.id

  tags = {
    Name = "app_instance"
  }
}

resource "aws_vpc_security_group_ingress_rule" "app_sg_ingress" {
  security_group_id            = aws_security_group.app_instance.id
  referenced_security_group_id = aws_security_group.lb_sg.id
  from_port                    = 80
  ip_protocol                  = "tcp"
  to_port                      = 80
}
```

This code defines security groups and ingress rules to manage network traffic for the application. It creates a security group for the load balancer (`lb_sg`) and another for the application instances (`app_instance`).

- The load balancer security group allows inbound HTTP traffic from any IP address.
- The application instance security group permits HTTP traffic originating from the load balancer.

This configuration ensures controlled communication between the load balancer and backend instances within the VPC.

---

### Launch Template & Auto Scaling Group Configuration

```
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
```

This code configures an EC2 launch template and an Auto Scaling Group (ASG) to manage application instances:

- **Launch Template**: Defines the instance properties such as the AMI, instance type, and associated security group (`app_instance`). It includes tags for identifying launched instances.

- **Auto Scaling Group**: Automatically manages the deployment of instances across private subnets (`private_subnet_a` and `private_subnet_b`) with desired, minimum, and maximum instance counts. Instances launched by the ASG inherit tags for easy identification.

This setup ensures scalable and resilient instance management for private application resources.

---

### Application Load Balancer Configuration

```
resource "aws_lb" "my_alb" {
  name               = "my-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.lb_sg.id]
  subnets            = [aws_subnet.public_subnet_a.id, aws_subnet.public_subnet_b.id]

  tags = {
    Environment = "Intern ENV"
  }
}

resource "aws_lb_target_group" "alb_tg" {
  name     = "my-target-group"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.intern_vpc.id

  health_check {
    path                = "/"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 3
    unhealthy_threshold = 3
  }

  tags = {
    Environment = "Intern ENV"
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.my_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.alb_tg.arn
  }
}
```

This code sets up an Application Load Balancer (ALB) to distribute traffic to application instances:

- **Load Balancer**: Deploys a public-facing ALB across two public subnets, secured by a specified security group (`lb_sg`). It facilitates HTTP traffic distribution and tagging for environment identification.

- **Target Group**: Defines a group of targets (application instances) that receive traffic from the ALB. Configured for HTTP traffic on port 80, with health checks ensuring instance availability and reliability.

- **Listener**: Configures the ALB to listen for incoming HTTP traffic on port 80 and forwards it to the target group (`alb_tg`) as the default action.

This setup ensures traffic routing to backend instances with health monitoring.

---

### Output Configuration

```
output "public-alb-dns-name" {
  value = aws_lb.my_alb.dns_name
}
```

This code defines an output variable:

- **Public ALB DNS Name**: Exposes the DNS name of the deployed Application Load Balancer (`my_alb`). This value can be used to access the ALB and verify its functionality.

The output provides a convenient way to reference the ALB endpoint after deployment.

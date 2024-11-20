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
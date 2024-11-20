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
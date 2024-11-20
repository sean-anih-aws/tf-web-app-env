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

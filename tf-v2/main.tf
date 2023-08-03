# Based on https://www.youtube.com/watch?v=6XSroskdCF0
# and https://github.com/antonputra/tutorials/blob/main/lessons/164/main.tf
#
# This script is missing the creation of
# Internet Gateway attached to the VPC,
# the route for 0.0.0.0 to the Internet
# gateway in VPC route table, the subnets 
# added to the routing table.
#
# terraform plan -var "server_port=8080"
# or
# export TF_VAR_server_port=8080

provider "aws" {
    region = "us-east-1"
}

resource "aws_vpc" "tfpoc_vpc" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"

  tags = {
    Name = "tfpoc"
  }
}

resource "aws_subnet" "tfpoc_subnet1" {
  vpc_id            = aws_vpc.tfpoc_vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "tfpoc"
  }
}

resource "aws_subnet" "tfpoc_subnet2" {
  vpc_id            = aws_vpc.tfpoc_vpc.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "us-east-1b"

  tags = {
    Name = "tfpoc"
  }
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [aws_vpc.tfpoc_vpc.id]
  }
}

resource "aws_launch_configuration" "example" {
    image_id = "ami-053b0d53c279acc90"
    instance_type = "t2.micro"
    security_groups = [aws_security_group.instance.id]

    user_data = <<-EOF
        #!/bin/bash
        echo "Hello, World" > index.html
        nohup busybox httpd -f -p ${var.server_port} &
        EOF

    #user_data_replace_on_change = true

    # Required for autoscaling group
    lifecycle {
      create_before_destroy = true
    }

}

resource "aws_security_group" "instance" {
    name = "web"
    vpc_id = aws_vpc.tfpoc_vpc.id

    ingress {
        from_port = var.server_port
        to_port   = var.server_port
        protocol  = "tcp"
        cidr_blocks = [ "0.0.0.0/0" ]

    }
}

resource "aws_autoscaling_group" "example" {
  launch_configuration = aws_launch_configuration.example.name
  #vpc_zone_identifier = [ aws_vpc.tfpoc_vpc.id ]
  vpc_zone_identifier = data.aws_subnets.default.ids

  target_group_arns = [aws_lb_target_group.asg.arn]
  health_check_type = "ELB"

  min_size = 1
  max_size = 2

  tag {
    key                 = "Name"
    value               = "my-ubuntu"
    propagate_at_launch = true
  }

  tag {
    key                 = "GBL_CLASS_0"
    value               = "TEST"
    propagate_at_launch = true
  }

  tag {
    key                 = "GBL_CLASS_1"
    value               = "TEST"
    propagate_at_launch = true
  }

  tag {
    key                 = "SEC_ASSETS_GATEWAY"
    value               = "GENERAL"
    propagate_at_launch = true
  }

  tag {
    key                 = "provisioned"
    value               = "manual"
    propagate_at_launch = true
  }

  tag {
    key                 = "SEC_ASSETS"
    value               = "TEST"
    propagate_at_launch = true
  }

  tag {
    key                 = "soc2_scope"
    value               = "no"
    propagate_at_launch = true
  }

}

resource "aws_lb" "example" {

  name = "web"
  load_balancer_type = "application"
  subnets = data.aws_subnets.default.ids
  security_groups = [aws_security_group.alb.id]
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.example.arn
  port = 80
  protocol = "HTTP"

  # By default, it just shows a simple 404 page
  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "404: page not found"
      status_code = 404
    }
  }
}

resource "aws_security_group" "alb" {
  name = "web-alb"
  vpc_id = aws_vpc.tfpoc_vpc.id

  #Allow inbound HTTP requests
  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  #Allow all outbound requests
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_lb_target_group" "asg" {
  name = "web-example"
  port = var.server_port
  protocol = "HTTP"
  vpc_id = aws_vpc.tfpoc_vpc.id

  health_check {
    path = "/"
    protocol = "HTTP"
    matcher = "200"
    interval = 15
    timeout = 3
    healthy_threshold = 2
    unhealthy_threshold = 2
  }
  
}

resource "aws_lb_listener_rule" "asg" {

  listener_arn = aws_lb_listener.http.arn
  priority = 100
  
  condition {
    path_pattern {
      values = ["*"]
    }
  }

  action {
    type = "forward"
    target_group_arn = aws_lb_target_group.asg.arn
  }

  
}

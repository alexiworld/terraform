# Follow https://www.youtube.com/watch?v=VJYA8mzmqFk 
# to create a VPC "tfpoc_vpc" with 2 subnets  
# "tfpoc_subnet1" and "tfpoc_subnet2", an internet
# gateway, associate the internet gateway to the vpc,
# and add route for 0.0.0.0 to the internet gateway
# in the VPC routing table, and add the 2 subnets to
# the same routing table (another tab). Must ensure
# the subnets are placed in different availability 
# zones because of application loadbalancer.
# Upon the successfull run of the terraform script
# the output will produce the domain to curl and
# see Hello, World.
#
# Commands:
# terraform init
# terraform apply
# terraform distroy
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
    Name = "tfpoc_vpc"
  }
}

data "aws_vpc" "tfpoc_vpc" {
  depends_on = [
    aws_vpc.tfpoc_vpc
  ]
  tags = {
    Name = "tfpoc_vpc"
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

resource "aws_internet_gateway_attachment" "tfpoc_gw_att" {
  internet_gateway_id = aws_internet_gateway.tfpoc_gw.id
  vpc_id              = aws_vpc.tfpoc_vpc.id
}

resource "aws_internet_gateway" "tfpoc_gw" {}


data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.tfpoc_vpc.id]
  }
}

# Creates a new route table. Changing the Name tag to "-" may
# or may not work.
#
# resource "aws_route_table" "tfpoc_routetable" {
#   vpc_id = aws_vpc.tfpoc_vpc.id
#
#   route {
#     cidr_block = "0.0.0.0/0"
#     gateway_id = aws_internet_gateway.tfpoc_gw.id
#   }
#
#   route {
#     ipv6_cidr_block        = "::/0"
#     gateway_id = aws_internet_gateway.tfpoc_gw.id
#   }
#
#   # tags = {
#   #   Name = "tfpoc_gw"
#   # }
# }
#
# resource "aws_route_table_association" "tfpoc_subnet1_ass" {
#   subnet_id      = aws_subnet.tfpoc_subnet1.id
#   route_table_id = aws_route_table.tfpoc_routetable.id
# }
#
# resource "aws_route_table_association" "tfpoc_subnet2_ass" {
#   subnet_id      = aws_subnet.tfpoc_subnet2.id
#   route_table_id = aws_route_table.tfpoc_routetable.id
# }

resource "aws_route" "tfpoc_route1" {
  route_table_id  = aws_vpc.tfpoc_vpc.default_route_table_id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id = aws_internet_gateway.tfpoc_gw.id
}
  
resource "aws_route" "tfpoc_route2" {
  route_table_id  = aws_vpc.tfpoc_vpc.default_route_table_id
  destination_ipv6_cidr_block = "::/0"
  gateway_id = aws_internet_gateway.tfpoc_gw.id
}

resource "aws_route_table_association" "tfpoc_subnet1_ass" {
  subnet_id      = aws_subnet.tfpoc_subnet1.id
  route_table_id = aws_vpc.tfpoc_vpc.default_route_table_id
}

resource "aws_route_table_association" "tfpoc_subnet2_ass" {
  subnet_id      = aws_subnet.tfpoc_subnet2.id
  route_table_id = aws_vpc.tfpoc_vpc.default_route_table_id
}

resource "aws_instance" "example" {
  ami           = "ami-053b0d53c279acc90"
  instance_type = "t2.micro"
  subnet_id = data.aws_subnets.default.ids[0]

  vpc_security_group_ids = [aws_security_group.instance.id]

  user_data = <<-EOF
              #!/bin/bash
              echo "Hello, World" > index.html
              nohup busybox httpd -f -p ${var.server_port} &
              EOF

  user_data_replace_on_change = true

    tags = {
        Name = "my-ubuntu"
        GBL_CLASS_0 = "TEST"
        GBL_CLASS_1 = "TEST"
        SEC_ASSETS_GATEWAY = "GENERAL"
        provisioned	= "manual"
        SEC_ASSETS = "TEST"
        soc2_scope = "no"
    }
}

resource "aws_launch_configuration" "example" {
  image_id      = "ami-053b0d53c279acc90"
  instance_type   = "t2.micro"
  security_groups = [aws_security_group.instance.id]

  user_data = <<-EOF
              #!/bin/bash
              echo "Hello, World" > index.html
              nohup busybox httpd -f -p ${var.server_port} &
              EOF

  # Required with an autoscaling group.
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group" "instance" {
  name = "web"
  vpc_id = aws_vpc.tfpoc_vpc.id

  ingress {
    from_port   = var.server_port
    to_port     = var.server_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_autoscaling_group" "example" {
  launch_configuration = aws_launch_configuration.example.name
  vpc_zone_identifier  = data.aws_subnets.default.ids

  target_group_arns = [aws_lb_target_group.asg.arn]
  health_check_type = "ELB"

  min_size = 2
  max_size = 10

  tag {
    key                 = "Name"
    value               = "web"
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
  name               = "web"
  load_balancer_type = "application"
  subnets            = data.aws_subnets.default.ids
  security_groups    = [aws_security_group.alb.id]
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.example.arn
  port              = 80
  protocol          = "HTTP"

  # By default, it just shows a simple 404 page
  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "404: page not found"
      status_code  = 404
    }
  }
}

resource "aws_security_group" "alb" {
  name = "web-alb"
  vpc_id = aws_vpc.tfpoc_vpc.id

  # Allow inbound HTTP requests
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow all outbound requests
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_lb_target_group" "asg" {
  name     = "web-example"
  port     = var.server_port
  protocol = "HTTP"
  vpc_id   = aws_vpc.tfpoc_vpc.id

  health_check {
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 15
    timeout             = 3
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

resource "aws_lb_listener_rule" "asg" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 100

  condition {
    path_pattern {
      values = ["*"]
    }
  }

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.asg.arn
  }
}
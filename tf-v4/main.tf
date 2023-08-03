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
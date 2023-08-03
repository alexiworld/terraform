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

resource "aws_subnet" "tfpoc_subnet" {
  vpc_id            = aws_vpc.tfpoc_vpc.id
  cidr_block        = "10.0.0.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "tfpoc"
  }
}

resource "aws_instance" "example" {
    ami = "ami-053b0d53c279acc90"
    instance_type = "t2.micro"
    subnet_id = aws_subnet.tfpoc_subnet.id

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
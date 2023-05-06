##### VASU $$$
resource "aws_vpc" "main" {
  cidr_block       = "172.2.0.0/16"
  instance_tenancy = "default"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "terraform-ashok"
  }
}

data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_security_group" "ingress-policy" {
  vpc_id        = aws_vpc.main.id
  ingress {
    cidr_blocks = ["192.168.10.15/32",]
    from_port   = 22  # Port from 22 to 22...
    to_port     = 22
    protocol    = "tcp"
  }

  ## This egress rule was missing from my original question...
  egress {
    # Terraform doesn't allow all egress traffic by default...
    cidr_blocks = ["0.0.0.0/0"]
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
  }

  tags = {
    Name = "sg-private"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "main"
  }
}

resource "aws_route" "r" {
  route_table_id            = aws_route_table.rt.id
  destination_cidr_block    = "0.0.0.0/0"
  gateway_id = aws_internet_gateway.igw.id
}

resource "aws_route_table" "rt" {
  vpc_id = aws_vpc.main.id
}

resource "aws_route_table_association" "rta" {
  subnet_id      = aws_subnet.cidr.id
  route_table_id = aws_route_table.rt.id
}

resource "aws_instance" "app_server" {
  #ami           = "ami-0edab8d70528476d3"
  ami = var.AMIS
  instance_type = "t2.small"
  #public_dns = true
  #key_name      = aws_key_pair.mykeypair.key_name
  key_name      = "jenkinsnew"

  subnet_id = aws_subnet.cidr.id
  vpc_security_group_ids = [
    aws_security_group.ingress-policy.id,
  ]
  associate_public_ip_address = true

  root_block_device {
    delete_on_termination = false
  }

  #user_data = <<-EOF
  #            #!/bin/bash
  #            apt-get update
  #            apt-get install openssh-server
  #            EOF
  tags = {
    Name = "JenkinsInstance"
  }
}

resource "aws_subnet" "cidr" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "172.2.0.0/24"
}

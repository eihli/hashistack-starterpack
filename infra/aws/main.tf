terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.27"
    }
  }
}

provider "aws" {
  profile = "default"
  region  = var.region
}

# Consul + Nomad server cluster

variable "region" {
  default = "us-east-2"
}
variable "availability_zone" {
  default = "us-east-2a"
}
variable "server_ami" {
  default = "ami-002ff389bfa57247f"
}
variable "instance_count" {
  default = 3
}
variable "instance_type" {
  default = "t2.micro"
}

resource "aws_vpc" "default_vpc" {
  cidr_block = "10.0.0.0/26"
}

resource "aws_subnet" "public" {
  vpc_id            = aws_vpc.default_vpc.id
  cidr_block        = "10.0.0.0/28"
  availability_zone = var.availability_zone
}

resource "aws_internet_gateway" "gateway" {
  vpc_id = aws_vpc.default_vpc.id
}

resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.default_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gateway.id
  }
}

resource "aws_route_table_association" "public_route_association" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public_route_table.id
}

resource "aws_security_group" "allow_ssh" {
  name   = "allow_ssh"
  vpc_id = aws_vpc.default_vpc.id

  ingress {
    from_port = 22
    to_port   = 22
    protocol  = "tcp"
    cidr_blocks = [
    "0.0.0.0/0"]
  }

  egress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    cidr_blocks = [
    "0.0.0.0/0"]
  }
}

resource "aws_instance" "servers" {
  count                       = var.instance_count
  ami                         = var.server_ami
  instance_type               = var.instance_type
  key_name                    = "default"
  subnet_id                   = aws_subnet.public.id
  associate_public_ip_address = "true"
  vpc_security_group_ids = [
    "${aws_security_group.allow_ssh.id}"
  ]
  tags = {
    Name = "Hashicorp Server Node ${count.index}"
  }
}

resource "aws_instance" "clients" {
  count                       = var.instance_count
  ami                         = var.server_ami
  instance_type               = var.instance_type
  key_name                    = "default"
  subnet_id                   = aws_subnet.public.id
  associate_public_ip_address = "true"
  vpc_security_group_ids = [
    "${aws_security_group.allow_ssh.id}"
  ]
  tags = {
    Name = "Hashicorp Server Node ${count.index}"
  }
}



output "ec2_server_ip" {
  value = {
    for instance in aws_instance.servers :
    instance.id => "${instance.public_ip}"
  }
}

output "ec2_client_ip" {
  value = {
    for instance in aws_instance.clients :
    instance.id => "${instance.public_ip}"
  }
}

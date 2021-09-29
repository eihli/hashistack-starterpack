terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.27"
    }
  }
}

// References:
// https://hands-on.cloud/terraform-managing-aws-vpc-creating-private-subnets/

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
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "Default VPC"
  }
}

resource "aws_subnet" "public" {
  vpc_id            = aws_vpc.default_vpc.id
  cidr_block        = "10.0.0.0/28"
  availability_zone = var.availability_zone
  map_public_ip_on_launch = true

  tags = {
    Name = "Public Subnet"
  }
}

resource "aws_subnet" "private" {
  vpc_id     = aws_vpc.default_vpc.id
  cidr_block = "10.0.1.0/24"
  availability_zone = var.availability_zone

  tags = {
    Name = "NAT-ed Private Subnet"
  }
}

resource "aws_internet_gateway" "gateway" {
  vpc_id = aws_vpc.default_vpc.id

  tags = {
    Name = "Default VPC Internet Gateway"
  }
}

resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.default_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gateway.id
  }

  tags = {
    Name = "Public Subnet Route Table"
  }
}

resource "aws_route_table_association" "public_route_association" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public_route_table.id
}

resource "aws_default_security_group" "default" {
  vpc_id = aws_vpc.default_vpc.id

  ingress {
    protocol  = "-1"
    self      = true
    from_port = 0
    to_port   = 0
    cidr_blocks = ["10.0.0.0/16"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "allow_ssh" {
  name   = "allow_ssh"
  vpc_id = aws_vpc.default_vpc.id
  tags = {
    Name = "Allow SSH Security Group"
  }
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

// This setup will result in a private subnet where machines will have access to the internet
// but will not be visible from the internet.
//
// See the "Fully Isolated Private Subnet" section
// of https://hands-on.cloud/terraform-managing-aws-vpc-creating-private-subnets/
// for a setup where machines on the private subnet will not have access out.

// Now let’s create NAT Gateway in a public subnet by declaring aws_nat_gateway and aws_eip.
resource "aws_eip" "nat_gw_eip" {
  vpc = true
  // https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eip
  // EIP may require IGW to exist prior to association. Use depends_on to set an explicit dependency on the IGW.
  depends_on = [aws_internet_gateway.gateway]
}

resource "aws_nat_gateway" "gateway" {
  depends_on = [aws_eip.nat_gw_eip]
  allocation_id = aws_eip.nat_gw_eip.id
  subnet_id     = aws_subnet.private.id
}

resource "aws_route_table" "default_vpc_nated" {
  vpc_id = aws_vpc.default_vpc.id

  tags = {
    Name = "Main Route Table for NAT-ed Private Subnet"
  }
}

resource "aws_route_table_association" "default_vpc_nated" {
  subnet_id = aws_subnet.private.id
  route_table_id = aws_route_table.default_vpc_nated.id
}

resource "aws_security_group" "consul_agents" {
  name   = "consul_agents"
  vpc_id = aws_vpc.default_vpc.id

  ingress {
      from_port = 8600
      to_port   = 8600
      protocol  = "tcp"
      cidr_blocks = [
        "10.0.0.0/26"
      ]
  }
  ingress {
      from_port = 8600
      to_port   = 8600
      protocol  = "udp"
      cidr_blocks = [
        "10.0.0.0/26"
      ]
  }
  ingress {
      from_port = 8500
      to_port   = 8500
      protocol  = "tcp"
      cidr_blocks = [
        "10.0.0.0/26"
      ]
  }
  ingress {
      from_port = 8301
      to_port   = 8301
      protocol  = "tcp"
      cidr_blocks = [
        "10.0.0.0/26"
      ]
  }
  ingress {
      from_port = 8301
      to_port   = 8301
      protocol  = "udp"
      cidr_blocks = [
        "10.0.0.0/26"
      ]
  }
  ingress {
      from_port = 8300
      to_port   = 8300
      protocol  = "tcp"
      cidr_blocks = [
        "10.0.0.0/26"
      ]
  }
  ingress {
      from_port = 21000
      to_port   = 21255
      protocol  = "tcp"
      cidr_blocks = [
        "10.0.0.0/26"
      ]
  }


  egress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    cidr_blocks = [
      "0.0.0.0/0"
    ]
  }
  egress {
      from_port = 8600
      to_port   = 8600
      protocol  = "tcp"
      cidr_blocks = [
        "10.0.0.0/26"
      ]
  }
  egress {
      from_port = 8600
      to_port   = 8600
      protocol  = "udp"
      cidr_blocks = [
        "10.0.0.0/26"
      ]
  }
  egress {
      from_port = 8500
      to_port   = 8500
      protocol  = "tcp"
      cidr_blocks = [
        "10.0.0.0/26"
      ]
  }
  egress {
      from_port = 8301
      to_port   = 8301
      protocol  = "tcp"
      cidr_blocks = [
        "10.0.0.0/26"
      ]
  }
  egress {
      from_port = 8301
      to_port   = 8301
      protocol  = "udp"
      cidr_blocks = [
        "10.0.0.0/26"
      ]
  }
  egress {
      from_port = 8300
      to_port   = 8300
      protocol  = "tcp"
      cidr_blocks = [
        "10.0.0.0/26"
      ]
  }
  egress {
      from_port = 21000
      to_port   = 21255
      protocol  = "tcp"
      cidr_blocks = [
        "10.0.0.0/26"
      ]
  }
}

resource "aws_security_group" "nomad_agents" {
  name   = "nomad_agents"
  vpc_id = aws_vpc.default_vpc.id

  ingress {
      from_port = 4646
      to_port   = 4648
      protocol  = "tcp"
      cidr_blocks = [
        "10.0.0.0/26"
      ]
  }
  ingress {
      from_port = 4648
      to_port   = 4648
      protocol  = "udp"
      cidr_blocks = [
        "10.0.0.0/26"
      ]
  }
  // MongoDB
  ingress {
    from_port = 27017
    to_port = 27017
    protocol = "tcp"
    cidr_blocks = [
      "10.0.0.0/26"
    ]
  }
  egress {
    from_port = 27017
    to_port = 27017
    protocol = "tcp"
    cidr_blocks = [
      "10.0.0.0/26"
    ]
  }

  egress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    cidr_blocks = [
      "0.0.0.0/0"
    ]
  }
  egress {
      from_port = 4646
      to_port   = 4648
      protocol  = "tcp"
      cidr_blocks = [
        "0.0.0.0/0"
      ]
  }
  egress {
      from_port = 4648
      to_port   = 4648
      protocol  = "udp"
      cidr_blocks = [
        "10.0.0.0/26"
      ]
  }
}

resource "aws_security_group" "allow_nfs" {
  name   = "allow_nfs"
  vpc_id = aws_vpc.default_vpc.id

  ingress {
    from_port = 2049
    to_port   = 2049
    protocol  = "tcp"
    cidr_blocks = [
    "10.0.0.0/26"]
  }

  egress {
    from_port = 2049
    to_port   = 2049
    protocol  = "tcp"
    cidr_blocks = [
    "10.0.0.0/26"]
  }
}

resource "aws_security_group" "allow_rpcbind" {
  name   = "allow_rpcbind"
  vpc_id = aws_vpc.default_vpc.id

  ingress {
    from_port = 111
    to_port   = 111
    protocol  = "tcp"
    cidr_blocks = [
    "10.0.0.0/26"]
  }

  egress {
    from_port = 111
    to_port   = 111
    protocol  = "tcp"
    cidr_blocks = [
    "10.0.0.0/26"]
  }
}

resource "aws_instance" "bastion" {
  ami           = var.server_ami  // TODO: Use bastion ami, not Hashistack ami.
  instance_type = "t2.micro"
  subnet_id = aws_subnet.public.id
  vpc_security_group_ids = [
    aws_security_group.allow_ssh.id,
    aws_default_security_group.default.id,
    aws_security_group.consul_agents.id,
    aws_security_group.nomad_agents.id
  ]
  key_name                    = "default"

  tags = {
    Name = "Bastion"
  }
}

resource "aws_instance" "servers" {
  count                       = var.instance_count
  ami                         = var.server_ami
  instance_type               = var.instance_type
  key_name                    = "default"
  subnet_id                   = aws_subnet.private.id

  tags = {
    Name = "Hashicorp Server Node ${count.index}"
  }
}

resource "aws_instance" "clients" {
  count                       = var.instance_count
  ami                         = var.server_ami
  instance_type               = var.instance_type
  key_name                    = "default"
  subnet_id                   = aws_subnet.private.id

  tags = {
    Name = "Hashicorp Client Node ${count.index}"
  }
}



output "ec2_server_ip" {
  value = {
    for instance in aws_instance.servers :
    instance.id => "${instance.private_ip}"
  }
}

output "ec2_client_ip" {
  value = {
    for instance in aws_instance.clients :
    instance.id => "${instance.private_ip}"
  }
}

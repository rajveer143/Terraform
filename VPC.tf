# Configuration for the AWS Provider
provider "aws" {
  region     = var.aws_region
  access_key = var.access_key
  secret_key = var.secret_key
}

# Main VPC
resource "aws_vpc" "prod-vpc" {
  cidr_block           = var.VPC_CIDR_BLOCK
  enable_dns_hostnames = "true"
  enable_dns_support   = "true"
  tags = {
    Name = "${var.PROJECT_NAME}-vpc"
  }
}

# Public subnet
resource "aws_subnet" "public" {
  vpc_id            = aws_vpc.prod-vpc.id
  cidr_block        = var.VPC_PUBLIC_SUBNET_CIDR_BLOCK
  availability_zone = var.aws_availability_zone
  tags = {
    Name = "${var.PROJECT_NAME}-vpc-public-subnet"
  }
}

# Private subnet
resource "aws_subnet" "private" {
  vpc_id            = aws_vpc.prod-vpc.id
  cidr_block        = var.VPC_PRIVATE_SUBNET_CIDR_BLOCK
  availability_zone = var.aws_availability_zone
  tags = {
    Name = "${var.PROJECT_NAME}-vpc-private-subnet"
  }
}

# Internet Gateway for internet Traffic
resource "aws_internet_gateway" "igw" {
  vpc_id      = aws_vpc.prod-vpc.id

  tags = {
    Name = "${var.PROJECT_NAME}-vpc-Internet-gateway"
  }

}

# Elastic IP for NAT Gateway
resource "aws_eip" "nat_eip" {
  vpc         = true
  depends_on  = [aws_internet_gateway.igw]
}

# NAT Gateway for Private IP address
resource "aws_nat_gateway" "ngw" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public.id
  depends_on    = [aws_internet_gateway.igw]

  tags = {
    Name = "${var.PROJECT_NAME}-vpc-NAT-gateway"
  }
}

# Route table for public subnet

resource "aws_route_table" "public" {
  vpc_id      = aws_vpc.prod-vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  route {
    ipv6_cidr_block = "::/0"
    gateway_id      = aws_internet_gateway.igw.id

  }

  tags = {
    Name = "${var.PROJECT_NAME}-public-route-table"
  }
}

# Route table for private subnet
resource "aws_route_table" "private" {
  vpc_id      = aws_vpc.prod-vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.ngw.id
  }
  tags = {
    Name = "${var.PROJECT_NAME}-private-route-table"
  }
}

#Route table association with Public Subnet
resource "aws_route_table_association" "to_public_subnet" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

#Route table association with Private Subnet
resource "aws_route_table_association" "to_private_subnet" {
  subnet_id      = aws_subnet.private.id
  route_table_id = aws_route_table.private.id
}

#Security group for Public Instance
resource "aws_security_group" "allow_web" {
  name        = "Allow_web_traffic"
  vpc_id      = aws_vpc.prod-vpc.id

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow_web"
  }
}

# Network interface with an IP in the public subnet 
resource "aws_network_interface" "web-server-nic" {
  subnet_id       = aws_subnet.public.id
  private_ips     = ["10.0.1.50"]
  security_groups = [aws_security_group.allow_web.id]
}

# Elastic IP to the network interface
resource "aws_eip" "one" {
  vpc                       = true
  network_interface         = aws_network_interface.web-server-nic.id
  associate_with_private_ip = "10.0.1.50"
  depends_on                = [aws_internet_gateway.igw]
}

# Ubuntu server with apache2
resource "aws_instance" "prod-web-server" {
  ami               = var.ami_webserver
  instance_type     = var.type_webserver
  availability_zone = var.aws_availability_zone
  key_name          = "main-key"
  network_interface {
    device_index         = 0
    network_interface_id = aws_network_interface.web-server-nic.id
  }
  user_data = <<-EOF
               #!/bin/bash
               sudo apt -get update
               sudo apt install apache2 -y
               sudo systemctl start apache2
               sudo chown -R $USER:$USER /var/www/html
               sudo echo  "<html><body><h1>Hello from Webserver at instance id `curl http://169.254.169.254/latest/meta-data/` </h1></body></html>" > /var/www/html/index.html
               EOF
  tags = {
    Name = "${var.PROJECT_NAME}-webserver-instance"
  }
}









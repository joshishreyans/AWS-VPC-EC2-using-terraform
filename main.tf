terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
}

#Specify the provider, region and access keys
provider "aws" {
  region     = "ap-south-1"
  access_key = "YOUR_ACCESS_KEY_ID"
  secret_key = "YOUR_SECRET_KEY"
}

#Creating a VPC
resource "aws_vpc" "tf-project-1" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "tf-project-1"
  }
}

#Creating an Internet gateway and attaching it to the VPC
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.tf-project-1.id
  tags = {
    Name = "tf-project-1"
  }
}
#Setting up a route table that routes all traffic through the internet gateway
resource "aws_route_table" "tf-project-1-rt" {
  vpc_id = aws_vpc.tf-project-1.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  route {
    ipv6_cidr_block = "::/0"
    gateway_id      = aws_internet_gateway.gw.id
  }

  tags = {
    Name = "tf-project-1"
  }
}

#Creating a subnet inside the VPC
resource "aws_subnet" "tf-project-1-default-subnet" {
  vpc_id            = aws_vpc.tf-project-1.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "ap-south-1a"
  tags = {
    Name = "tf-project-1"
  }
}

#Associating the route table with the subnet
resource "aws_route_table_association" "rta-1" {
  subnet_id      = aws_subnet.tf-project-1-default-subnet.id
  route_table_id = aws_route_table.tf-project-1-rt.id
}

#Creating a security group to allow HTTP, HTTTPS and SSH traffic
resource "aws_security_group" "allow_web_traffic" {
  name        = "allow_web_traffic"
  description = "Allow web traffic"
  vpc_id      = aws_vpc.tf-project-1.id

  ingress {
    description      = "HTTPS"
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
  ingress {
    description      = "HTTP"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
  ingress {
    description      = "SSH"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "tf-project-1"
  }
}

#Creating a network interface to provide the private IP
resource "aws_network_interface" "tf-project-1-nic" {
  subnet_id       = aws_subnet.tf-project-1-default-subnet.id
  private_ips     = ["10.0.1.50"]
  security_groups = [aws_security_group.allow_web_traffic.id]
}

#Creating a elastic IP and attaching it to the above private IP address
resource "aws_eip" "one" {
  domain                    = "vpc"
  network_interface         = aws_network_interface.tf-project-1-nic.id
  associate_with_private_ip = "10.0.1.50"
  depends_on                = [aws_internet_gateway.gw]
}

#Creating an EC2 instance inside the VPC, attaching the network interface to the instance and adding user data that runs on startup
resource "aws_instance" "tf-project-1-webserver" {

  ami               = "ami-0f5ee92e2d63afc18"
  instance_type     = "t2.micro"
  availability_zone = "ap-south-1a"
  key_name          = "NAME_OF_YOUR_EC2_INSTANCE_KEY"
  network_interface {
    device_index         = 0
    network_interface_id = aws_network_interface.tf-project-1-nic.id
  }

  user_data = <<-EOF
              #!/bin/bash
              sudo apt update -y
              sudo apt install apache2 -y
              sudo systemctl start apache2
              sudo bash -c "echo your very first web server >> /var/www/html/index.html"
              EOF
  tags = {
    Name = "tf-project-1"
  }
}

#Getting the Public IP and Private IP of the instance as output
output "public-ip-webserver" {
  value = aws_eip.one.public_ip
}
output "private-ip-webserver" {
  value = aws_instance.tf-project-1-webserver.private_ip
}

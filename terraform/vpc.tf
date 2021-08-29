/*
This terraform file creates a basic VPC with 2 subnets that are attached to the internet gateway and NAT.

This assumes that you have an aws config named alula with the appopriate keys for your aws account.

*/

provider "aws" {
  profile = "alula"
  region  = "us-east-1"
}

resource "aws_vpc" "main" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"
  enable_dns_support = true
  enable_dns_hostnames = true

  tags = {
    Name = "main-vpc"
  }
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "main"
  }
  depends_on = [
    aws_vpc.main
  ]
}

resource "aws_subnet" "public" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.1.0/24"
  map_public_ip_on_launch = false
  availability_zone = "us-east-1a"
  tags = {
    Name = "Main-public"
  }
  depends_on = [
    aws_vpc.main
  ]
}

resource "aws_subnet" "public2" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.2.0/24"
  map_public_ip_on_launch = false
  availability_zone = "us-east-1e"
  tags = {
    Name = "Main-public-1e"
  }
  depends_on = [
    aws_vpc.main
  ]
}

resource "aws_default_route_table" "public" {
  default_route_table_id = aws_vpc.main.main_route_table_id

  tags = {
    Name = "main-public"
  }
  depends_on = [
    aws_vpc.main
  ]
}

resource "aws_route" "public_internet_gateway" {
  route_table_id         = aws_default_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.gw.id

  timeouts {
    create = "5m"
  }
  depends_on = [
    aws_default_route_table.public
  ]
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_default_route_table.public.id
  depends_on = [
    aws_subnet.public
  ]
}

resource "aws_route_table_association" "public2" {
  subnet_id      = aws_subnet.public2.id
  route_table_id = aws_default_route_table.public.id
  depends_on = [
    aws_subnet.public2
  ]
}

resource "aws_eip" "nat_eip" {
  vpc      = true
  depends_on = [
    aws_vpc.main
  ]
}

resource "aws_nat_gateway" "nat1" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public.id

  tags = {
    Name = "gw NAT"
  }

  # To ensure proper ordering, it is recommended to add an explicit dependency
  # on the Internet Gateway for the VPC.
  depends_on = [aws_internet_gateway.gw]
}

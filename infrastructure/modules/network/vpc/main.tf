# VPC Configuration
resource "aws_vpc" "lks_vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "${var.project_name}-vpc"
    Project = var.project_name
    Owner = "lks-team"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "lks_igw" {
  vpc_id = aws_vpc.lks_vpc.id

  tags = {
    Name = "${var.project_name}-igw"
    Project = var.project_name
    Owner = "lks-team"
  }
}

# Public Subnet
resource "aws_subnet" "public_subnet_1" {
  vpc_id                  = aws_vpc.lks_vpc.id
  cidr_block              = var.public_subnet_1_cidr
  availability_zone       = var.availability_zone_1
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.project_name}-public-subnet-1"
    Project = var.project_name
    Owner = "lks-team"
    "kubernetes.io/role/elb" = "1"
  }
}

resource "aws_subnet" "public_subnet_2" {
  vpc_id                  = aws_vpc.lks_vpc.id
  cidr_block              = var.public_subnet_2_cidr
  availability_zone       = var.availability_zone_2
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.project_name}-public-subnet-2"
    Project = var.project_name
    Owner = "lks-team"
    "kubernetes.io/role/elb" = "1"
  }
}

# Private Subnet 1
resource "aws_subnet" "private_subnet_1" {
  vpc_id            = aws_vpc.lks_vpc.id
  cidr_block        = var.private_subnet_1_cidr
  availability_zone = var.availability_zone_1

  tags = {
    Name = "${var.project_name}-private-subnet-1"
    Project = var.project_name
    Owner = "lks-team"
  }
}

# Private Subnet 2
resource "aws_subnet" "private_subnet_2" {
  vpc_id            = aws_vpc.lks_vpc.id
  cidr_block        = var.private_subnet_2_cidr
  availability_zone = var.availability_zone_2

  tags = {
    Name = "${var.project_name}-private-subnet-2"
    Project = var.project_name
    Owner = "lks-team"
  }
}

# Route Table for Public Subnet
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.lks_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.lks_igw.id
  }

  tags = {
    Name = "${var.project_name}-public-rt"
    Project = var.project_name
    Owner = "lks-team"
  }
}

# Route Table Association for Public Subnet
resource "aws_route_table_association" "public_rta" {
  subnet_id      = aws_subnet.public_subnet_1.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "public_rta_2" {
  subnet_id      = aws_subnet.public_subnet_2.id
  route_table_id = aws_route_table.public_rt.id
}

# Note: Private route table associations will be handled by the bastion module
# to enable NAT gateway functionality through the bastion host 
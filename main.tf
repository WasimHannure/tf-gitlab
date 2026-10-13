# --------------------------------------------------
# 1. VPC
# --------------------------------------------------

resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "demo-vpc"
  }
}

# --------------------------------------------------
# 2. PUBLIC AND PRIVATE SUBNETS
# --------------------------------------------------

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true

  tags = {
    Name = "public-subnet"
  }
}

resource "aws_subnet" "private" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.2.0/24"
  map_public_ip_on_launch = false

  tags = {
    Name = "private-subnet"
  }
}

# --------------------------------------------------
# 3. INTERNET GATEWAY
# --------------------------------------------------

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "demo-igw"
  }
}

# --------------------------------------------------
# 4. PUBLIC ROUTE TABLE
# --------------------------------------------------

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "public-rt"
  }
}

resource "aws_route" "public_internet" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# --------------------------------------------------
# 5. ELASTIC IP FOR NAT GATEWAY
# --------------------------------------------------

resource "aws_eip" "nat" {
  domain = "vpc"

  depends_on = [
    aws_internet_gateway.igw
  ]

  tags = {
    Name = "nat-eip"
  }
}

# --------------------------------------------------
# 6. NAT GATEWAY IN PUBLIC SUBNET
# --------------------------------------------------

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public.id

  depends_on = [
    aws_route_table_association.public,
    aws_route.public_internet
  ]

  tags = {
    Name = "demo-nat"
  }
}

# --------------------------------------------------
# 7. PRIVATE ROUTE TABLE
# --------------------------------------------------

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "private-rt"
  }
}

resource "aws_route" "private_nat" {
  route_table_id         = aws_route_table.private.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat.id
}

resource "aws_route_table_association" "private" {
  subnet_id      = aws_subnet.private.id
  route_table_id = aws_route_table.private.id
}

# --------------------------------------------------
# 8. SECURITY GROUP FOR PUBLIC EC2
# --------------------------------------------------

resource "aws_security_group" "public_ec2" {
  name        = "public-ec2-sg"
  description = "Allow SSH from administrator IP"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "SSH from administrator IP"
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
    Name = "public-ec2-sg"
  }
}

# --------------------------------------------------
# 9. SECURITY GROUP FOR PRIVATE EC2
# --------------------------------------------------

resource "aws_security_group" "private_ec2" {
  name        = "private-ec2-sg"
  description = "Allow SSH from public EC2"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "SSH from public EC2"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.public_ec2.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "private-ec2-sg"
  }
}

# --------------------------------------------------
# 10. PUBLIC UBUNTU EC2
# --------------------------------------------------

resource "aws_instance" "public_ec2" {
  ami                         = "ami-0b6d9d3d33ba97d99"
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.public.id
  vpc_security_group_ids      = [aws_security_group.public_ec2.id]
  associate_public_ip_address = true
  key_name                    = var.key_name

  tags = {
    Name = "public-ec2"
  }
}

# --------------------------------------------------
# 11. PRIVATE UBUNTU EC2
# --------------------------------------------------

resource "aws_instance" "private_ec2" {
  ami                         = "ami-0b6d9d3d33ba97d99"
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.private.id
  vpc_security_group_ids      = [aws_security_group.private_ec2.id]
  associate_public_ip_address = false
  key_name                    = var.key_name

  tags = {
    Name = "private-ec2"
  }
}

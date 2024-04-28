terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.46.0"
    }
  }
}

provider aws {
  region = var.region
  alias = "primary"
}

resource "aws_vpc" vpc_block {
  provider = aws.primary
  cidr_block       = var.vpc_cidr_block
  instance_tenancy = "default"

  tags = {
    cluster = "primary"
    Name    = var.vpc_name
    project = "Udacity"
  }
}

resource "aws_internet_gateway" "igw" {
  provider = aws.primary
  vpc_id = aws_vpc.vpc_block.id

  tags = {
    cluster = "primary"
    Name    = "primary-udacity-igw"
    project = "Udacity"
  }
}

resource "aws_subnet" "public_subnet_a" {
  provider = aws.primary
  vpc_id            = aws_vpc.vpc_block.id
  cidr_block        = var.public_subnet_cidr_a
  availability_zone = var.availability_zones[0]

  tags = {
    Name    = "Public Subnet a"
    project = "Udacity"
  }
}

resource "aws_subnet" "private_subnet_a" {
  provider = aws.primary
  vpc_id            = aws_vpc.vpc_block.id
  cidr_block        = var.private_subnet_cidr_a
  availability_zone = var.availability_zones[0]

  tags = {
    Name    = "Private Subnet a"
    project = "Udacity"
  }
}

resource "aws_subnet" "public_subnet_b" {
  provider = aws.primary
  vpc_id            = aws_vpc.vpc_block.id
  cidr_block        = var.public_subnet_cidr_b
  availability_zone = var.availability_zones[1]

  tags = {
    Name    = "Public Subnet b"
    project = "Udacity"
  }
}
resource "aws_subnet" "private_subnet_b" {
  provider = aws.primary
  vpc_id            = aws_vpc.vpc_block.id
  cidr_block        = var.private_subnet_cidr_b
  availability_zone = var.availability_zones[1]

  tags = {
    Name    = "Private Subnet b"
    project = "Udacity"
  }
}

resource "aws_route_table" "public_route_table" {
  provider = aws.primary
  vpc_id = aws_vpc.vpc_block.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name    = "Public Route Table"
    project = "Udacity"
  }
}

resource "aws_route_table_association" "public_subnet_a" {
  provider = aws.primary
  subnet_id      = aws_subnet.public_subnet_a.id
  route_table_id = aws_route_table.public_route_table.id
}

resource "aws_route_table_association" "public_subnet_b" {
  provider = aws.primary
  subnet_id      = aws_subnet.public_subnet_b.id
  route_table_id = aws_route_table.public_route_table.id
}

# ____ database security group
resource "aws_security_group" "database_security_group" {
  name        = "UDARR-Database"
  description = "Udacity ARR Project - Database Security Group"
  vpc_id      = aws_vpc.vpc_block.id

  tags = {
    Name = "UDARR-Database"
    project = "Udacity"
  }
}

resource "aws_security_group_rule" "database_security_group_egress" {
  type              = "egress"
  from_port         = 3306
  to_port           = 3306
  protocol          = "tcp"
  source_security_group_id = aws_security_group.application_security_group.id
  security_group_id = aws_security_group.database_security_group.id
}

resource "aws_security_group_rule" "database_security_group_ingress" {
  type              = "ingress"
  from_port         = 3306
  to_port           = 3306
  protocol          = "tcp"
  source_security_group_id = aws_security_group.application_security_group.id
  security_group_id = aws_security_group.database_security_group.id
}

resource "aws_security_group" "application_security_group" {
  name        = "UDARR-Application"
  description = "Udacity ARR Project - Application Security Group"
  vpc_id      = aws_vpc.vpc_block.id

  ingress {
    description = "SSH from the Internet"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    security_groups = [aws_security_group.database_security_group.id]
  }

  egress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    security_groups = [aws_security_group.database_security_group.id]
  }

  tags = {
    Name = "UDARR-Application"
     project = "Udacity"
  }
}

# ----rds instance
resource "aws_db_subnet_group" "rds_database_subnet_group" {
  name       = "udacity-rds-subnet-group"
  subnet_ids = [aws_subnet.private_subnet_a.id, aws_subnet.private_subnet_b.id]

  tags = {
    project = "Udacity"
    Name = "Main udacity database subnet group"
  }
}

resource "aws_db_instance" "udacity_rds_instance" {
  allocated_storage    = 10
  max_allocated_storage = 100
  port                  = 3306
  storage_type         = "gp2"
  db_name              = "udacity"
  engine               = "mysql"
  engine_version       = "8.0"
  instance_class       = "db.t3.micro"
  username             = "udacity"
  password             = "f00ba$baz1"
  skip_final_snapshot  = true
  parameter_group_name = "default.mysql8.0"
  vpc_security_group_ids = [aws_security_group.database_security_group.id]
  db_subnet_group_name = aws_db_subnet_group.rds_database_subnet_group.name
  multi_az = true
  backup_retention_period = 7
  deletion_protection = false
  apply_immediately = true
  enabled_cloudwatch_logs_exports = ["audit", "error", "general", "slowquery"]

  tags = {
    Name = "udacity-rds-instance"
    project = "Udacity"
  }
}

# Requester's side of the connection.
resource "aws_vpc_peering_connection" "vpc_peering_connection" {
  provider      = aws.primary
  vpc_id        = aws_vpc.vpc_block.id
  peer_vpc_id   = aws_vpc.secondary_vpc_block.id
  auto_accept   = false
  peer_region = var.secondary_region

  tags = {
    Side = "Requester"
    project = "Udacity"
  }
}

# Accepter's side of the connection.
resource "aws_vpc_peering_connection_accepter" "vpc_peering_connection" {
  provider                  = aws.secondary
  vpc_peering_connection_id = aws_vpc_peering_connection.vpc_peering_connection.id
  auto_accept               = true

  tags = {
    Side = "Accepter"
    project = "Udacity"
  }
}

# Ec2 instance
data "aws_ami" "amazon-linux-2" {
 most_recent = true
 filter {
   name   = "owner-alias"
   values = ["amazon"]
 }
  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
#   ami-0663b059c6536cac8
}

resource "aws_instance" "connectDB_ec2_instance" {
  ami           = data.aws_ami.amazon-linux-2.id
  instance_type = "t3.micro"
  key_name      = aws_key_pair.key_pair.key_name
  associate_public_ip_address = true

  subnet_id = aws_subnet.public_subnet_a.id
  security_groups = [aws_security_group.application_security_group.id]

  user_data = <<-EOF
              #!/bin/bash
              echo "DB_HOST=${aws_db_instance.udacity_rds_instance.endpoint}" >> /etc/environment
              echo "DB_PORT=3306" >> /etc/environment
              echo "DB_USER=udacity" >> /etc/environment
              echo "DB_PASS=f00ba$baz1" >> /etc/environment
              sudo su root
              apt update -y
              apt install golang -y
              apt install mysql-client-core-8.0 -y
              apt install awscli -y
              EOF

  tags = {
    Name = "Udacity - ec2 instance"
    project = "Udacity"
  }
}

resource "aws_key_pair" "key_pair" {
  key_name   = "ec2_key_pair"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCuJEAxdVx2axdkctk7MDELDFeRl/ZynCaEIQCQptpmsiXqY4xnk4LYc0TEDWr5XtA47efPvQva4rwVHceOO/pzSmgBbbP9KIeAXqNKD8Axb+Jbz/1tc0RPumnvwQD+V0FHRSD/CzDUcXuI5vosMQ/77JoMW+9hjqUiFI3yribX/nlo4UgNhs9JzpFBmG8jTWnX/18DbOHkeSiFwy3R5/Ixvld7SpapMStGj13GaYHEFOuJNN9x9tJ8aL0ZgVFJWHuAIwzfGQMhqIVZbHT/4lgzUf2Oa9N2wMq1RhCykl7F+81Xc9689ld02WEkIjUV/tB6Kf+3a5hVlRFtbBDAI6Z9 for gitlab"
}

output "instance_ip" {
  description = "The public ip for ssh access"
  value       = aws_instance.connectDB_ec2_instance.public_ip
}





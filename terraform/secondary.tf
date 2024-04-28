provider "aws" {
  region = var.secondary_region
  alias = "secondary"
}

resource "aws_vpc" "secondary_vpc_block" {
  provider = aws.secondary
  cidr_block       = var.secondary_vpc_cidr_block
  instance_tenancy = "default"

  tags = {
    cluster = "secondary"
    Name    = var.secondary_vpc_name
    project = "Udacity"
  }
}

resource "aws_internet_gateway" "secondary_igw" {
  provider = aws.secondary
  vpc_id = aws_vpc.secondary_vpc_block.id

  tags = {
    cluster = "secondary"
    Name    = "secondary-udacity-igw"
    project = "Udacity"
  }
}

resource "aws_subnet" "secondary_public_subnet_a" {
  provider = aws.secondary
  vpc_id            = aws_vpc.secondary_vpc_block.id
  cidr_block        = var.secondary_public_subnet_cidr_a
  availability_zone = var.secondary_availability_zones[0]

  tags = {
    cluster = "secondary"
    Name    = "Public Subnet a"
    project = "Udacity"
  }
}

resource "aws_subnet" "secondary_private_subnet_a" {
  provider = aws.secondary
  vpc_id            = aws_vpc.secondary_vpc_block.id
  cidr_block        = var.secondary_private_subnet_cidr_a
  availability_zone = var.secondary_availability_zones[0]

  tags = {
    cluster = "secondary"
    Name    = "Private Subnet a"
    project = "Udacity"
  }
}

resource "aws_subnet" "secondary_public_subnet_b" {
  provider = aws.secondary
  vpc_id            = aws_vpc.secondary_vpc_block.id
  cidr_block        = var.secondary_public_subnet_cidr_b
  availability_zone = var.secondary_availability_zones[1]

  tags = {
    cluster = "secondary"
    Name    = "Public Subnet b"
    project = "Udacity"
  }
}
resource "aws_subnet" "secondary_private_subnet_b" {
  provider = aws.secondary
  vpc_id            = aws_vpc.secondary_vpc_block.id
  cidr_block        = var.secondary_private_subnet_cidr_b
  availability_zone = var.secondary_availability_zones[1]

  tags = {
    cluster = "secondary"
    Name    = "Private Subnet b"
    project = "Udacity"
  }
}

resource "aws_route_table" "secondary_public_route_table" {
  vpc_id = aws_vpc.secondary_vpc_block.id
  provider = aws.secondary

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.secondary_igw.id
  }

  tags = {
    Name    = "Public Route Table - secondary"
    project = "Udacity"
  }
}

resource "aws_route_table_association" "secondary_public_subnet_a" {
  provider = aws.secondary
  subnet_id      = aws_subnet.secondary_public_subnet_a.id
  route_table_id = aws_route_table.secondary_public_route_table.id
}

resource "aws_route_table_association" "secondary_public_subnet_b" {
  provider = aws.secondary
  subnet_id      = aws_subnet.secondary_public_subnet_b.id
  route_table_id = aws_route_table.secondary_public_route_table.id
}

# ----rds instance
resource "aws_db_subnet_group" "rds_replica_database_subnet_group" {
  provider = aws.secondary
  name       = "udacity-rds-replica-subnet-group"
  subnet_ids = [aws_subnet.secondary_private_subnet_a.id, aws_subnet.secondary_private_subnet_b.id]

  tags = {
    project = "Udacity"
    Name = "Secondary udacity database subnet group"
  }
}

resource "aws_security_group" "application_security_group_secondary" {
  provider = aws.secondary
  name        = "UDARR-Application-secondary"
  description = "Udacity ARR Project - Application Security Group- secondary"
  vpc_id      = aws_vpc.secondary_vpc_block.id

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
    security_groups = [aws_security_group.database_security_group_secondary.id]
  }

  egress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    security_groups = [aws_security_group.database_security_group_secondary.id]
  }

  tags = {
    Name = "UDARR-Application - secondary"
    project = "Udacity"
    secondary = "true"
  }
}

resource "aws_security_group" "database_security_group_secondary" {
  provider = aws.secondary
  name        = "UDARR-Database-secondary"
  description = "Udacity ARR Project - Database Security Group - secondary"
  vpc_id      = aws_vpc.secondary_vpc_block.id

  tags = {
    Name = "UDARR-Database - secondary"
    project = "Udacity"
    secondary = "true"
  }
}

resource "aws_security_group_rule" "secondary_database_security_group_egress" {
  provider = aws.secondary
  type              = "egress"
  from_port         = 3306
  to_port           = 3306
  protocol          = "tcp"
  source_security_group_id = aws_security_group.application_security_group_secondary.id
  security_group_id = aws_security_group.database_security_group_secondary.id
}

resource "aws_security_group_rule" "secondary_database_security_group_ingress" {
  provider = aws.secondary
  type              = "ingress"
  from_port         = 3306
  to_port           = 3306
  protocol          = "tcp"
  source_security_group_id = aws_security_group.application_security_group_secondary.id
  security_group_id = aws_security_group.database_security_group_secondary.id
}

resource "aws_db_instance" "udacity_rds_replica" {
  provider = aws.secondary
  replicate_source_db = aws_db_instance.udacity_rds_instance.arn
  identifier_prefix = "udacity-rds-replica"
  instance_class = aws_db_instance.udacity_rds_instance.instance_class
  publicly_accessible = false
  db_subnet_group_name = aws_db_subnet_group.rds_replica_database_subnet_group.name
  vpc_security_group_ids = [aws_security_group.database_security_group_secondary.id]
  deletion_protection = false
  skip_final_snapshot = true
  backup_retention_period = 7
  apply_immediately = true
  enabled_cloudwatch_logs_exports = ["audit", "error", "general", "slowquery"]
  tags = {
    Name = "udacity-rds-replica"
    project = "Udacity"
  }
}

# Ec2 instance
data "aws_ami" "amazon-linux-2_secondary" {
  provider = aws.secondary
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

# resource "aws_key_pair" "key_pair_secondary" {
#   key_name   = "ec2_key_pair_secondary"
#   public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCuJEAxdVx2axdkctk7MDELDFeRl/ZynCaEIQCQptpmsiXqY4xnk4LYc0TEDWr5XtA47efPvQva4rwVHceOO/pzSmgBbbP9KIeAXqNKD8Axb+Jbz/1tc0RPumnvwQD+V0FHRSD/CzDUcXuI5vosMQ/77JoMW+9hjqUiFI3yribX/nlo4UgNhs9JzpFBmG8jTWnX/18DbOHkeSiFwy3R5/Ixvld7SpapMStGj13GaYHEFOuJNN9x9tJ8aL0ZgVFJWHuAIwzfGQMhqIVZbHT/4lgzUf2Oa9N2wMq1RhCykl7F+81Xc9689ld02WEkIjUV/tB6Kf+3a5hVlRFtbBDAI6Z9 for gitlab"
# }

resource "aws_instance" "connectDB_ec2_instance_secondary" {
  provider = aws.secondary
  ami           = data.aws_ami.amazon-linux-2_secondary.id
  instance_type = "t3.micro"
  associate_public_ip_address = true

  subnet_id = aws_subnet.secondary_public_subnet_a.id
  security_groups = [aws_security_group.application_security_group_secondary.id]

  user_data = <<-EOF
              #!/bin/bash
              echo "DB_HOST=${aws_db_instance.udacity_rds_replica.endpoint}" >> /etc/environment
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
    Name = "Udacity - ec2 instance - secondary"
    project = "Udacity"
    secondary = "true"
  }
}



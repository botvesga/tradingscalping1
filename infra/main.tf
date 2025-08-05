terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.50"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# 1) Traemos la VPC por defecto
data "aws_vpc" "default" {
  default = true
}

# 2) Traemos el Security Group "default" explícitamente
data "aws_security_group" "default_sg" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
  filter {
    name   = "group-name"
    values = ["default"]
  }

  # Necesitamos el nombre del SG:
  # Terraform >=0.13 lo infiere, si falla indica:
  #   vpc_id = data.aws_vpc.default.id
}

# 3) Traemos el DB Subnet Group existente
data "aws_db_subnet_group" "existing" {
  name = "scalping-db-subnet-group"
}

# 4) Creamos el ECS Cluster
resource "aws_ecs_cluster" "scalping" {
  name = "scalping-cluster"
}

# 5) Creamos la RDS (TimescaleDB)
resource "aws_db_instance" "timescaledb" {
  identifier           = "scalping-db"
  engine               = "postgres"
  instance_class       = "db.t3.medium"
  allocated_storage    = 20
  name                 = "scalping"
  username             = var.db_username
  password             = var.db_password
  publicly_accessible  = false

  # <-- aquí apuntamos al SG default que acabamos de capturar
  vpc_security_group_ids = [
    data.aws_security_group.default_sg.id
  ]

  db_subnet_group_name = data.aws_db_subnet_group.existing.name
  skip_final_snapshot  = true
}

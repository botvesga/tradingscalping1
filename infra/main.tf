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

# 1) Cargamos la VPC por defecto
data "aws_vpc" "default" {
  default = true
}

# 2) Cargamos su Default Security Group
data "aws_default_security_group" "default" {
  vpc_id = data.aws_vpc.default.id
}

# 3) Cargamos el DB Subnet Group existente
data "aws_db_subnet_group" "existing" {
  name = "scalping-db-subnet-group"
}

# 4) ECS Cluster
resource "aws_ecs_cluster" "scalping" {
  name = "scalping-cluster"
}

# 5) RDS (TimescaleDB)
resource "aws_db_instance" "timescaledb" {
  identifier             = "scalping-db"
  engine                 = "postgres"
  instance_class         = "db.t3.medium"
  allocated_storage      = 20
  name                   = "scalping"
  username               = var.db_username
  password               = var.db_password
  publicly_accessible    = false

  # <<<--- Aquí YA usamos `.id` en lugar de `.default_security_group_id`
  vpc_security_group_ids = [
    data.aws_default_security_group.default.id
  ]

  db_subnet_group_name = data.aws_db_subnet_group.existing.name
  skip_final_snapshot  = true
}

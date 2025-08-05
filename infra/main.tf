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

# 1) VPC por defecto
data "aws_vpc" "default" {
  default = true
}

# 2) DB Subnet Group ya creado
data "aws_db_subnet_group" "existing" {
  name = "scalping-db-subnet-group"
}

# 3) ECS Cluster
resource "aws_ecs_cluster" "scalping" {
  name = "scalping-cluster"
}

# 4) RDS TimescaleDB
resource "aws_db_instance" "timescaledb" {
  identifier           = "scalping-db"
  engine               = "postgres"
  instance_class       = "db.t3.medium"
  allocated_storage    = 20
  name                 = "scalping"
  username             = var.db_username
  password             = var.db_password
  publicly_accessible  = false

  # <-- aquí usamos el default SG de la VPC
  vpc_security_group_ids = [
    data.aws_vpc.default.default_security_group_id
  ]

  db_subnet_group_name = data.aws_db_subnet_group.existing.name
  skip_final_snapshot  = true
}

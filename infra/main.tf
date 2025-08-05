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

module "vpc" {
  source             = "terraform-aws-modules/vpc/aws"
  version            = "3.14.2"
  name               = "scalping-vpc"
  cidr               = "10.0.0.0/16"
  azs                = ["${var.aws_region}a", "${var.aws_region}b"]
  public_subnets     = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnets    = ["10.0.101.0/24", "10.0.102.0/24"]
  enable_nat_gateway = false
}

resource "aws_ecs_cluster" "scalping" {
  name = "scalping-cluster"
}

# En lugar de resource "aws_db_subnet_group", traemos el ya creado:
data "aws_db_subnet_group" "existing" {
  name = "scalping-db-subnet-group"
}

resource "aws_db_instance" "timescaledb" {
  identifier             = "scalping-db"
  engine                 = "postgres"
  engine_version         = "14.10"
  instance_class         = "db.t3.medium"
  allocated_storage      = 20
  name                   = "scalping"
  username               = var.db_username
  password               = var.db_password
  publicly_accessible    = false
  vpc_security_group_ids = [module.vpc.default_security_group_id]
  # Referenciamos el existing data source:
  db_subnet_group_name   = data.aws_db_subnet_group.existing.name
  skip_final_snapshot    = true
}

# Secrets Manager NO lo volvemos a crear para no chocar con el existente
# (asumimos que ya está creado en AWS)

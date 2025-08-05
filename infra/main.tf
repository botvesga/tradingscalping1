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

# VPC básica
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "3.14.2"
  name    = "scalping-vpc"
  cidr    = "10.0.0.0/16"
  azs             = ["${var.aws_region}a","${var.aws_region}b"]
  public_subnets  = ["10.0.1.0/24","10.0.2.0/24"]
  enable_nat_gateway = false
}

# Cluster ECS
-  db_subnet_group_name = module.vpc.default_db_subnet_group
+  db_subnet_group_name = module.vpc.database_subnet_group_name

# RDS PostgreSQL (TimescaleDB)
resource "aws_db_instance" "timescaledb" {
  identifier          = "scalping-db"
  engine              = "postgres"
  engine_version      = "14.9"
  instance_class      = "db.t3.medium"
  allocated_storage   = 20
  name                = "scalping"
  username            = var.db_username
  password            = var.db_password
  publicly_accessible = false
  vpc_security_group_ids = [module.vpc.default_security_group_id]
  db_subnet_group_name = module.vpc.database_subnet_group_name
}

# Secret Manager para clave de Polygon
resource "aws_secretsmanager_secret" "polygon" {
  name = "polygon-api-key"
}

resource "aws_secretsmanager_secret_version" "polygon_version" {
  secret_id     = aws_secretsmanager_secret.polygon.id
  secret_string = var.polygon_api_key
}

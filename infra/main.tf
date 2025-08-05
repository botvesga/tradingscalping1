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

resource "aws_db_subnet_group" "scalping" {
  name       = "scalping-db-subnet-group"
  subnet_ids = module.vpc.private_subnets
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
  db_subnet_group_name   = aws_db_subnet_group.scalping.name
  skip_final_snapshot    = true
}

# ------------------------------------------------
# Secrets Manager: comentado para no recrear
# Ya existe polygon-api-key en tu cuenta de AWS
# ------------------------------------------------
#resource "aws_secretsmanager_secret" "polygon" {
#  name = "polygon-api-key"
#}
#
#resource "aws_secretsmanager_secret_version" "polygon_version" {
#  secret_id     = aws_secretsmanager_secret.polygon.id
#  secret_string = var.polygon_api_key
#}

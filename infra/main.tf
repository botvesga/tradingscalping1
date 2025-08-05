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

# -------------------------------------------------------
# 1) TRAEMOS LA VPC EXISTENTE (ej. la default)
# -------------------------------------------------------
data "aws_vpc" "existing" {
  default = true
}

# -------------------------------------------------------
# 2) TRAEMOS SUS SUBNETS (públicas y privadas)
# -------------------------------------------------------
data "aws_subnets" "all" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.existing.id]
  }
}

# Para el grupo de RDS solo usaremos las privadas:
locals {
  private_subnet_ids = [
    for s in data.aws_subnets.all.ids : s
    if contains(lookup(data.aws_subnets.all, "ids"), s) && 
       contains(lookup(data.aws_subnets.all, "subnet_ids"), s) &&
       # Ajusta este condicional según tu naming o tag para privadas:
       # aquí asumimos que las privadas no tienen "Public" en su nombre
       !(contains(s, "public"))
  ]
}

# -------------------------------------------------------
# 3) CLUSTER ECS
# -------------------------------------------------------
resource "aws_ecs_cluster" "scalping" {
  name = "scalping-cluster"
}

# -------------------------------------------------------
# 4) TRAEMOS EL DB SUBNET GROUP YA EXISTENTE
# -------------------------------------------------------
data "aws_db_subnet_group" "existing" {
  name = "scalping-db-subnet-group"
}

# -------------------------------------------------------
# 5) INSTANCIA RDS
# -------------------------------------------------------
resource "aws_db_instance" "timescaledb" {
  identifier             = "scalping-db"
  engine                 = "postgres"
  instance_class         = "db.t3.medium"
  allocated_storage      = 20
  name                   = "scalping"
  username               = var.db_username
  password               = var.db_password
  publicly_accessible    = false
  vpc_security_group_ids = [data.aws_vpc.existing.default_security_group_id]
  db_subnet_group_name   = data.aws_db_subnet_group.existing.name
  skip_final_snapshot    = true
}


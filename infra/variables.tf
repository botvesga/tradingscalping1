variable "aws_region" {
  description = "Región AWS donde desplegar"
  type        = string
  default     = "us-east-1"
}

variable "db_username" {
  description = "Usuario de la base de datos PostgreSQL"
  type        = string
}

variable "db_password" {
  description = "Password de la base de datos PostgreSQL"
  type        = string
  sensitive   = true
}

variable "polygon_api_key" {
  description = "Clave de API de Polygon (Secrets Manager)"
  type        = string
  sensitive   = true
}

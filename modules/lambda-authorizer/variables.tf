variable "function_name" {
  description = "Nome da função Lambda"
  type        = string
}

variable "project_name" {
  description = "Nome do projeto (usado para permissões do Parameter Store)"
  type        = string
}

variable "environment" {
  description = "Ambiente (dev, prod, etc)"
  type        = string
}

variable "jwt_secret_param_name" {
  description = "Nome do parâmetro no Parameter Store que contém o JWT secret"
  type        = string
}

variable "log_retention_days" {
  description = "Dias de retenção dos logs do CloudWatch"
  type        = number
  default     = 14
}

variable "tags" {
  description = "Tags para aplicar aos recursos"
  type        = map(string)
  default     = {}
}
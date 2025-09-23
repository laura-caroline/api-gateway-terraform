variable "aws_region" {
  description = "Região da AWS onde os recursos serão criados"
  type        = string
}

variable "project_name" {
  description = "Nome do projeto (usado como prefixo para os recursos)"
  type        = string
}

variable "stage_name" {
  description = "Nome do stage do API Gateway"
  type        = string
}

variable "jwt_secret" {
  description = "Secret para validação de tokens JWT (vem do Parameter Store)"
  type        = string
  sensitive   = true
}

variable "microservices" {
  description = "Lista de microserviços para configurar no API Gateway"
  type = list(object({
    name        = string
    base_path   = string
    target_url  = string
    methods     = list(string)
  }))
  default = []
}

variable "tags" {
  description = "Tags para aplicar aos recursos"
  type        = map(string)
  default     = {}
}
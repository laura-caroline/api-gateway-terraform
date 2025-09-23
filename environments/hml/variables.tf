variable "aws_region" {
  description = "Região da AWS onde os recursos serão criados"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Nome do projeto (usado como prefixo para os recursos)"
  type        = string
  default     = "api-gateway-dev"
}

variable "stage_name" {
  description = "Nome do stage do API Gateway"
  type        = string
  default     = "hml"
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
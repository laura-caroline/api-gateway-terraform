terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket  = "api-gateway-terraform-states-074995673012-hml"
    key     = "environments/hml/terraform.tfstate"
    region  = "us-east-1"
    encrypt = true
  }
}

provider "aws" {
  region = var.aws_region
}

# Data sources
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# Buscar JWT_SECRET do Parameter Store
data "aws_ssm_parameter" "jwt_secret" {
  name            = "/otto99.hml/JWT_SECRET"
  with_decryption = true
}

module "api_gateway" {
  source = "../../modules/api-gateway"

  aws_region    = var.aws_region
  project_name  = var.project_name
  stage_name    = var.stage_name
  jwt_secret    = data.aws_ssm_parameter.jwt_secret.value
  microservices = var.microservices

  tags = {
    Environment = "hml"
    Project     = var.project_name
    ManagedBy   = "terraform"
  }
}

# Outputs
output "api_gateway_url" {
  description = "URL do API Gateway"
  value       = module.api_gateway.api_gateway_url
}

output "lambda_authorizer_arn" {
  description = "ARN do Lambda Authorizer"
  value       = module.api_gateway.lambda_authorizer_arn
}

output "api_gateway_id" {
  description = "ID do API Gateway"
  value       = module.api_gateway.api_gateway_id
}
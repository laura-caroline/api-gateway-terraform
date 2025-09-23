output "api_gateway_url" {
  description = "URL do API Gateway"
  value       = "https://${aws_api_gateway_rest_api.api.id}.execute-api.${data.aws_region.current.name}.amazonaws.com/v1"
}

output "lambda_authorizer_arn" {
  description = "ARN do Lambda Authorizer"
  value       = module.lambda_authorizer.function_arn
}

output "api_gateway_id" {
  description = "ID do API Gateway"
  value       = aws_api_gateway_rest_api.api.id
}

output "api_gateway_arn" {
  description = "ARN do API Gateway"
  value       = aws_api_gateway_rest_api.api.arn
}

output "lambda_authorizer_function_name" {
  description = "Nome da função Lambda Authorizer"
  value       = module.lambda_authorizer.function_name
}

output "stage_arn" {
  description = "ARN do stage do API Gateway"
  value       = aws_api_gateway_stage.api_stage.arn
}

# Outputs do Lambda Authorizer Module
output "lambda_authorizer_invoke_arn" {
  description = "ARN de invocação do Lambda Authorizer"
  value       = module.lambda_authorizer.invoke_arn
}

output "lambda_authorizer_role_arn" {
  description = "ARN da role IAM do Lambda Authorizer"
  value       = module.lambda_authorizer.role_arn
}

output "lambda_authorizer_log_group_name" {
  description = "Nome do log group do CloudWatch do Lambda Authorizer"
  value       = module.lambda_authorizer.log_group_name
}
output "function_arn" {
  description = "ARN da função Lambda"
  value       = aws_lambda_function.authorizer.arn
}

output "function_name" {
  description = "Nome da função Lambda"
  value       = aws_lambda_function.authorizer.function_name
}

output "invoke_arn" {
  description = "ARN de invocação da função Lambda"
  value       = aws_lambda_function.authorizer.invoke_arn
}

output "role_arn" {
  description = "ARN da role IAM do Lambda"
  value       = aws_iam_role.lambda_authorizer_role.arn
}

output "log_group_name" {
  description = "Nome do log group do CloudWatch"
  value       = aws_cloudwatch_log_group.lambda_authorizer_logs.name
}
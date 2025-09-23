terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Data sources
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# IAM Role para Lambda Authorizer
resource "aws_iam_role" "lambda_authorizer_role" {
  name = "${var.function_name}-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })

  tags = var.tags
}

# IAM Policy para Lambda Authorizer (incluindo permissão para Parameter Store)
resource "aws_iam_role_policy" "lambda_authorizer_policy" {
  name = "${var.function_name}-policy"
  role = aws_iam_role.lambda_authorizer_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:*"
      },
      {
        Effect = "Allow"
        Action = [
          "ssm:GetParameter",
          "ssm:GetParameters",
          "ssm:GetParametersByPath"
        ]
        Resource = [
          "arn:aws:ssm:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:parameter/common.*/*",
          "arn:aws:ssm:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:parameter/${var.project_name}/*"
        ]
      }
    ]
  })
}

# Lambda Authorizer
resource "aws_lambda_function" "authorizer" {
  filename         = "${path.module}/lambda-authorizer.zip"
  function_name    = var.function_name
  role            = aws_iam_role.lambda_authorizer_role.arn
  handler         = "dist/index.handler"
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
  runtime         = "nodejs18.x"
  timeout         = 30

  environment {
    variables = {
      JWT_SECRET_PARAM_NAME = var.jwt_secret_param_name
      ENVIRONMENT          = var.environment
    }
  }

  depends_on = [
    aws_iam_role_policy.lambda_authorizer_policy,
    aws_cloudwatch_log_group.lambda_authorizer_logs,
  ]

  tags = var.tags
}

# Build do Lambda
resource "null_resource" "build_lambda" {
  triggers = {
    # Rebuild quando qualquer arquivo TypeScript mudar
    src_hash = data.archive_file.source_files.output_sha
  }

  provisioner "local-exec" {
    command = "cd ${path.module} && npm install && npm run build && npm run package"
  }
}

# Zip dos arquivos fonte para trigger
data "archive_file" "source_files" {
  type        = "zip"
  source_dir  = "${path.module}/src"
  output_path = "${path.module}/src.zip"
}

# Zip final do Lambda
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = path.module
  output_path = "${path.module}/lambda-authorizer.zip"
  excludes = [
    "src",
    "*.md",
    "*.zip",
    "node_modules/.bin",
    "*.ts",
    "*.map"
  ]

  depends_on = [null_resource.build_lambda]
}

# CloudWatch Log Group para Lambda Authorizer
resource "aws_cloudwatch_log_group" "lambda_authorizer_logs" {
  name              = "/aws/lambda/${var.function_name}"
  retention_in_days = var.log_retention_days

  tags = var.tags
}
# Recurso específico para cada microserviço
resource "aws_api_gateway_resource" "microservice_resources" {
  for_each = { for ms in var.microservices : ms.base_path => ms }
  
  rest_api_id = aws_api_gateway_rest_api.api.id
  parent_id   = aws_api_gateway_rest_api.api.root_resource_id
  path_part   = each.value.base_path
}

# Sub-recurso proxy para cada microserviço (captura todos os sub-paths)
resource "aws_api_gateway_resource" "microservice_proxy" {
  for_each = { for ms in var.microservices : ms.base_path => ms }
  
  rest_api_id = aws_api_gateway_rest_api.api.id
  parent_id   = aws_api_gateway_resource.microservice_resources[each.key].id
  path_part   = "{proxy+}"
}

# Métodos HTTP para cada microserviço
resource "aws_api_gateway_method" "microservice_methods" {
  for_each = {
    for ms in var.microservices : ms.base_path => {
      microservice = ms
      methods = ms.methods
    }
  }

  rest_api_id   = aws_api_gateway_rest_api.api.id
  resource_id   = aws_api_gateway_resource.microservice_proxy[each.key].id
  http_method   = "ANY"
  authorization = "CUSTOM"
  authorizer_id = aws_api_gateway_authorizer.jwt_authorizer.id

  request_parameters = {
    "method.request.header.Authorization" = true
    "method.request.path.proxy"           = true
  }
}

# Integração HTTP direta para cada microserviço
resource "aws_api_gateway_integration" "microservice_integration" {
  for_each = { for ms in var.microservices : ms.base_path => ms }

  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_resource.microservice_proxy[each.key].id
  http_method = aws_api_gateway_method.microservice_methods[each.key].http_method

  type                    = "HTTP_PROXY"
  integration_http_method = "ANY"
  uri                     = "${each.value.target_url}/{proxy}"
  timeout_milliseconds    = 29000
  
  request_parameters = {
    "integration.request.path.proxy" = "method.request.path.proxy"
  }
}

# Método OPTIONS para CORS (se necessário)
resource "aws_api_gateway_method" "microservice_options" {
  for_each = { for ms in var.microservices : ms.base_path => ms }

  rest_api_id   = aws_api_gateway_rest_api.api.id
  resource_id   = aws_api_gateway_resource.microservice_proxy[each.key].id
  http_method   = "OPTIONS"
  authorization = "NONE"
}

# Integração para OPTIONS (CORS)
resource "aws_api_gateway_integration" "microservice_options_integration" {
  for_each = { for ms in var.microservices : ms.base_path => ms }

  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_resource.microservice_proxy[each.key].id
  http_method = aws_api_gateway_method.microservice_options[each.key].http_method

  type                 = "MOCK"
  timeout_milliseconds = 29000
  
  request_templates = {
    "application/json" = "{\"statusCode\": 200}"
  }
}

# Resposta para OPTIONS (CORS)
resource "aws_api_gateway_method_response" "microservice_options_response" {
  for_each = { for ms in var.microservices : ms.base_path => ms }

  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_resource.microservice_proxy[each.key].id
  http_method = aws_api_gateway_method.microservice_options[each.key].http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true
    "method.response.header.Access-Control-Allow-Methods" = true
    "method.response.header.Access-Control-Allow-Origin"  = true
  }
}

# Integração de resposta para OPTIONS
resource "aws_api_gateway_integration_response" "microservice_options_integration_response" {
  for_each = { for ms in var.microservices : ms.base_path => ms }

  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_resource.microservice_proxy[each.key].id
  http_method = aws_api_gateway_method.microservice_options[each.key].http_method
  status_code = aws_api_gateway_method_response.microservice_options_response[each.key].status_code

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'"
    "method.response.header.Access-Control-Allow-Methods" = "'GET,POST,PUT,DELETE,OPTIONS'"
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
  }
}
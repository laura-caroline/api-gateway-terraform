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
    "method.request.header.Authorization"     = true
    "method.request.header.x-tenant-id"       = false
    "method.request.header.Content-Type"      = false
    "method.request.header.Accept"            = false
    "method.request.header.User-Agent"        = false
    "method.request.path.proxy"               = true
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
    # Path proxy (obrigatório para capturar sub-paths)
    "integration.request.path.proxy" = "method.request.path.proxy"
    
    # Headers originais da requisição (passthrough)
    "integration.request.header.Authorization"   = "method.request.header.Authorization"
    "integration.request.header.x-tenant-id"     = "method.request.header.x-tenant-id"
    "integration.request.header.Content-Type"    = "method.request.header.Content-Type"
    "integration.request.header.Accept"          = "method.request.header.Accept"
    "integration.request.header.User-Agent"      = "method.request.header.User-Agent"
    
    # Headers adicionais do contexto do authorizer
    "integration.request.header.x-user-id"       = "context.authorizer.userId"
    "integration.request.header.x-user-email"    = "context.authorizer.email"
    "integration.request.header.x-tenant-context" = "context.authorizer.tenantId"
  }

  # IMPORTANTE: HTTP_PROXY automaticamente repassa:
  # - Todos os headers não mapeados explicitamente
  # - Body completo (JSON, form-data, XML, texto, binário, etc.)
  # - Query parameters (incluindo arrays e objetos)
  # - Método HTTP (GET, POST, PUT, DELETE, etc.)
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
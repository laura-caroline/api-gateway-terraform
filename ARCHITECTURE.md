# Arquitetura do API Gateway

## Visão Geral

Este projeto implementa um API Gateway usando AWS API Gateway com autenticação JWT via Lambda Authorizer e roteamento direto para microserviços.

## Arquitetura Atual (Otimizada)

```
Cliente → API Gateway → Lambda Authorizer → Microserviço Direto
                ↓ (se token inválido)
            Retorna 401/403
```

### Componentes

1. **API Gateway REST API**
   - Recebe todas as requisições
   - Aplica autenticação via Lambda Authorizer
   - Faz proxy direto para microserviços

2. **Lambda Authorizer**
   - Valida tokens JWT no header `Authorization`
   - Extrai informações do usuário e tenant
   - Retorna política de autorização (Allow/Deny)

3. **Microserviços**
   - Recebem requisições diretamente do API Gateway
   - Não há camada intermediária de roteamento

## Configuração

### Estrutura de URLs

Cada microserviço é acessível via:
```
https://api-gateway-url.com/{base_path}/{sub_path}
```

Exemplo:
- `GET /users/profile` → `https://user-service.com/profile`
- `POST /orders` → `https://order-service.com/`
- `PUT /products/123` → `https://product-service.com/123`

### Configuração de Microserviços

```hcl
microservices = [
  {
    name        = "user-service"
    base_path   = "users"           # Acessível via /users/*
    target_url  = "https://user-service.com"
    methods     = ["GET", "POST", "PUT", "DELETE"]
  },
  {
    name        = "order-service"
    base_path   = "orders"          # Acessível via /orders/*
    target_url  = "https://order-service.com"
    methods     = ["GET", "POST", "PUT", "DELETE"]
  }
]
```

## Fluxo de Autenticação

1. Cliente envia requisição com header `Authorization: Bearer <token>`
2. API Gateway chama Lambda Authorizer
3. Authorizer valida token JWT e extrai informações do usuário
4. Se válido, API Gateway faz proxy direto para o microserviço
5. Resposta do microserviço é retornada ao cliente

## Headers Preservados

O API Gateway preserva automaticamente:
- `Authorization`
- `Content-Type`
- `x-tenant-id`
- `User-Agent`
- Outros headers relevantes

## CORS

CORS está configurado automaticamente para todos os microserviços:
- `Access-Control-Allow-Origin: *`
- `Access-Control-Allow-Methods: GET,POST,PUT,DELETE,OPTIONS`
- `Access-Control-Allow-Headers: Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token`

## Monitoramento

- CloudWatch Logs para Lambda Authorizer
- API Gateway logs (se habilitados)
- Métricas do API Gateway no CloudWatch


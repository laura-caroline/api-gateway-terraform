# Estrutura do Projeto API Gateway Terraform

## Estrutura de Diretórios

```
.
├── environments/                    # Configurações por ambiente
│   ├── dev/                        # Ambiente de desenvolvimento
│   │   ├── main.tf                 # Configuração principal do ambiente dev
│   │   └── variables.tf            # Variáveis específicas do dev
│   └── prod/                       # Ambiente de produção
│       ├── main.tf                 # Configuração principal do ambiente prod
│       └── variables.tf            # Variáveis específicas do prod
├── modules/                        # Módulos Terraform reutilizáveis
│   ├── api-gateway/                # Módulo do API Gateway
│   │   ├── main.tf                 # Recursos principais do API Gateway
│   │   ├── microservices.tf        # Configuração de microserviços
│   │   ├── outputs.tf              # Outputs do módulo
│   │   └── variables.tf            # Variáveis do módulo
│   └── lambda-authorizer/          # Módulo do Lambda Authorizer
│       ├── main.tf                 # Recursos do Lambda com build automático
│       ├── outputs.tf              # Outputs do Lambda
│       ├── variables.tf            # Variáveis do Lambda
│       └── src/                    # Código fonte TypeScript
│           ├── authorizer.ts       # Lógica principal do autorizador
│           ├── index.ts            # Handler principal
│           ├── jwt.service.ts      # Serviço de validação JWT
│           └── types.ts            # Definições de tipos
├── ARCHITECTURE.md                 # Documentação da arquitetura
├── README.md                       # Documentação principal
├── TROUBLESHOOTING.md             # Guia de solução de problemas
└── package.json                   # Dependências do projeto
```

## Principais Melhorias

### 1. Separação por Ambientes
- **environments/dev/**: Configuração para desenvolvimento
- **environments/prod/**: Configuração para produção
- Cada ambiente tem seu próprio state no S3
- Configurações específicas por ambiente

### 2. Estrutura Modular
- **modules/api-gateway/**: Módulo reutilizável do API Gateway
- **modules/lambda-authorizer/**: Módulo reutilizável do Lambda Authorizer
- Facilita reutilização entre ambientes
- Melhor organização e manutenibilidade

### 3. Build Automático do Lambda
- O módulo Lambda compila automaticamente o TypeScript
- Usa `null_resource` para executar npm install e build
- Gera o ZIP automaticamente via `archive_file`
- Não requer build manual antes do Terraform

### 4. Gestão de Secrets
- JWT_SECRET vem do AWS Parameter Store
- Separado por ambiente: `/common.dev/JWT_SECRET` e `/common.prod/JWT_SECRET`
- Não expõe secrets no código

### 5. Backend S3
- States centralizados no S3
- Separados por ambiente
- Bucket: `api-gateway-terraform-states-074995673012`
- Chaves: `environments/{env}/terraform.tfstate`

## Como Usar

### Deploy do Ambiente de Produção
```bash
cd environments/prod
terraform init
terraform plan
terraform apply
```

### Deploy do Ambiente de Desenvolvimento
```bash
cd environments/dev
terraform init
terraform plan
terraform apply
```

### Primeira Configuração
1. Criar parâmetros no AWS Parameter Store:
   - `/common.prod/JWT_SECRET`
   - `/common.dev/JWT_SECRET`

2. Verificar se o bucket S3 existe:
   - `api-gateway-terraform-states-074995673012`

3. Executar terraform init em cada ambiente

## Arquitetura

- **API Gateway**: Endpoint regional com autorização JWT
- **Lambda Authorizer**: Valida tokens JWT usando JWKS ou secret local
- **Parameter Store**: Armazena secrets de forma segura
- **CloudWatch**: Logs centralizados
- **S3**: Armazenamento de states do Terraform

## Vantagens da Nova Estrutura

1. **Escalabilidade**: Fácil adicionar novos ambientes
2. **Reutilização**: Módulos podem ser usados em outros projetos
3. **Segurança**: Secrets no Parameter Store
4. **Automação**: Build automático do Lambda
5. **Organização**: Separação clara de responsabilidades
6. **Manutenibilidade**: Código mais limpo e organizado
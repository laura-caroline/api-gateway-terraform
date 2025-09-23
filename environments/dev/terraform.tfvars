aws_region = "us-east-1"
project_name = "api-gateway-dev"
stage_name = "dev"

# Microserviços - usando httpbin.org para teste em dev
microservices = [
  {
    name        = "leads-service"
    base_path   = "leads"
    target_url  = "https://backend-worker-leads.hml.ottoenterprise.com.br"
    methods     = ["GET", "POST", "PUT", "DELETE"]
  }
]
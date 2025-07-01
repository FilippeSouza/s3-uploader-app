# Bloco de configuração do Terraform e do provedor AWS
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Configura o provedor AWS para a região correta
provider "aws" {
  # Usamos us-east-1 porque o AWS App Runner está disponível lá.
  region = "us-east-1"
}

# 1. Cria a nossa "garagem" PRIVADA para imagens Docker (ECR)
# Nossa pipeline vai enviar a imagem da nossa aplicação para cá.
resource "aws_ecr_repository" "app_repo" {
  name                 = "s3-uploader-app"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}

# 2. Cria a permissão para o App Runner poder, no FUTURO, acessar nossa garagem privada
# Embora a criação inicial use uma imagem pública, esta permissão será
# essencial para que a pipeline consiga fazer o deploy da nossa imagem privada.
resource "aws_iam_role" "apprunner_ecr_role" {
  name = "AppRunnerECRAccessRole-s3-uploader"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action    = "sts:AssumeRole",
      Effect    = "Allow",
      Principal = {
        Service = "build.apprunner.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "apprunner_ecr_policy_attachment" {
  role       = aws_iam_role.apprunner_ecr_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSAppRunnerServicePolicyForECRAccess"
}

# 3. Cria o serviço App Runner usando uma IMAGEM PÚBLICA DE EXEMPLO
resource "aws_apprunner_service" "app_service" {
  service_name = "s3-uploader-service"

  # AQUI ESTÁ A MUDANÇA PRINCIPAL: Usamos uma imagem pública para a criação inicial
  source_configuration {
    # Não precisamos de autenticação para uma imagem pública
    image_repository {
      image_identifier      = "public.ecr.aws/aws-containers/hello-app-runner:latest"
      image_repository_type = "ECR_PUBLIC" # O tipo muda para ECR PÚBLICO
    }
    auto_deployments_enabled = false
  }

  instance_configuration {
    cpu    = "1024" # 1 vCPU
    memory = "2048" # 2 GB RAM
  }

  network_configuration {
    ingress_configuration {
      is_publicly_accessible = true
    }
  }

  tags = {
    ManagedBy = "Terraform"
    Project   = "s3-uploader"
  }
}

# Bloco de saídas para exportar informações importantes
output "ecr_repository_url" {
  description = "A URL do repositório ECR criado."
  value       = aws_ecr_repository.app_repo.repository_url
}

output "app_runner_service_arn" {
  description = "O ARN do serviço App Runner criado."
  value       = aws_apprunner_service.app_service.arn
}
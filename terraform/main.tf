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
  # IMPORTANTE: Usamos us-east-1 porque o AWS App Runner está disponível lá.
  region = "us-east-1"
}

# 1. Cria a nossa "garagem" para imagens Docker (ECR)
resource "aws_ecr_repository" "app_repo" {
  name                 = "s3-uploader-app"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}

# 2. Cria a permissão para o App Runner poder acessar a garagem (ECR)
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

# 3. Cria o serviço App Runner que vai executar nossa aplicação
resource "aws_apprunner_service" "app_service" {
  service_name = "s3-uploader-service"

  source_configuration {
    authentication_configuration {
      access_role_arn = aws_iam_role.apprunner_ecr_role.arn
    }
    image_repository {
      image_identifier      = "${aws_ecr_repository.app_repo.repository_url}:latest"
      image_repository_type = "ECR"
    }
    auto_deployments_enabled = true
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

# Bloco de saídas para exportar informações importantes da nossa infraestrutura
output "ecr_repository_url" {
  description = "A URL do repositório ECR criado."
  value       = aws_ecr_repository.app_repo.repository_url
}

output "app_runner_service_arn" {
  description = "O ARN do serviço App Runner criado."
  value       = aws_apprunner_service.app_service.arn
}
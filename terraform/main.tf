# Declaração das variáveis sensíveis
variable "app_aws_access_key_id" {
  description = "A chave de acesso para a aplicação rodar"
  type        = string
  sensitive   = true
}
variable "app_aws_secret_access_key" {
  description = "A chave secreta para a aplicação rodar"
  type        = string
  sensitive   = true
}

# Configuração do Provedor
provider "aws" {
  region = "us-east-1"
}

# 1. Cria o repositório ECR
resource "aws_ecr_repository" "app_repo" {
  name         = "s3-uploader-app"
  force_delete = true
}
/*
/*# 2. Cria a permissão para o App Runner acessar o ECR
resource "aws_iam_role" "apprunner_ecr_role" {
  name = "AppRunnerECRAccessRole-s3-uploader"
  assume_role_policy = jsonencode({
    Version   = "2012-10-17",
    Statement = [{
      Action    = "sts:AssumeRole",
      Effect    = "Allow",
      Principal = { Service = "build.apprunner.amazonaws.com" }
    }]
  })
}
resource "aws_iam_role_policy_attachment" "apprunner_ecr_policy_attachment" {
  role       = aws_iam_role.apprunner_ecr_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSAppRunnerServicePolicyForECRAccess"
}

# 3. Cria o serviço App Runner para a NOSSA aplicação
resource "aws_apprunner_service" "app_service" {
  service_name = "s3-uploader-service"

  source_configuration {
    authentication_configuration {
      access_role_arn = aws_iam_role.apprunner_ecr_role.arn
    }
    image_repository {
      image_identifier      = "${aws_ecr_repository.app_repo.repository_url}:latest"
      image_repository_type = "ECR"
      image_configuration {
        runtime_environment_variables = {
          AWS_ACCESS_KEY_ID     = var.app_aws_access_key_id
          AWS_SECRET_ACCESS_KEY = var.app_aws_secret_access_key
          AWS_S3_BUCKET_NAME    = "welcome-ecopower"
          AWS_REGION            = "us-east-1"
        }
      }
    }
    auto_deployments_enabled = true
  }

  instance_configuration {
    cpu    = "1024"
    memory = "2048"
  }
}

# Saídas
output "app_runner_service_arn" {
  value = aws_apprunner_service.app_service.arn
}*/
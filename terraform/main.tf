# --- Fica na pasta /terraform ---

# Variável para o ID da sua conta AWS
variable "aws_account_id" {
  description = "O ID da conta AWS para criar nomes de recursos únicos."
  type        = string
}

# Configuração do Provedor AWS
provider "aws" {
  region = "us-east-1"
}

# 1. Cria o repositório ECR
resource "aws_ecr_repository" "app_repo" {
  name         = "s3-uploader-app"
  force_delete = true
}

# 2. Cria o Bucket S3 para os uploads da APLICAÇÃO
resource "aws_s3_bucket" "application_data_bucket" {
  bucket = "s3-uploader-data-${var.aws_account_id}"
}

# 3. Permissão para o App Runner ACESSAR o ECR
resource "aws_iam_role" "apprunner_ecr_role" {
  name = "AppRunnerECRAccessRole-s3"
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

# 4. Permissão para a APLICAÇÃO ACESSAR o S3
resource "aws_iam_role" "apprunner_instance_role" {
  name = "AppRunnerInstanceRole-s3"
  assume_role_policy = jsonencode({
    Version   = "2012-10-17",
    Statement = [{
      Action    = "sts:AssumeRole",
      Effect    = "Allow",
      Principal = { Service = "tasks.apprunner.amazonaws.com" }
    }]
  })
}
# Anexa a política de acesso total ao S3 gerenciada pela AWS para eliminar erros
resource "aws_iam_role_policy_attachment" "s3_full_access_attachment" {
  role       = aws_iam_role.apprunner_instance_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}

# 5. O Serviço App Runner
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
        port = "3000" # Informa ao App Runner qual porta nossa aplicação usa
        runtime_environment_variables = {
          AWS_S3_BUCKET_NAME = aws_s3_bucket.application_data_bucket.bucket
          AWS_REGION         = "us-east-1"
        }
      }
    }
    auto_deployments_enabled = true
  }

  instance_configuration {
    cpu               = "1024"
    memory            = "2048"
    instance_role_arn = aws_iam_role.apprunner_instance_role.arn # Associa a permissão de S3 ao serviço
  }
}

# Saídas
output "app_runner_service_arn" {
  value = aws_apprunner_service.app_service.arn
}
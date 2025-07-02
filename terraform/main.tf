provider "aws" {
  region = "us-east-1"
}

# 1. Cria o repositório ECR
resource "aws_ecr_repository" "app_repo" {
  name         = "s3-uploader-app"
  force_delete = true
}

# 2. Permissão para o App Runner ACESSAR o ECR
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

# 3. Permissão para a APLICAÇÃO ACESSAR o S3
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
resource "aws_iam_role_policy" "s3_access_policy" {
  name = "AppRunnerS3AccessPolicy"
  role = aws_iam_role.apprunner_instance_role.id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action   = ["s3:GetObject", "s3:PutObject"],
      Effect   = "Allow",
      Resource = [
        "arn:aws:s3:::welcome-ecopower",
        "arn:aws:s3:::welcome-ecopower/*",
      ]
    }]
  })
}

# 4. O Serviço App Runner
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
    cpu               = "1024"
    memory            = "2048"
    instance_role_arn = aws_iam_role.apprunner_instance_role.arn # Associa a permissão de S3 ao serviço
  }
}

# Saídas
output "app_runner_service_arn" {
  value = aws_apprunner_service.app_service.arn
}
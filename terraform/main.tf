variable "aws_account_id" {
  description = "O ID da conta AWS para nomes de recursos únicos."
  type        = string
}

provider "aws" {
  region = "us-east-1"
}

# Recursos de Armazenamento
resource "aws_ecr_repository" "app_repo" {
  name         = "s3-uploader-app"
  force_delete = true
}

resource "aws_s3_bucket" "application_data_bucket" {
  bucket = "s3-uploader-data-${var.aws_account_id}"
}

resource "aws_s3_bucket_ownership_controls" "ownership_controls" {
  bucket = aws_s3_bucket.application_data_bucket.id
  rule {
    object_ownership = "ObjectWriter"
  }
}

resource "aws_s3_bucket_public_access_block" "public_access_block" {
  bucket                  = aws_s3_bucket.application_data_bucket.id
  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_acl" "bucket_acl" {
  depends_on = [
    aws_s3_bucket_ownership_controls.ownership_controls,
    aws_s3_bucket_public_access_block.public_access_block
  ]
  bucket = aws_s3_bucket.application_data_bucket.id
  acl    = "private"
}

# Permissões do IAM
resource "aws_iam_role" "apprunner_ecr_role" {
  name               = "AppRunnerECRAccessRole-s3-uploader"
  assume_role_policy = jsonencode({
    Version   = "2012-10-17",
    Statement = [{ Action = "sts:AssumeRole", Effect = "Allow", Principal = { Service = "build.apprunner.amazonaws.com" } }]
  })
}
resource "aws_iam_role_policy_attachment" "apprunner_ecr_policy_attachment" {
  role       = aws_iam_role.apprunner_ecr_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSAppRunnerServicePolicyForECRAccess"
}

resource "aws_iam_role" "apprunner_instance_role" {
  name               = "AppRunnerInstanceRole-s3-uploader"
  assume_role_policy = jsonencode({
    Version   = "2012-10-17",
    Statement = [{ Action = "sts:AssumeRole", Effect = "Allow", Principal = { Service = "tasks.apprunner.amazonaws.com" } }]
  })
}
resource "aws_iam_role_policy_attachment" "s3_full_access_attachment" {
  role       = aws_iam_role.apprunner_instance_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}

# Serviço App Runner
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
        port = "3000"
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
    instance_role_arn = aws_iam_role.apprunner_instance_role.arn
  }
}

# Saídas
output "app_runner_service_arn" {
  description = "O ARN do serviço App Runner criado."
  value       = aws_apprunner_service.app_service.arn
}

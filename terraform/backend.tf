# --- Arquivo: backend.tf ---
# Descreve os recursos necessários para o backend remoto.

# 1. Bucket S3 para guardar o estado do Terraform
resource "aws_s3_bucket" "terraform_state" {
  bucket = "tfstate-s3-uploader-504759923868"
}

# 2. Ativa o versionamento no bucket de estado
resource "aws_s3_bucket_versioning" "terraform_state_versioning" {
  bucket = aws_s3_bucket.terraform_state.id
  versioning_configuration {
    status = "Enabled"
  }
}

# 3. Tabela DynamoDB para "trancar" o arquivo de estado
resource "aws_dynamodb_table" "terraform_state_lock" {
  name         = "s3-uploader-tf-lock"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }
}
terraform {
  backend "s3" {
    bucket         = "tfstate-s3-uploader-504759923868"
    key            = "global/s3-uploader/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "s3-uploader-app-tf-lock"
    encrypt        = true
  }
}
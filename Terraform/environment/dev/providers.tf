terraform {
  backend "s3"{
    bucket = "backend-bucket-tf-11"
    dynamodb_table = "state-lock"
    key = "global/mystatefile/terraform.tfstate"
    region = "eu-north-1"
  }
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "6.65.0"
    }
  }
}


provider "aws" {
  region = "eu-north-1"
}
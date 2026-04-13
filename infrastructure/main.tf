terraform {
  required_version = ">= 1.7.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  cloud {
    organization = "platform-engineering-demos"  # Change to your TFC org name later
    workspaces {
      name = "cnc-logging-dev"
    }
  }
}

provider "aws" {
  region = var.aws_region
  default_tags {
    tags = {
      ManagedBy   = "PlatformTeam"
      Environment = var.environment
      Project     = "CloudNative-Commerce"
    }
  }
}

data "aws_caller_identity" "current" {}

variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "environment" {
  type    = string
  default = "dev"
}

variable "bucket_prefix" {
  type    = string
  default = "cnc-logs"
}

variable "owner_email" {
  type = string
}

resource "aws_s3_bucket" "logs" {
  bucket = "${var.bucket_prefix}-${data.aws_caller_identity.current.account_id}-${var.environment}"
  
  tags = {
    Owner = var.owner_email
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "logs_sse" {
  bucket = aws_s3_bucket.logs.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_versioning" "logs_versioning" {
  bucket = aws_s3_bucket.logs.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_public_access_block" "logs_public_block" {
  bucket                  = aws_s3_bucket.logs.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

output "bucket_arn" {
  value = aws_s3_bucket.logs.arn
}

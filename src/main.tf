terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  required_version = ">= 1.2.0  "
}

provider "aws" {
  region = "eu-north-1"
}

# Register new application
resource "aws_servicecatalogappregistry_application" "cloud_project" {
  name        = "Cloud_Project"
  description = "Commmercial Servicis project"
}

# Create application VPC
module "vpc" {
  source     = "aws-ia/vpc/aws"
  version    = "~> 4.4"
  name       = "marketing-vpc"
  cidr_block = "10.0.0.0/16"
  az_count   = 2

  subnets = {
    public = {
      netmask = 24
    }
    private = {
      netmask = 24
    }
  }
  tags = aws_servicecatalogappregistry_application.cloud_project.application_tag
}
resource "aws_iam_role" "lambda_exec" {
  name = "serverless_lambda"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Sid    = ""
      Principal = {
        Service = "lambda.amazonaws.com"
      }
      }
    ]
  })
}

#attaches a policy to the IAM role. 
resource "aws_iam_role_policy_attachment" "lambda_policy" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}
resource "aws_iam_role_policy_attachment" "lambda_dynamoroles" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonDynamoDBFullAccess"
}


resource "aws_dynamodb_table" "sales" {
  name         = "SalesTable"
  hash_key     = "SaleID"
  range_key    = "TimeOfSale"
  billing_mode = "PAY_PER_REQUEST"

  attribute {
    name = "SaleID"
    type = "S" 
  }

  attribute {
    name = "TimeOfSale"
    type = "N"
  }

  attribute {
    name = "UserID"
    type = "N"
  }

  tags = merge(aws_servicecatalogappregistry_application.cloud_project.application_tag, {
    Name = "Sales Table"
  })
  global_secondary_index {
    name            = "UserIDIndex"
    hash_key        = "UserID" # The index will be on UserID
    projection_type = "ALL"    # Include all attributes in the index
    read_capacity  = 5
    write_capacity = 5
  }
}

data "archive_file" "SalesCollection" {
  type        = "zip"
  source_file = "SaleCollection.py" # Pointing to Python file in this directory
  output_path = "SalesCollection_payload.zip"
}

resource "aws_lambda_function" "SalesCollection" {
  filename      = "SalesCollection_payload.zip"
  function_name = "SaleCollection"
  role          = aws_iam_role.lambda_exec.arn
  handler       = "SaleCollection.lambda_handler"
  runtime       = "python3.12"

  source_code_hash = data.archive_file.SalesCollection.output_base64sha256


}

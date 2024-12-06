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
  resource "aws_iam_role_policy_attachment" "lambda_vpc_policy" {
    role       = aws_iam_role.lambda_exec.name
    policy_arn = "arn:aws:iam::aws:policy/AmazonVPCFullAccess"
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
    type = "S"
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

resource "aws_dynamodb_table" "UsersTable" {
  name         = "UsersTable"
  hash_key     = "UserID"
  billing_mode = "PAY_PER_REQUEST"

  attribute {
    name = "UserID"
    type = "S"
  }

  tags = merge(aws_servicecatalogappregistry_application.cloud_project.application_tag, {
    Name = "User Table"
  })

}

data "archive_file" "SalesCollection" {
  type        = "zip"
  source_file = "SaleCollection.py" # Pointing to Python file in this directory
  output_path = "SalesCollection_payload.zip"
}
data "archive_file" "post_confirmation" {
  type        = "zip"
  source_file = "PostConfirmationLambda.py" # Pointing to Python file in this directory
  output_path = "post_confirmation.zip"
}
data "archive_file" "PreSignUp" {
  type        = "zip"
  source_file = "PreSignUpLambda.py" # Pointing to Python file in this directory
  output_path = "pre_sign_up.zip"
}

  resource "aws_lambda_function" "SalesCollection" {
    filename      = "SalesCollection_payload.zip"
    function_name = "SaleCollection"
    role          = aws_iam_role.lambda_exec.arn
    handler       = "SaleCollection.lambda_handler"
    runtime       = "python3.12"

    # VPC Configuration for Lambda
    vpc_config {
      subnet_ids = [
      module.vpc.private_subnet_attributes_by_az["private/eu-north-1a"].id,
      module.vpc.private_subnet_attributes_by_az["private/eu-north-1b"].id
    ]
      security_group_ids = [aws_security_group.lambda_sg.id]
    }

    source_code_hash = data.archive_file.SalesCollection.output_base64sha256


  }
  # Create a security group for Lambda if needed
  resource "aws_security_group" "lambda_sg" {
    name        = "lambda_sg"
    description = "Security Group for Lambda function"
    vpc_id      = module.vpc.vpc_attributes.id

    egress {
      from_port   = 0
      to_port     = 0
      protocol    = "-1" # Allow all protocols
      cidr_blocks = ["0.0.0.0/0"] # Allow outbound to any destination
    }
    ingress {
      description      = "Allow all inbound traffic"
      from_port        = 0
      to_port          = 0
      protocol         = "-1" # -1 means all protocols
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = ["::/0"]
    }
  }

  resource "aws_vpc_endpoint" "dynamodb" {
    vpc_id       = module.vpc.vpc_attributes.id
    service_name = "com.amazonaws.eu-north-1.dynamodb" # Adjust for your region
    route_table_ids = [for az, rt in module.vpc.rt_attributes_by_type_by_az["private"] : rt.id]

    tags = {
      Name = "dynamodb-vpc-endpoint"
    }
  }

resource "aws_lambda_function" "pre_sign_up" {
  function_name = "PreSignUpLambda"
  runtime       = "python3.12"
  handler       = "pre_signup.lambda_handler"
  role          = aws_iam_role.lambda_exec.arn
  filename      = "pre_sign_up.zip"  # Path to the Lambda zip file

  source_code_hash = data.archive_file.PreSignUp.output_base64sha256
}
resource "aws_lambda_function" "post_confirmation" {
  function_name = "PostConfirmationLambda"
  runtime       = "python3.12"
  handler       = "post_confirmation.lambda_handler"
  role          = aws_iam_role.lambda_exec.arn
  filename      = "post_confirmation.zip"  # Path to the Lambda zip file

  source_code_hash = data.archive_file.post_confirmation.output_base64sha256
}

  resource "aws_sns_topic" "sales_notifications" {
    name = "SalesNotifications"
  }
  resource "aws_lambda_permission" "notification_sns_publish" {
    statement_id  = "AllowSNSPublish"
    action        = "lambda:InvokeFunction"
    function_name = aws_lambda_function.NotificationLambda.function_name
    principal     = "sns.amazonaws.com"
    source_arn    = aws_sns_topic.sales_notifications.arn
  }
  resource "aws_lambda_permission" "sales_collection_invoke_notification" {
  statement_id  = "AllowSalesCollectionInvokeNotification"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.NotificationLambda.function_name
  principal     = "lambda.amazonaws.com"
  source_arn    = aws_lambda_function.SalesCollection.arn
  }
  resource "aws_lambda_function" "NotificationLambda" {
    filename      = "NotificationLambda_payload.zip"
    function_name = "NotificationLambda"
    role          = aws_iam_role.lambda_exec.arn
    handler       = "NotificationLambda.lambda_handler"
    runtime       = "python3.12"
    environment {
      variables = {
        SNS_TOPIC_ARN = aws_sns_topic.sales_notifications.arn
      }
    }

    vpc_config {
      subnet_ids = [
        module.vpc.private_subnet_attributes_by_az["private/eu-north-1a"].id,
        module.vpc.private_subnet_attributes_by_az["private/eu-north-1b"].id
      ]
      security_group_ids = [aws_security_group.lambda_sg.id]
    }

    source_code_hash = data.archive_file.NotificationLambda.output_base64sha256
  }
  data "archive_file" "NotificationLambda" {
    type        = "zip"
    source_file = "NotificationLambda.py" # Replace with the correct Python filename
    output_path = "NotificationLambda_payload.zip"
  }

  resource "aws_iam_role_policy_attachment" "notification_lambda_sns" {
    role       = aws_iam_role.lambda_exec.name
    policy_arn = "arn:aws:iam::aws:policy/AmazonSNSFullAccess"
  }
  resource "aws_iam_role_policy" "invoke_notification_lambda" {
    name   = "InvokeNotificationLambdaPolicy"
    role   = aws_iam_role.lambda_exec.name
    policy = jsonencode({
      Version = "2012-10-17",
      Statement = [
        {
          Effect   = "Allow",
          Action   = "lambda:InvokeFunction",
          Resource = aws_lambda_function.NotificationLambda.arn
        }
      ]
    })
  }

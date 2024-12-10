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
    read_capacity   = 5
    write_capacity  = 5
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
resource "aws_dynamodb_table" "BusinessTable" {
  name         = "BusinessTable"
  hash_key     = "BusinessName"
  billing_mode = "PAY_PER_REQUEST"

  attribute {
    name = "BusinessName"
    type = "S"
  }

  tags = merge(aws_servicecatalogappregistry_application.cloud_project.application_tag, {
    Name = "Business Table"
  })

}
resource "aws_dynamodb_table" "SessionTable" {
  name         = "SessionTable"
  hash_key     = "SessionID"
  billing_mode = "PAY_PER_REQUEST"

  attribute {
    name = "SessionID"
    type = "S"
  }

  tags = merge(aws_servicecatalogappregistry_application.cloud_project.application_tag, {
    Name = "Session Table"
  })

}
resource "aws_dynamodb_table" "FeedbackTable" {
  name         = "FeedbackTable"
  hash_key     = "SaleID"
  billing_mode = "PAY_PER_REQUEST"

  attribute {
    name = "SaleID"
    type = "S"
  }
  

  tags = merge(aws_servicecatalogappregistry_application.cloud_project.application_tag, {
    Name = "Feedback Table"
  })

}
data "archive_file" "SalesCollection" {
  type        = "zip"
  source_file = "SaleCollection.py" # Pointing to Python file in this directory
  output_path = "SalesCollection_payload.zip"
}
data "archive_file" "Feedback" {
  type        = "zip"
  source_file = "Feedback.py" # Pointing to Python file in this directory
  output_path = "Feedback_payload.zip"
}
data "archive_file" "SignIn" {
  type        = "zip"
  source_file = "SignIn.py" # Pointing to Python file in this directory
  output_path = "SignIn.zip"
}
data "archive_file" "SignUpBusiness" {
  type        = "zip"
  source_file = "SignUpBusiness.py" # Pointing to Python file in this directory
  output_path = "SignUpBusiness.zip"
}
resource "aws_lambda_function" "SignUpBusiness" {
  filename      = "SignUpBusiness.zip"
  function_name = "SignUpBusiness"
  role          = aws_iam_role.lambda_exec.arn
  handler       = "SignUpBusiness.lambda_handler"
  runtime       = "python3.12"

  # VPC Configuration for Lambda
  vpc_config {
    subnet_ids = [
      module.vpc.private_subnet_attributes_by_az["private/eu-north-1a"].id,
      module.vpc.private_subnet_attributes_by_az["private/eu-north-1b"].id
    ]
    security_group_ids = [aws_security_group.lambda_sg.id]
  }

  source_code_hash = data.archive_file.SignUpBusiness.output_base64sha256


}
resource "aws_lambda_function" "SignIn" {
  filename      = "SignIn.zip"
  function_name = "SignIn"
  role          = aws_iam_role.lambda_exec.arn
  handler       = "SignIn.lambda_handler"
  runtime       = "python3.12"

  # VPC Configuration for Lambda
  vpc_config {
    subnet_ids = [
      module.vpc.private_subnet_attributes_by_az["private/eu-north-1a"].id,
      module.vpc.private_subnet_attributes_by_az["private/eu-north-1b"].id
    ]
    security_group_ids = [aws_security_group.lambda_sg.id]
  }

  source_code_hash = data.archive_file.SignIn.output_base64sha256


}
resource "aws_lambda_function" "validateSignIn" {
  filename      = "validateSignIn.zip"
  function_name = "validateSignIn"
  role          = aws_iam_role.lambda_exec.arn
  handler       = "validateSignIn.lambda_handler"
  runtime       = "python3.12"

  # VPC Configuration for Lambda
  vpc_config {
    subnet_ids = [
      module.vpc.private_subnet_attributes_by_az["private/eu-north-1a"].id,
      module.vpc.private_subnet_attributes_by_az["private/eu-north-1b"].id
    ]
    security_group_ids = [aws_security_group.lambda_sg.id]
  }

  source_code_hash = data.archive_file.validateSignIn.output_base64sha256


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
resource "aws_lambda_function" "Feedback" {
  filename      = "Feedback_payload.zip"
  function_name = "Feedback"
  role          = aws_iam_role.lambda_exec.arn
  handler       = "Feedback.lambda_handler"
  runtime       = "python3.12"

  # VPC Configuration for Lambda
  vpc_config {
    subnet_ids = [
      module.vpc.private_subnet_attributes_by_az["private/eu-north-1a"].id,
      module.vpc.private_subnet_attributes_by_az["private/eu-north-1b"].id
    ]
    security_group_ids = [aws_security_group.lambda_sg.id]
  }

  source_code_hash = data.archive_file.Feedback.output_base64sha256


}
# Create a security group for Lambda if needed
resource "aws_security_group" "lambda_sg" {
  name        = "lambda_sg"
  description = "Security Group for Lambda function"
  vpc_id      = module.vpc.vpc_attributes.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"          # Allow all protocols
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
  vpc_id          = module.vpc.vpc_attributes.id
  service_name    = "com.amazonaws.eu-north-1.dynamodb" # Adjust for your region
  route_table_ids = [for az, rt in module.vpc.rt_attributes_by_type_by_az["private"] : rt.id]

  tags = {
    Name = "dynamodb-vpc-endpoint"
  }
}

resource "aws_sns_topic" "sales_notifications" {
  name = "SalesNotifications"
}
resource "aws_lambda_permission" "notification_sns_publish" {
  statement_id  = "AllowSNSPublish"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.SalesCollection.function_name
  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.sales_notifications.arn
}
# resource "aws_lambda_permission" "sales_collection_invoke_notification" {
#   statement_id  = "AllowSalesCollectionInvokeNotification"
#   action        = "lambda:InvokeFunction"
#   function_name = aws_lambda_function.NotificationLambda.function_name
#   principal     = "lambda.amazonaws.com"
#   source_arn    = aws_lambda_function.SalesCollection.arn
# }
# resource "aws_lambda_function" "NotificationLambda" {
#   filename      = "NotificationLambda_payload.zip"
#   function_name = "NotificationLambda"
#   role          = aws_iam_role.lambda_exec.arn
#   handler       = "NotificationLambda.lambda_handler"
#   runtime       = "python3.12"
#   environment {
#     variables = {
#       SNS_TOPIC_ARN = aws_sns_topic.sales_notifications.arn
#     }
#   }

#   vpc_config {
#     subnet_ids = [
#       module.vpc.private_subnet_attributes_by_az["private/eu-north-1a"].id,
#       module.vpc.private_subnet_attributes_by_az["private/eu-north-1b"].id
#     ]
#     security_group_ids = [aws_security_group.lambda_sg.id]
#   }

#   source_code_hash = data.archive_file.NotificationLambda.output_base64sha256
# }
resource "aws_lambda_function" "SignUp" {
  filename      = "SignUp.zip"
  function_name = "SignUpLambda"
  role          = aws_iam_role.lambda_exec.arn
  handler       = "SignUp.lambda_handler"
  runtime       = "python3.12"
  vpc_config {
    subnet_ids = [
      module.vpc.private_subnet_attributes_by_az["private/eu-north-1a"].id,
      module.vpc.private_subnet_attributes_by_az["private/eu-north-1b"].id
    ]
    security_group_ids = [aws_security_group.lambda_sg.id]
  }

  source_code_hash = data.archive_file.SignUp.output_base64sha256
}
# data "archive_file" "NotificationLambda" {
#   type        = "zip"
#   source_file = "NotificationLambda.py" # Replace with the correct Python filename
#   output_path = "NotificationLambda_payload.zip"
# }
data "archive_file" "validateSignIn" {
  type        = "zip"
  source_file = "validateSignIn.py" # Replace with the correct Python filename
  output_path = "validateSignIn.zip"
}
data "archive_file" "SignUp" {
  type        = "zip"
  source_file = "SignUp.py" # Replace with the correct Python filename
  output_path = "SignUp.zip"
}
resource "aws_iam_role_policy_attachment" "notification_lambda_sns" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSNSFullAccess"
}
resource "aws_iam_role_policy" "lambda_publish_sns" {
  name = "LambdaPublishToSNSPolicy"
  role = aws_iam_role.lambda_exec.name

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = "sns:Publish",
        Resource = aws_sns_topic.sales_notifications.arn
      }
    ]
  })
}
resource "aws_sns_topic_policy" "sns_policy" {
  arn = aws_sns_topic.sales_notifications.arn

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect    = "Allow",
        Principal = { Service = "lambda.amazonaws.com" },
        Action    = "sns:Publish",
        Resource  = aws_sns_topic.sales_notifications.arn,
        Condition = {
          ArnEquals = {
            "aws:SourceArn" = aws_lambda_function.SalesCollection.arn
          }
        }
      }
    ]
  })
}
# resource "aws_iam_role_policy" "invoke_notification_lambda" {
#   name = "InvokeNotificationLambdaPolicy"
#   role = aws_iam_role.lambda_exec.name
#   policy = jsonencode({
#     Version = "2012-10-17",
#     Statement = [
#       {
#         Effect   = "Allow",
#         Action   = "lambda:InvokeFunction",
#         Resource = aws_lambda_function.NotificationLambda.arn
#       }
#     ]
#   })
# }

resource "aws_lambda_permission" "allow_business_signup" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.SignUpBusiness.function_name
  principal     = "apigateway.amazonaws.com"
}
resource "aws_lambda_permission" "allow_feedback" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.Feedback.function_name
  principal     = "apigateway.amazonaws.com"
}
resource "aws_lambda_permission" "allow_user_signup" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.SignUp.function_name
  principal     = "apigateway.amazonaws.com"
}
resource "aws_vpc_endpoint" "sns_gateway" {
  vpc_id            = module.vpc.vpc_attributes.id
  service_name      = "com.amazonaws.eu-north-1.sns"
  vpc_endpoint_type = "Interface" # Interface endpoint for API Gateway

  # Extracting only the subnet IDs from the private subnet attributes
  subnet_ids = [for key, value in module.vpc.private_subnet_attributes_by_az : value["id"]]

  security_group_ids = [aws_security_group.lambda_sg.id]
  private_dns_enabled = true
  tags = {
    Name = "API SNS VPC Endpoint"
  }
}

resource "aws_vpc_endpoint" "api_gateway" {
  vpc_id            = module.vpc.vpc_attributes.id
  service_name      = "com.amazonaws.eu-north-1.execute-api"
  vpc_endpoint_type = "Interface" # Interface endpoint for API Gateway

  # Extracting only the subnet IDs from the private subnet attributes
  subnet_ids = [for key, value in module.vpc.private_subnet_attributes_by_az : value["id"]]

  security_group_ids = [aws_security_group.lambda_sg.id]

  tags = {
    Name = "API Gateway VPC Endpoint"
  }
}

resource "aws_api_gateway_rest_api" "Project_Gateway" {
  name        = "Project-api"
  description = "Project API Gateway"
}

resource "aws_api_gateway_resource" "api_resource" {
  rest_api_id = aws_api_gateway_rest_api.Project_Gateway.id
  parent_id   = aws_api_gateway_rest_api.Project_Gateway.root_resource_id
  path_part   = "project"
}

resource "aws_api_gateway_method" "Business_signUp_method" {
  rest_api_id   = aws_api_gateway_rest_api.Project_Gateway.id
  resource_id   = aws_api_gateway_resource.api_resource.id
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "Busieness_Sign_up_integration" {
  rest_api_id             = aws_api_gateway_rest_api.Project_Gateway.id
  resource_id             = aws_api_gateway_resource.api_resource.id
  http_method             = aws_api_gateway_method.Business_signUp_method.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = "arn:aws:apigateway:eu-north-1:lambda:path/2015-03-31/functions/${aws_lambda_function.SignUpBusiness.arn}/invocations" # here give your URI ID 
}
# User Sign up
resource "aws_api_gateway_resource" "sign_up_resource" {
  rest_api_id = aws_api_gateway_rest_api.Project_Gateway.id
  parent_id   = aws_api_gateway_rest_api.Project_Gateway.root_resource_id
  path_part   = "UserSignUp"
}

resource "aws_api_gateway_method" "user_signUp_method" {
  rest_api_id   = aws_api_gateway_rest_api.Project_Gateway.id
  resource_id   = aws_api_gateway_resource.sign_up_resource.id
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "user_Sign_up_integration" {
  rest_api_id             = aws_api_gateway_rest_api.Project_Gateway.id
  resource_id             = aws_api_gateway_resource.sign_up_resource.id
  http_method             = aws_api_gateway_method.user_signUp_method.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = "arn:aws:apigateway:eu-north-1:lambda:path/2015-03-31/functions/${aws_lambda_function.SignUp.arn}/invocations" # here give your URI ID 
}

# Sign in user

resource "aws_api_gateway_resource" "sign_in_resource" {
  rest_api_id = aws_api_gateway_rest_api.Project_Gateway.id
  parent_id   = aws_api_gateway_rest_api.Project_Gateway.root_resource_id
  path_part   = "UserSignIn"
}

resource "aws_api_gateway_method" "user_signin_method" {
  rest_api_id   = aws_api_gateway_rest_api.Project_Gateway.id
  resource_id   = aws_api_gateway_resource.sign_in_resource.id
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "user_Sign_in_integration" {
  rest_api_id             = aws_api_gateway_rest_api.Project_Gateway.id
  resource_id             = aws_api_gateway_resource.sign_in_resource.id
  http_method             = aws_api_gateway_method.user_signin_method.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = "arn:aws:apigateway:eu-north-1:lambda:path/2015-03-31/functions/${aws_lambda_function.SignIn.arn}/invocations" # here give your URI ID 
}

# sales collection

resource "aws_api_gateway_resource" "sale_collection_resource" {
  rest_api_id = aws_api_gateway_rest_api.Project_Gateway.id
  parent_id   = aws_api_gateway_rest_api.Project_Gateway.root_resource_id
  path_part   = "BusinessCollect"
}

resource "aws_api_gateway_method" "sale_collection_method" {
  rest_api_id   = aws_api_gateway_rest_api.Project_Gateway.id
  resource_id   = aws_api_gateway_resource.sale_collection_resource.id
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "sale_collection_integration" {
  rest_api_id             = aws_api_gateway_rest_api.Project_Gateway.id
  resource_id             = aws_api_gateway_resource.sale_collection_resource.id
  http_method             = aws_api_gateway_method.sale_collection_method.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = "arn:aws:apigateway:eu-north-1:lambda:path/2015-03-31/functions/${aws_lambda_function.SalesCollection.arn}/invocations" # here give your URI ID 
}
# validation

resource "aws_api_gateway_resource" "validation_resource" {
  rest_api_id = aws_api_gateway_rest_api.Project_Gateway.id
  parent_id   = aws_api_gateway_rest_api.Project_Gateway.root_resource_id
  path_part   = "UserValidate"
}

resource "aws_api_gateway_method" "validation_method" {
  rest_api_id   = aws_api_gateway_rest_api.Project_Gateway.id
  resource_id   = aws_api_gateway_resource.validation_resource.id
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "validation_integration" {
  rest_api_id             = aws_api_gateway_rest_api.Project_Gateway.id
  resource_id             = aws_api_gateway_resource.validation_resource.id
  http_method             = aws_api_gateway_method.validation_method.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = "arn:aws:apigateway:eu-north-1:lambda:path/2015-03-31/functions/${aws_lambda_function.validateSignIn.arn}/invocations" # here give your URI ID 
}

# Define the API Gateway Deployment
resource "aws_api_gateway_deployment" "api_deployment" {
  depends_on = [aws_api_gateway_integration.Busieness_Sign_up_integration]
  rest_api_id = aws_api_gateway_rest_api.Project_Gateway.id
  description = "Deployment for CloudProject stage"
  
}

# Define the API Gateway Stage (optional, auto-created by deployment above)
resource "aws_api_gateway_stage" "cloud_project_stage" {
  deployment_id = aws_api_gateway_deployment.api_deployment.id
  rest_api_id   = aws_api_gateway_rest_api.Project_Gateway.id
  stage_name    = "CloudProject"
  description   = "API Stage for the CloudProject deployment"
  variables = {
    environment = "production"
  }
}
# Feedback
resource "aws_api_gateway_resource" "feedback_resource" {
  rest_api_id = aws_api_gateway_rest_api.Project_Gateway.id
  parent_id   = aws_api_gateway_rest_api.Project_Gateway.root_resource_id
  path_part   = "Feedback"
}

resource "aws_api_gateway_method" "feedback_method" {
  rest_api_id   = aws_api_gateway_rest_api.Project_Gateway.id
  resource_id   = aws_api_gateway_resource.feedback_resource.id
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "feedback_integration" {
  rest_api_id             = aws_api_gateway_rest_api.Project_Gateway.id
  resource_id             = aws_api_gateway_resource.feedback_resource.id
  http_method             = aws_api_gateway_method.feedback_method.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = "arn:aws:apigateway:eu-north-1:lambda:path/2015-03-31/functions/${aws_lambda_function.Feedback.arn}/invocations" # here give your URI ID 
}

# "arn:aws:apigateway:eu-north-1:lambda:path/2015-03-31/functions/arn:aws:lambda:eu-north-1:221082171326:function:SignUpBusiness/invocations
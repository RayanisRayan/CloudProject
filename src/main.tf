terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  required_version = ">= 1.2.0"
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

# # Create application instance
# resource "aws_instance" "web_server" {
#   instance_type = "t3.micro"
#   ami           = data.aws_ssm_parameter.al_2023.value
#   subnet_id     = module.vpc.private_subnet_attributes_by_az["private/${module.vpc.azs[0]}"].id
#   tags          = aws_servicecatalogappregistry_application.cloud_project.application_tag
# }

# # Create CloudWatch Alarm
# resource "aws_cloudwatch_metric_alarm" "web_server_cpu" {
#   alarm_name          = "marketing-web-server-cpu-high"
#   comparison_operator = "GreaterThanOrEqualToThreshold"
#   evaluation_periods  = 2
#   metric_name         = "CPUUtilization"
#   namespace           = "AWS/EC2"
#   dimensions = {
#     InstanceId = aws_instance.web_server.id
#   }
#   period                    = 120
#   statistic                 = "Average"
#   threshold                 = 80
#   alarm_description         = "This metric monitors EC2 CPU utilization"
#   insufficient_data_actions = []
#   tags                      = aws_servicecatalogappregistry_application.cloud_project.application_tag
# }
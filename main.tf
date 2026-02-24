terraform {
  required_version = ">= 1.10"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket       = "monitoring-tfstate-02fa6331"
    key          = "monitoring/terraform.tfstate"
    region       = "us-west-2"
    use_lockfile = true
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "monitoring-alerting"
      Environment = var.environment
      ManagedBy   = "terraform"
      Owner       = "luis-garcia"
    }
  }
}

# Billing metrics only exist in us-east-1
provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"
}

module "monitoring" {
  source = "./modules/monitoring"

  project                 = "monitoring"
  environment             = var.environment
  alarm_email             = var.alarm_email
  log_retention_days      = var.log_retention_days
  error_alarm_threshold   = var.error_alarm_threshold
  billing_alarm_threshold = var.billing_alarm_threshold
  aws_region              = var.aws_region
}

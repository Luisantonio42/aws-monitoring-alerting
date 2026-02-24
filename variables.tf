variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-west-2"
}

variable "environment" {
  description = "Deployment environment (dev, staging, prod)"
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }
}

variable "alarm_email" {
  description = "Email address to receive alarm notifications"
  type        = string
}

variable "log_retention_days" {
  description = "Number of days to retain CloudWatch logs"
  type        = number
  default     = 30
}

variable "error_alarm_threshold" {
  description = "Number of errors before the alarm fires"
  type        = number
  default     = 5
}

variable "billing_alarm_threshold" {
  description = "Estimated monthly charges in USD to trigger billing alarm"
  type        = number
  default     = 10
}

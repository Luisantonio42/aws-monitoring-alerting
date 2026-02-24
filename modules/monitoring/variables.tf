variable "aws_region" {
  description = "AWS region for dashboard URL construction"
  type        = string
}

variable "project" {
  description = "Project name used for resource naming"
  type        = string
  default     = "monitoring"
}

variable "environment" {
  description = "Deployment environment (dev, staging, prod)"
  type        = string
}

variable "alarm_email" {
  description = "Email address to receive alarm notifications"
  type        = string
}

variable "log_retention_days" {
  description = "Number of days to retain CloudWatch logs"
  type        = number
}

variable "error_alarm_threshold" {
  description = "Number of errors before the alarm fires"
  type        = number
}

variable "billing_alarm_threshold" {
  description = "Estimated monthly charges in USD to trigger billing alarm"
  type        = number
}

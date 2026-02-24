output "sns_topic_arn" {
  description = "ARN of the SNS alarm notification topic"
  value       = module.monitoring.sns_topic_arn
}

output "log_group_name" {
  description = "Name of the centralized CloudWatch log group"
  value       = module.monitoring.log_group_name
}

output "dashboard_url" {
  description = "URL to the CloudWatch dashboard"
  value       = module.monitoring.dashboard_url
}
output "sns_topic_arn" {
  description = "ARN of the SNS alarm notification topic"
  value       = aws_sns_topic.alerts.arn
}

output "log_group_name" {
  description = "Name of the centralized CloudWatch log group"
  value       = aws_cloudwatch_log_group.app.name
}

output "dashboard_url" {
  description = "URL to the CloudWatch dashboard"
  value       = "https://${var.aws_region}.console.aws.amazon.com/cloudwatch/home?region=${var.aws_region}#dashboards:name=${aws_cloudwatch_dashboard.main.dashboard_name}"
}
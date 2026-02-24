resource "aws_sns_topic" "alerts" {
  name = "${var.project}-${var.environment}-alerts"
}

# Only CloudWatch can send alerts
resource "aws_sns_topic_policy" "alerts" {
  arn = aws_sns_topic.alerts.arn

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid    = "AllowCloudWatchPublish"
      Effect = "Allow"
      Principal = {
        Service = "cloudwatch.amazonaws.com"
      }
      Action   = "SNS:Publish"
      Resource = aws_sns_topic.alerts.arn
    }]
  })
}


# Requires manual confirmation click after terraform apply
resource "aws_sns_topic_subscription" "email" {
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = var.alarm_email
}

resource "aws_cloudwatch_log_group" "app" {
  name              = "/${var.project}/${var.environment}/app"
  retention_in_days = var.log_retention_days

  tags = {
    Environment = var.environment
    Service     = "app"
  }
}

resource "aws_cloudwatch_log_metric_filter" "errors" {
  name           = "${var.project}-${var.environment}-errors"
  log_group_name = aws_cloudwatch_log_group.app.name
  pattern        = "ERROR"

  metric_transformation {
    name      = "ErrorCount"
    namespace = "${var.project}/errors"
    value     = "1"
  }
}

resource "aws_cloudwatch_metric_alarm" "error_count" {
  alarm_name          = "${var.project}-${var.environment}-error-count"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 2
  metric_name         = "ErrorCount"
  namespace           = "${var.project}/errors"
  period              = 300
  statistic           = "Sum"
  threshold           = var.error_alarm_threshold

  # 2 periods prevents transient spikes from triggering pages
  alarm_description = "Error rate exceeded threshold"
  alarm_actions     = [aws_sns_topic.alerts.arn]
  ok_actions        = [aws_sns_topic.alerts.arn]

  # Missing data means the filter found nothing — not an error
  treat_missing_data = "notBreaching"
}

resource "aws_cloudwatch_metric_alarm" "billing" {
  alarm_name          = "${var.project}-${var.environment}-billing"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "EstimatedCharges"
  namespace           = "AWS/Billing"
  period              = 86400
  statistic           = "Maximum"
  threshold           = var.billing_alarm_threshold

  # Billing metrics only available in us-east-1
  dimensions = {
    Currency = "USD"
  }

  alarm_actions      = [aws_sns_topic.alerts.arn]
  ok_actions         = [aws_sns_topic.alerts.arn]
  treat_missing_data = "notBreaching"
}

resource "aws_cloudwatch_metric_alarm" "cf_5xx" {
  alarm_name          = "${var.project}-${var.environment}-cf-5xx"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 2
  metric_name         = "5xxErrorRate"
  namespace           = "AWS/CloudFront"
  period              = 300
  statistic           = "Average"
  threshold           = 1

  dimensions = {
    Region = "Global"
  }

  # 5xx means your origin is failing — treat missing as not breaching
  # since CloudFront may have no traffic in dev
  alarm_actions      = [aws_sns_topic.alerts.arn]
  ok_actions         = [aws_sns_topic.alerts.arn]
  treat_missing_data = "notBreaching"
}

resource "aws_cloudwatch_composite_alarm" "critical" {
  alarm_name = "${var.project}-${var.environment}-critical"

  # Only fires when BOTH alarms are in ALARM state simultaneously
  # Reduces noise — a single metric spike won't page you
  alarm_rule = "ALARM(\"${aws_cloudwatch_metric_alarm.error_count.alarm_name}\") AND ALARM(\"${aws_cloudwatch_metric_alarm.cf_5xx.alarm_name}\")"

  alarm_actions = [aws_sns_topic.alerts.arn]
  ok_actions    = [aws_sns_topic.alerts.arn]
}

resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = "${var.project}-${var.environment}"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "alarm"
        x      = 0
        y      = 0
        width  = 6
        height = 3
        properties = {
          title  = "Critical Composite Alarm"
          alarms = [aws_cloudwatch_composite_alarm.critical.arn]
        }
      },
      {
        type   = "metric"
        x      = 6
        y      = 0
        width  = 9
        height = 6
        properties = {
          title   = "Application Error Count"
          region  = var.aws_region
          period  = 300
          stat    = "Sum"
          metrics = [
            ["${var.project}/errors", "ErrorCount"]
          ]
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 3
        width  = 6
        height = 6
        properties = {
          title   = "CloudFront 5xx Error Rate"
          region  = "us-east-1"
          period  = 300
          stat    = "Average"
          metrics = [
            ["AWS/CloudFront", "5xxErrorRate", "Region", "Global"]
          ]
        }
      },
      {
        type   = "metric"
        x      = 6
        y      = 6
        width  = 9
        height = 6
        properties = {
          title   = "Estimated AWS Charges (USD)"
          region  = "us-east-1"
          period  = 86400
          stat    = "Maximum"
          metrics = [
            ["AWS/Billing", "EstimatedCharges", "Currency", "USD"]
          ]
        }
      }
    ]
  })
}

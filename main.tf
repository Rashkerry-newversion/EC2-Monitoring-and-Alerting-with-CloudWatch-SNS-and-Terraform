provider "aws" {
  region = "us-east-1"
}

# ========== Variables ==========

variable "key_name" {
  default = "monitoring" # Your EC2 key pair name
}

variable "security_group" {
  default = "security-group-ID" # Actual SG ID (not name)
}

variable "email_address" {
  default = "your-email"
}

# ========== main.tf ==========

resource "aws_instance" "monitored_ec2" {
  ami                    = "Your-preferred-AMI" # Amazon Linux 2 (us-east-1)
  instance_type          = "t2.micro"
  key_name               = var.key_name
  vpc_security_group_ids = [var.security_group]     # ✅ FIXED: changed from security_groups

  tags = {
    Name = "MonitoredEC2"
  }
}

# ========== SNS Topic ==========

resource "aws_sns_topic" "cpu_alert_topic" {
  name = "ec2-high-cpu-alerts"
}

# ========== SNS Email Subscription ==========

resource "aws_sns_topic_subscription" "email_alert" {
  topic_arn = aws_sns_topic.cpu_alert_topic.arn
  protocol  = "email"
  endpoint  = var.email_address
}

# ========== CloudWatch Alarm ==========

resource "aws_cloudwatch_metric_alarm" "high_cpu_alarm" {
  alarm_name          = "HighCPUUsage"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 6
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 60
  statistic           = "Average"
  threshold           = 60
  alarm_description   = "Alert when CPU usage exceeds 60% for 6 minutes"
  alarm_actions       = [aws_sns_topic.cpu_alert_topic.arn]

  dimensions = {
    InstanceId = aws_instance.monitored_ec2.id
  }
}

# Generic EC2 Instance Module
# Reusable for all RoboShop services (databases and applications)

resource "aws_instance" "main" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  key_name               = var.key_name
  subnet_id              = var.subnet_id
  vpc_security_group_ids = var.security_group_ids
  
  user_data = var.user_data_script != "" ? var.user_data_script : null
  
  # Enable detailed monitoring (optional but recommended)
  monitoring = var.enable_detailed_monitoring
  
  # Root volume configuration
  root_block_device {
    volume_type           = var.root_volume_type
    volume_size           = var.root_volume_size
    delete_on_termination = true
    encrypted             = var.enable_encryption
    
    tags = merge(
      var.tags,
      {
        Name = "${var.project_name}-${var.environment}-${var.service_name}-root"
      }
    )
  }
  
  # Additional data volume (optional, for databases)
  dynamic "ebs_block_device" {
    for_each = var.data_volume_size > 0 ? [1] : []
    content {
      device_name           = "/dev/sdf"
      volume_type           = var.data_volume_type
      volume_size           = var.data_volume_size
      delete_on_termination = false
      encrypted             = var.enable_encryption
      
      tags = merge(
        var.tags,
        {
          Name = "${var.project_name}-${var.environment}-${var.service_name}-data"
        }
      )
    }
  }
  
  # IAM instance profile for CloudWatch, SSM, etc.
  iam_instance_profile = var.iam_instance_profile
  
  # User data to execute on first boot
  user_data_replace_on_change = var.user_data_replace_on_change
  
  tags = merge(
    var.tags,
    {
      Name        = "${var.project_name}-${var.environment}-${var.service_name}"
      Service     = var.service_name
      Environment = var.environment
      Tier        = var.tier
    }
  )
  
  lifecycle {
    create_before_destroy = false
    ignore_changes        = []
  }
}

# CloudWatch Log Group for instance logs (optional)
resource "aws_cloudwatch_log_group" "instance" {
  count = var.enable_cloudwatch_logs ? 1 : 0
  
  name              = "/aws/ec2/${var.project_name}-${var.environment}-${var.service_name}"
  retention_in_days = var.log_retention_days
  
  tags = merge(
    var.tags,
    {
      Name    = "${var.project_name}-${var.environment}-${var.service_name}-logs"
      Service = var.service_name
    }
  )
}

# CloudWatch Alarms for instance health
resource "aws_cloudwatch_metric_alarm" "instance_health" {
  count = var.enable_health_alarm ? 1 : 0
  
  alarm_name          = "${var.project_name}-${var.environment}-${var.service_name}-health"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "StatusCheckFailed"
  namespace           = "AWS/EC2"
  period              = "60"
  statistic           = "Average"
  threshold           = "0"
  alarm_description   = "This metric monitors instance health"
  alarm_actions       = var.alarm_actions
  
  dimensions = {
    InstanceId = aws_instance.main.id
  }
  
  tags = var.tags
}

# CloudWatch Alarm for CPU utilization
resource "aws_cloudwatch_metric_alarm" "cpu_utilization" {
  count = var.enable_cpu_alarm ? 1 : 0
  
  alarm_name          = "${var.project_name}-${var.environment}-${var.service_name}-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "300"
  statistic           = "Average"
  threshold           = var.cpu_threshold
  alarm_description   = "This metric monitors CPU utilization"
  alarm_actions       = var.alarm_actions
  
  dimensions = {
    InstanceId = aws_instance.main.id
  }
  
  tags = var.tags
}

# Elastic IP (optional, for bastion or public-facing instances)
resource "aws_eip" "main" {
  count = var.allocate_eip ? 1 : 0
  
  instance = aws_instance.main.id
  domain   = "vpc"
  
  tags = merge(
    var.tags,
    {
      Name    = "${var.project_name}-${var.environment}-${var.service_name}-eip"
      Service = var.service_name
    }
  )
}

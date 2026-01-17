# Route53 Private Hosted Zone Module
# Creates internal DNS for service discovery

# Private Hosted Zone
resource "aws_route53_zone" "private" {
  name = var.domain_name
  
  vpc {
    vpc_id = var.vpc_id
  }
  
  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-${var.environment}-private-zone"
      Type = "Private"
    }
  )
}

# A Record for each service
resource "aws_route53_record" "service" {
  for_each = var.service_records
  
  zone_id = aws_route53_zone.private.zone_id
  name    = "${each.key}.${var.domain_name}"
  type    = "A"
  ttl     = var.ttl
  records = [each.value]
}

# CNAME Record (optional, for aliases)
resource "aws_route53_record" "cname" {
  for_each = var.cname_records
  
  zone_id = aws_route53_zone.private.zone_id
  name    = "${each.key}.${var.domain_name}"
  type    = "CNAME"
  ttl     = var.ttl
  records = [each.value]
}

# Health check for critical services (optional)
resource "aws_route53_health_check" "service" {
  for_each = var.health_check_configs
  
  ip_address        = each.value.ip_address
  port              = each.value.port
  type              = each.value.type
  resource_path     = lookup(each.value, "resource_path", "/")
  failure_threshold = lookup(each.value, "failure_threshold", 3)
  request_interval  = lookup(each.value, "request_interval", 30)
  
  tags = merge(
    var.tags,
    {
      Name    = "${var.project_name}-${var.environment}-${each.key}-health"
      Service = each.key
    }
  )
}

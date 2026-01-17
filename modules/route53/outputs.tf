output "zone_id" {
  description = "Hosted zone ID"
  value       = aws_route53_zone.private.zone_id
}

output "zone_name" {
  description = "Hosted zone name"
  value       = aws_route53_zone.private.name
}

output "zone_arn" {
  description = "Hosted zone ARN"
  value       = aws_route53_zone.private.arn
}

output "name_servers" {
  description = "Name servers for the hosted zone"
  value       = aws_route53_zone.private.name_servers
}

output "service_records" {
  description = "Map of service DNS names to IPs"
  value = {
    for k, v in aws_route53_record.service : k => {
      fqdn = v.fqdn
      name = v.name
      ip   = var.service_records[k]
    }
  }
}

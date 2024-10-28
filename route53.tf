
resource "aws_route53_zone" "private_zones" {
  for_each = local.aws_services

  name = "${each.key}.${var.main_region}.amazonaws.com"
  
  vpc {
    vpc_id = module.shared_services_vpc.vpc_id
  }

  tags = {
    Name = "private-zone-${each.key}"
  }
}

resource "aws_route53_record" "interface_endpoint_records" {
  for_each = aws_vpc_endpoint.shared_interface_endpoints

  zone_id = aws_route53_zone.private_zones[each.key].id
  name    = "${each.key}.${var.main_region}.amazonaws.com"
  type    = "A"

  alias {
    name                   = each.value.dns_entry[0].dns_name
    zone_id                = each.value.dns_entry[0].hosted_zone_id
    evaluate_target_health = true
  }
}

# resource "aws_route53_zone_association" "spoke_associations" {
#   for_each = local.aws_services

#   zone_id = aws_route53_zone.private_zones[each.key].id
#   vpc_id  = var.spoke_vpc_id
# }
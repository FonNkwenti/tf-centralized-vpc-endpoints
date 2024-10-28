# # Create Private Hosted Zone in VPC A
# resource "aws_route53_zone" "private_zone" {
#   name          = "saas.internal"
#   vpc {
#     vpc_id = module.service_consumer_main.vpc_id 
#     vpc_region = var.main_region
#   }

#   provider = aws.service_consumer_main

# }

# resource "aws_route53_record" "endpoint_cname" {
#   zone_id = aws_route53_zone.private_zone.zone_id
#   name    = "saas.internal"
#   type    = "CNAME"
#   ttl     = 300
#   records = [aws_vpc_endpoint.privateLink_service.dns_entry[0].dns_name]
# }
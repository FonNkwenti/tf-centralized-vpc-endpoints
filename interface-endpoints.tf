resource "aws_vpc_endpoint" "shared_interface_endpoints" {
  for_each = local.aws_services
  vpc_id   = module.shared_services_vpc.vpc_id
  ip_address_type     = "ipv4"
  vpc_endpoint_type   = "Interface"

  service_name        = each.value.name
  security_group_ids  = [module.interface_endpoints_sg.security_group_id]
  private_dns_enabled = false
  subnet_ids          = module.shared_services_vpc.private_subnets

  tags = {
    Name = "shared-${each.key}-interface-endpoint"
  }
}
# resource "aws_vpc_endpoint" "s3_interface_endpoints" {
#   vpc_id                = module.shared_services_vpc.vpc_id
#   ip_address_type     = "ipv4"
#   vpc_endpoint_type   = "Interface"
#   service_name        = "com.amazonaws.${var.main_region}.s3"
#   security_group_ids  = [module.interface_endpoints_sg.security_group_id]
#   private_dns_enabled = false
#   subnet_ids          = module.shared_services_vpc.private_subnets

#   tags = {
#     Name = "s3-interface-endpoint"
#   }
# }


module "interface_endpoints_sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "5.1.0"

  name        = "interface-endpoints-sg"
  vpc_id      = module.shared_services_vpc.vpc_id
  description = "security group for shared services interface endpoints"

  ingress_with_cidr_blocks = [
    {
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      cidr_blocks = "0.0.0.0/0"
      description = "HTTPS from VPC"
    }
  ]

  egress_with_cidr_blocks = [
    {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = "0.0.0.0/0"
    }
  ]

  tags = {
    Name = "interface-endpoints-sg"
  }

}
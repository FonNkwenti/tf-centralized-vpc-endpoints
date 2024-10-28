

////////////////////////////

module "shared_services_vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = local.name
  cidr = local.shared_services_vpc_cidr

  azs             = local.main_azs
  public_subnets  = [for k, v in local.main_azs : cidrsubnet(local.shared_services_vpc_cidr, 8, k)]
  private_subnets = [for k, v in local.main_azs : cidrsubnet(local.shared_services_vpc_cidr, 8, k + 10)]

  enable_nat_gateway = false
  single_nat_gateway = false

  enable_dns_hostnames = true
  enable_dns_support   = true

  manage_default_security_group = false
  manage_default_network_acl    = false

  tags = merge(local.common_tags, {
    Name = "${local.name}-shared-services"
  })
}

/*

# 
resource "aws_ec2_transit_gateway" "main_tgw" {
  description = "Main region Transit Gateway"

  tags = merge(local.common_tags, {
    Name = "main-region-tgw"
  })

}

resource "aws_route" "transit_vpc_cidr_to_main_tgw" {
  count                  = length(module.shared_services_vpc.private_route_table_ids)
  route_table_id         = element(module.shared_services_vpc.private_route_table_ids, count.index)
  destination_cidr_block = local.transit_vpc_cidr
  transit_gateway_id     = aws_ec2_transit_gateway.main_tgw.id


}

# attach service_provide_main VPC to transit gateway
resource "aws_ec2_transit_gateway_vpc_attachment" "main_tgw_attachment" {
  transit_gateway_id = aws_ec2_transit_gateway.main_tgw.id
  vpc_id             = module.shared_services_vpc.vpc_id
  subnet_ids         = module.shared_services_vpc.private_subnets

  tags = merge(local.common_tags, {
    Name = "service-consumer-main-vpc"
  })

}



data "aws_ec2_transit_gateway_route_table" "main_tgw_default_route_table" {
  filter {
    name   = "default-association-route-table"
    values = ["true"]
  }

  # transit_gateway_id = aws_ec2_transit_gateway.main_tgw.id

  depends_on = [aws_ec2_transit_gateway.main_tgw]


}


////////////////////////////////////////////////////////////




## TGW PEERING


# create a transit gateway peering attachment
resource "aws_ec2_transit_gateway_peering_attachment" "main_to_transit_peering" {
  peer_region             = var.transit_region
  transit_gateway_id      = aws_ec2_transit_gateway.main_tgw.id
  peer_transit_gateway_id = aws_ec2_transit_gateway.transit_tgw.id

  tags = merge(local.common_tags, {
    Name = "tgw-peering-main-to-transit"
    Side = "Requester"
  })

}



resource "aws_ec2_transit_gateway_route" "main_to_transit_route" {
  transit_gateway_route_table_id = data.aws_ec2_transit_gateway_route_table.main_tgw_default_route_table.id
  destination_cidr_block        = local.transit_vpc_cidr
  transit_gateway_attachment_id = aws_ec2_transit_gateway_peering_attachment.main_to_transit_peering.id

  depends_on = [
    aws_ec2_transit_gateway_peering_attachment.main_to_transit_peering,
    aws_ec2_transit_gateway_vpc_attachment.main_tgw_attachment,
    aws_ec2_transit_gateway_peering_attachment_accepter.transit_accept_main
  ]


}

*/
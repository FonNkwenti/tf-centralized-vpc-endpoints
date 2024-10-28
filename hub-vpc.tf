

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



# 
resource "aws_ec2_transit_gateway" "main_tgw" {
  description = "Main region Transit Gateway"
  default_route_table_association = "disable"

  tags = merge(local.common_tags, {
    Name = "main-region-tgw"
  })

}


resource "aws_route" "hub_to_spoke_a" {
  count                  = length(module.shared_services_vpc.private_route_table_ids)
  route_table_id         = element(module.shared_services_vpc.private_route_table_ids, count.index)
  destination_cidr_block = local.spoke_a_vpc_cidr
  transit_gateway_id     = aws_ec2_transit_gateway.main_tgw.id

}
resource "aws_route" "spoke_a_to_hub" {
  count                  = length(module.spoke_a_vpc.private_route_table_ids)
  route_table_id         = element(module.spoke_a_vpc.private_route_table_ids, count.index)
  destination_cidr_block = local.shared_services_vpc_cidr
  transit_gateway_id     = aws_ec2_transit_gateway.main_tgw.id

}

# attach service_provide_main VPC to transit gateway
resource "aws_ec2_transit_gateway_vpc_attachment" "hub_vpc_attachment" {
  subnet_ids         = module.shared_services_vpc.private_subnets
  transit_gateway_id = aws_ec2_transit_gateway.main_tgw.id
  vpc_id             = module.shared_services_vpc.vpc_id
  transit_gateway_default_route_table_association = "false"

  tags = merge(local.common_tags, {
    Name = "hub-vpc"
  })

}
resource "aws_ec2_transit_gateway_vpc_attachment" "spoke_a_vpc_attachment" {
  vpc_id             = module.spoke_a_vpc.vpc_id
  transit_gateway_id = aws_ec2_transit_gateway.main_tgw.id
  subnet_ids         = module.spoke_a_vpc.private_subnets
  transit_gateway_default_route_table_association = "false"

  tags = merge(local.common_tags, {
    Name = "spoke-a-vpc"
  })

}


# data "aws_ec2_transit_gateway_route_table" "main_tgw_default_route_table" {
#   filter {
#     name   = "default-association-route-table"
#     values = ["true"]
#   }
#   depends_on = [aws_ec2_transit_gateway.main_tgw]
# }

resource "aws_ec2_transit_gateway_route_table" "shared_services_rt" {
  transit_gateway_id = aws_ec2_transit_gateway.main_tgw.id

  tags = {
    Name = "Shared-Services-Route-Table"
  }
}

# Associate the route table with both VPC attachments
resource "aws_ec2_transit_gateway_route_table_association" "hub_vpc_association" {
  transit_gateway_attachment_id = aws_ec2_transit_gateway_vpc_attachment.hub_vpc_attachment.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.shared_services_rt.id
}

resource "aws_ec2_transit_gateway_route_table_association" "spoke_a_association" {
  transit_gateway_attachment_id = aws_ec2_transit_gateway_vpc_attachment.spoke_a_vpc_attachment.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.shared_services_rt.id
}

# Add routes to enable communication between Hub and Spoke VPCs
resource "aws_ec2_transit_gateway_route" "hub_to_spoke_a" {
  destination_cidr_block         = local.spoke_a_vpc_cidr
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.shared_services_rt.id
   transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.spoke_a_vpc_attachment.id
}


resource "aws_ec2_transit_gateway_route" "spoke_a_to_hub" {
  destination_cidr_block         = local.shared_services_vpc_cidr
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.shared_services_rt.id
    transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.hub_vpc_attachment.id
}




/*


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
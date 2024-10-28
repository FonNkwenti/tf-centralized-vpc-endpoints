
module "spoke_a_vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = "${local.name}-transit"
  cidr = local.spoke_a_vpc_cidr

  azs             = local.main_azs
  private_subnets = [for k, v in local.main_azs : cidrsubnet(local.spoke_a_vpc_cidr, 8, k + 10)]

  enable_nat_gateway = false
  single_nat_gateway = false

  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(local.common_tags, {
    Name = "${local.name}-spoke-a"
  })

}

/*
resource "aws_ec2_transit_gateway" "transit_tgw" {
  description = "Main region Transit Gateway"

  tags = merge(local.common_tags, {
    Name = "transit-region-tgw"
  })

}

resource "aws_route" "main_vpc_cidr_to_transit_tgw" {
  count                  = length(module.spoke_a_vpc.private_route_table_ids)
  route_table_id         = element(module.spoke_a_vpc.private_route_table_ids, count.index)
  destination_cidr_block = local.main_vpc_cidr
  transit_gateway_id     = aws_ec2_transit_gateway.transit_tgw.id


}

# attach service_provide_transit VPC to transit gateway
resource "aws_ec2_transit_gateway_vpc_attachment" "transit_tgw_attachment" {
  transit_gateway_id = aws_ec2_transit_gateway.transit_tgw.id
  vpc_id             = module.spoke_a_vpc.vpc_id
  subnet_ids         = module.spoke_a_vpc.private_subnets

  tags = merge(local.common_tags, {
    Name = "service-consumer-transit-vpc"
  })

}

data "aws_ec2_transit_gateway_route_table" "transit_tgw_default_route_table" {
  filter {
    name   = "default-association-route-table"
    values = ["true"]
  }

  depends_on = [aws_ec2_transit_gateway.transit_tgw]


}

## TGW PEERING

resource "aws_ec2_transit_gateway_peering_attachment_accepter" "transit_accept_main" {
  transit_gateway_attachment_id = data.aws_ec2_transit_gateway_peering_attachment.accepter_peering_data.id

  tags = merge(local.common_tags, {
    Name = "tgw-peering-transit-to-main"
    Side = "Acceptor"
  })



}

# # Transit VPC transit Gateway's peering request needs to be accepted.
# So, we fetch the Peering Attachment.
data "aws_ec2_transit_gateway_peering_attachment" "accepter_peering_data" {
  depends_on = [aws_ec2_transit_gateway_peering_attachment.main_to_transit_peering]
  filter {
    name   = "state"
    values = ["pendingAcceptance", "available"]
  }
  filter {
    name = "transit-gateway-id"
    values = [aws_ec2_transit_gateway.transit_tgw.id]
  }

}

resource "aws_ec2_transit_gateway_route" "transit_to_main_route" {
  transit_gateway_route_table_id = data.aws_ec2_transit_gateway_route_table.transit_tgw_default_route_table.id
  destination_cidr_block        = local.main_vpc_cidr
  transit_gateway_attachment_id = data.aws_ec2_transit_gateway_peering_attachment.accepter_peering_data.id

  depends_on = [
    aws_ec2_transit_gateway_peering_attachment.main_to_transit_peering,
    aws_ec2_transit_gateway_vpc_attachment.transit_tgw_attachment,
    aws_ec2_transit_gateway_peering_attachment_accepter.transit_accept_main,
  ]


}



resource "aws_vpc_endpoint" "privateLink_service" {
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = false
  vpc_id              = module.service_consumer_main.vpc_id 
  service_name        = var.privateLink_service_name
  security_group_ids  = [aws_security_group.privateLink_service.id]
  subnet_ids          = module.service_consumer_main.private_subnets

  tags = merge(local.common_tags,{
    Name = "privateLink-service"
  })

}

resource "aws_security_group" "privateLink_service" {
  name        = "privateLink-service"
  description = "Security group for privateLink Interface Endpoint"
  vpc_id      = module.service_consumer_main.vpc_id 

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]

  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags,{
    Name = "privateLink-service"
  })

  lifecycle {
    create_before_destroy = true
  }

}


module "ec2_transit_instance" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "5.2.1"

  name                        = "${local.name}-transit-client"
  instance_type               = "t2.micro"
  monitoring                  = false
  associate_public_ip_address = false
  # key_name                    = ""
  subnet_id                   = module.spoke_a_vpc.private_subnets[0]
  vpc_security_group_ids      = [module.transit_spoke_a_instance_security_group.security_group_id]


}


module "transit_spoke_a_instance_security_group" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "5.1.0"

  name        = "privatelink-client-sg"
  vpc_id      = module.spoke_a_vpc.vpc_id
  description = "private instance security group"

  ingress_with_cidr_blocks = [
    {
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = "0.0.0.0/0"
      description = "allow ssh"
    },
    {
      from_port   = -1
      to_port     = -1
      protocol    = "icmp"
      cidr_blocks = "0.0.0.0/0"
      description = "allow icmp pings"
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
  
}

*/




module "spoke_a_instance" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "5.2.1"

  name                        = "${local.name}-spoke-a"
  instance_type               = "t2.micro"
  monitoring                  = false
  associate_public_ip_address = false
  key_name                    = var.ssh_key_pair
  subnet_id                   = module.spoke_a_vpc.private_subnets[0]
  vpc_security_group_ids      = [module.spoke_a_instance_security_group.security_group_id]
}


module "spoke_a_instance_security_group" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "5.1.0"

  name        = "spoke-a-client-sg"
  vpc_id      = module.spoke_a_vpc.vpc_id
  description = "private instance security group"

  ingress_with_cidr_blocks = [
    {
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = "0.0.0.0/0"
      description = "allow ssh"
    },
    {
      from_port   = -1
      to_port     = -1
      protocol    = "icmp"
      cidr_blocks = "0.0.0.0/0"
      description = "allow icmp pings"
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

}



resource "aws_ec2_instance_connect_endpoint" "spoke_a_instance" {
  subnet_id  = element(module.spoke_a_vpc.private_subnets, 0)  
  depends_on = [module.spoke_a_instance]
  security_group_ids = [module.spoke_a_instance_security_group.security_group_id]

  tags = local.common_tags


}




module "spoke_a_instance_connect_security_group" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "5.1.0"

  name        = "ec2-instance-connect-sg"
  vpc_id      = module.spoke_a_vpc.vpc_id
  description = "private instance security group"

  ingress_with_cidr_blocks = [
    {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = "0.0.0.0/0"
      description = "allow all traffic"
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

}
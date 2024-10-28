
module "ec2_instance" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "5.2.1"

  name                        = "${local.name}-client"
  instance_type               = "t2.micro"
  monitoring                  = false
  associate_public_ip_address = false
  key_name                    = var.ssh_key_pair
  subnet_id                   = module.shared_services_vpc.private_subnets[0]
  vpc_security_group_ids      = [module.instance_security_group.security_group_id]
}


module "instance_security_group" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "5.1.0"

  name        = "privatelink-client-sg"
  vpc_id      = module.shared_services_vpc.vpc_id
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



resource "aws_ec2_instance_connect_endpoint" "this" {
  subnet_id  = element(module.shared_services_vpc.private_subnets, 0)  
  depends_on = [module.ec2_instance]
  security_group_ids = [module.instance_security_group.security_group_id]

  tags = local.common_tags


}




module "instance_connect_security_group" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "5.1.0"

  name        = "ec2-instance-connect-sg"
  vpc_id      = module.shared_services_vpc.vpc_id
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





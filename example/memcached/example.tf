provider "aws" {
  region = "ap-south-1"
}

module "vpc" {
  source                              = "git::https://github.com/opsstation/terraform-aws-vpc.git?ref=v1.0.0"
  name                                = "app"
  environment                         = "test"
  cidr_block                          = "10.0.0.0/16"
  enable_flow_log                     = true
  create_flow_log_cloudwatch_iam_role = true
  additional_cidr_block               = ["172.3.0.0/16", "172.2.0.0/16"]
  dhcp_options_domain_name            = "service.consul"
  dhcp_options_domain_name_servers    = ["127.0.0.1", "10.10.0.2"]
}

module "subnet" {
  source             = "git::https://github.com/opsstation/terraform-aws-subnet.git?ref=v1.0.0"
  name               = "app"
  environment        = "test"
  availability_zones = ["ap-south-1a", "ap-south-1b", "ap-south-1c"]
  vpc_id             = module.vpc.id
  type               = "public"
  igw_id             = module.vpc.igw_id
  ipv4_public_cidrs  = ["10.0.1.0/24", "10.0.13.0/24", "10.0.18.0/24"]
  enable_ipv6        = false
}

module "memcached" {
  source = "./../../"

  name        = "memcached"
  environment = "test"
  label_order = ["name", "environment"]

  vpc_id        = module.vpc.id
  allowed_ip    = [module.vpc.vpc_cidr_block]
  allowed_ports = [11211]

  cluster_enabled                          = true
  memcached_ssm_parameter_endpoint_enabled = true
  memcached_route53_record_enabled         = false
  engine                                   = "memcached"
  engine_version                           = "1.6.17"
  parameter_group_name                     = ""
  az_mode                                  = "cross-az"
  port                                     = 11211
  node_type                                = "cache.t2.micro"
  num_cache_nodes                          = 2
  subnet_ids                               = module.subnet.public_subnet_id
  availability_zones                       = ["ap-south-1a", "ap-south-1b"]
  extra_tags = {
    Application = "opsstation"
  }

  route53_record_enabled         = false
  ssm_parameter_endpoint_enabled = false
  dns_record_name                = "prod"
  route53_ttl                    = "300"
  route53_type                   = "CNAME"
  route53_zone_id                = "SERFxxxx6XCsY9Lxxxxx"

}

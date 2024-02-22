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
  additional_cidr_block               = ["172.3.0.0/16"]
  dhcp_options_domain_name            = "service.consul"
  dhcp_options_domain_name_servers    = ["127.0.0.1"]
}

module "subnet" {
  source             = "git::https://github.com/opsstation/terraform-aws-subnet.git?ref=v1.0.0"
  name               = "app"
  environment        = "test"
  availability_zones = ["ap-south-1a"]
  vpc_id             = module.vpc.id
  type               = "public"
  igw_id             = module.vpc.igw_id
  ipv4_public_cidrs  = ["10.0.1.0/24"]
  enable_ipv6        = false
}

module "redis-cluster" {
  source = "./../../"

  name        = "redis-cluster"
  environment = "test"
  label_order = ["environment", "name"]


  vpc_id        = module.vpc.id
  allowed_ip    = [module.vpc.vpc_cidr_block]
  allowed_ports = [6379]

  cluster_replication_enabled = true
  engine                      = "redis"
  engine_version              = "7.0"
  parameter_group_name        = "default.redis7.cluster.on"
  port                        = 6379
  node_type                   = "cache.t2.micro"
  subnet_ids                  = module.subnet.public_subnet_id
  availability_zones          = ["ap-south-1a"]
  num_cache_nodes             = 1
  snapshot_retention_limit    = 7
  automatic_failover_enabled  = true
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

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

module "redis" {
  source = "./../../"

  name        = "redis"
  environment = "test"
  label_order = ["name", "environment"]

  vpc_id        = module.vpc.id
  allowed_ip    = [module.vpc.vpc_cidr_block]
  allowed_ports = [6379]

  cluster_replication_enabled = true
  engine                      = "redis"
  engine_version              = "7.1"
  parameter_group_name        = "default.redis7"
  port                        = 6379
  node_type                   = "cache.r6g.large"
  subnet_ids                  = module.subnet.public_subnet_id
  availability_zones          = [""]
  automatic_failover_enabled  = false
  multi_az_enabled            = false
  num_cache_clusters          = 1
  retention_in_days           = 0
  snapshot_retention_limit    = 7

  log_delivery_configuration = [
    {
      destination_type = "cloudwatch-logs"
      log_format       = "json"
      log_type         = "slow-log"
    },
    {
      destination_type = "cloudwatch-logs"
      log_format       = "json"
      log_type         = "engine-log"
    }
  ]
  extra_tags = {
    Application = "opsstation"
  }

  route53_record_enabled         = false
  ssm_parameter_endpoint_enabled = false
  dns_record_name                = "prod"
  route53_ttl                    = "300"
  route53_type                   = "CNAME"
  route53_zone_id                = "Z017xxxxDLxxx0GH04"
}

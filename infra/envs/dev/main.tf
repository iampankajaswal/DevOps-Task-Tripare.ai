terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket         = "terraform-state-dev-hotel-bookings"
    key            = "dev/terraform.tfstate"
    region         = "ap-south-2"
    dynamodb_table = "terraform-lock-dev"
    encrypt        = true
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Environment = "dev"
      ManagedBy   = "terraform"
      Project     = "hotel-bookings"
    }
  }
}

module "network" {
  source = "../../modules/network"

  environment          = var.environment
  vpc_cidr             = var.vpc_cidr
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  availability_zones   = var.availability_zones
  container_port       = var.container_port
}

module "ecs" {
  source = "../../modules/ecs"

  environment           = var.environment
  aws_region            = var.aws_region
  vpc_id                = module.network.vpc_id
  public_subnet_ids     = module.network.public_subnet_ids
  private_subnet_ids    = module.network.private_subnet_ids
  alb_security_group_id = module.network.alb_security_group_id
  ecs_security_group_id = module.network.ecs_security_group_id
  container_image       = var.container_image
  container_port        = var.container_port
  task_cpu              = var.task_cpu
  task_memory           = var.task_memory
  desired_count         = var.desired_count
  db_host               = module.rds.db_address
  db_name               = var.db_name
}

module "rds" {
  source = "../../modules/rds"

  environment             = var.environment
  private_subnet_ids      = module.network.private_subnet_ids
  rds_security_group_id   = module.network.rds_security_group_id
  instance_class          = var.rds_instance_class
  allocated_storage       = var.rds_allocated_storage
  max_allocated_storage   = var.rds_max_allocated_storage
  db_name                 = var.db_name
  db_username             = var.db_username
  db_password             = var.db_password
  multi_az                = var.rds_multi_az
  backup_retention_period = var.rds_backup_retention_period
  deletion_protection     = var.rds_deletion_protection
}

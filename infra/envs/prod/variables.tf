variable "environment" {
  description = "Environment name"
  type        = string
}

variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "vpc_cidr" {
  description = "VPC CIDR block"
  type        = string
}

variable "public_subnet_cidrs" {
  description = "Public subnet CIDRs"
  type        = list(string)
}

variable "private_subnet_cidrs" {
  description = "Private subnet CIDRs"
  type        = list(string)
}

variable "availability_zones" {
  description = "Availability zones"
  type        = list(string)
}

variable "container_image" {
  description = "Docker image for the app"
  type        = string
}

variable "container_port" {
  description = "Container port"
  type        = number
}

variable "task_cpu" {
  description = "ECS task CPU units"
  type        = number
}

variable "task_memory" {
  description = "ECS task memory in MB"
  type        = number
}

variable "desired_count" {
  description = "Number of ECS tasks"
  type        = number
}

variable "db_name" {
  description = "Database name"
  type        = string
}

variable "db_username" {
  description = "Database master username"
  type        = string
  sensitive   = true
}

variable "db_password" {
  description = "Database master password"
  type        = string
  sensitive   = true
}

variable "rds_instance_class" {
  description = "RDS instance class"
  type        = string
}

variable "rds_allocated_storage" {
  description = "RDS allocated storage in GB"
  type        = number
}

variable "rds_max_allocated_storage" {
  description = "RDS max allocated storage in GB"
  type        = number
}

variable "rds_multi_az" {
  description = "Enable multi-AZ"
  type        = bool
}

variable "rds_backup_retention_period" {
  description = "Backup retention in days"
  type        = number
}

variable "rds_deletion_protection" {
  description = "Enable deletion protection"
  type        = bool
}

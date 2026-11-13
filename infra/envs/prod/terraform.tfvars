environment = "prod"
aws_region  = "ap-south-1"

vpc_cidr             = "10.1.0.0/16"
public_subnet_cidrs  = ["10.1.1.0/24", "10.1.2.0/24"]
private_subnet_cidrs = ["10.1.10.0/24", "10.1.20.0/24"]
availability_zones   = ["ap-south-1a", "ap-south-1b"]

container_image = "nginx:latest"
container_port  = 80
task_cpu        = 512
task_memory     = 1024
desired_count   = 2

db_name     = "hotel_bookings"
db_username = "dbadmin"
db_password = "prod-change-me-in-secrets-manager"

rds_instance_class          = "db.t3.medium"
rds_allocated_storage       = 50
rds_max_allocated_storage   = 200
rds_multi_az                = true
rds_backup_retention_period = 14
rds_deletion_protection     = true

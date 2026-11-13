environment = "dev"
aws_region  = "ap-south-1"

vpc_cidr             = "10.0.0.0/16"
public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24"]
private_subnet_cidrs = ["10.0.10.0/24", "10.0.20.0/24"]
availability_zones   = ["ap-south-1a", "ap-south-1b"]

container_image = "nginx:latest"
container_port  = 80
task_cpu        = 256
task_memory     = 512
desired_count   = 1

db_name     = "hotel_bookings"
db_username = "dbadmin"
db_password = "dev-change-me-in-secrets-manager"

rds_instance_class          = "db.t3.micro"
rds_allocated_storage       = 20
rds_max_allocated_storage   = 50
rds_multi_az                = false
rds_backup_retention_period = 3
rds_deletion_protection     = false

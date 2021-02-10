resource "aws_db_instance" "database" {
    allocated_storage = 20
    storage_type = "gp2"
    engine = "mysql"
    engine_version = "5.7"
    instance_class = var.aws_db_instance_type
    name = var.aws_db_name
    username = var.aws_db_username
    password = var.aws_db_password
    publicly_accessible = true
    skip_final_snapshot = true
    backup_retention_period = 0
    tags = {
      Environment = "dev"
    }
}
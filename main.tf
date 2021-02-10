terraform {
    required_version = ">= 0.12"
    backend "s3" {
        bucket = "BUCKET_NAME" //NECESSARIO COLOCAR NOME DO BUCKET
        key = "project_1.tfstate"
        region = "us-east-2"
    }
}

//TEMPLATE FILE

data "template_file" "phpconfig" {
    template = file("files/conf.wp-config.php")
    vars = {
      db_port = aws_db_instance.database.port
      db_host = aws_db_instance.database.address
      db_user = var.aws_db_username
      db_pass = var.aws_db_password
      db_name = var.aws_db_name
    }
}

// S3

resource "aws_s3_bucket_object" "object" {
  bucket = "BUCKET_NAME" //NECESSARIO COLOCAR NOME DO BUCKET
  key    = "wp-config.php"
  content = data.template_file.phpconfig.rendered
  acl = "public-read"
}
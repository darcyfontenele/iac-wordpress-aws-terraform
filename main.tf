terraform {
    required_version = ">= 0.12"
    backend "s3" {
        bucket = "BUCKET_NAME" //NECESSARIO COLOCAR NOME DO BUCKET
        key = "project_1.tfstate"
        region = "us-east-2"
    }
}

//PROVIDER - EXTERNALIZAR

provider "aws" {
    region = var.aws_region
}

//DATABASE

data "template_file" "phpconfig" {
    template = file("files/conf.wp-config.php") //ARQUIVO DE CONFIGURACAO DO BANCO
    vars = {
        db_port = aws_db_instance.database.port
        db_host = aws_db_instance.database.address
        db_user = aws_db_instance.database.username //ALTERAR PARA VARIAVEL EXTERNA
        db_pass = aws_db_instance.database.password //ALTERAR PARA VARIAVEL EXTERNA
        db_name = aws_db_instance.database.name //ALTERAR PARA VARIAVEL EXTERNA
    }
}

resource "aws_s3_bucket_object" "object" {
  bucket = "BUCKET_NAME" //NECESSARIO COLOCAR NOME DO BUCKET
  key    = "wp-config.php"
  content = data.template_file.phpconfig.rendered
  acl = "public-read"
}

resource "aws_db_instance" "database" {
    allocated_storage = 20
    storage_type = "gp2"
    engine = "mysql"
    engine_version = "5.7"
    instance_class = "db.t2.micro"
    name = "wordpress" //ALTERAR PARA VARIAVEL EXTERNA
    username = "iacmysqldb" //ALTERAR PARA VARIAVEL EXTERNA
    password = "iacmysqldb" //ALTERAR PARA VARIAVEL EXTERNA
    publicly_accessible = true
    skip_final_snapshot = true
    backup_retention_period = 0
    tags = {
      Environment = "dev"
    }
}

// WORDPRESS

resource "aws_security_group" "web" {
  vpc_id = aws_vpc.main.id

  ingress {
    protocol    = "tcp"
    from_port   = 22
    to_port     = 22
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    protocol    = "icmp"
    from_port   = -1
    to_port     = -1
    cidr_blocks = ["172.31.0.0/16"]
  }

  ingress {
    protocol    = "tcp"
    from_port   = 80
    to_port     = 80
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    protocol    = -1
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_launch_template" "web" {
  name = "web"
  instance_type = "t2.micro"
  key_name = "iacuece"
  network_interfaces {
    subnet_id =  aws_subnet.main.id
    security_groups = [aws_security_group.web.id]
  }
  image_id = "ami-01aab85a5e4a5a0fe"
  placement {
    availability_zone = "us-east-2a"
  }
  user_data = filebase64("./files/userdata.sh")
  monitoring {
    enabled = true
  }
}

resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
}

resource "aws_subnet" "main" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
}

resource "aws_default_route_table" "main" {
  default_route_table_id = aws_vpc.main.default_route_table_id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }
}

resource "aws_elb" "elb1" {
    name = "terraform-elb"
    security_groups = [aws_security_group.web.id]
    subnets = [aws_subnet.main.id]
    listener {
      instance_port = 80
      instance_protocol = "http"
      lb_port = 80
      lb_protocol = "http"
    }
    health_check {
      healthy_threshold = 2
      unhealthy_threshold = 2
      timeout = 3
      target = "HTTP:80/"
      interval = 30
    }
    cross_zone_load_balancing = true
    idle_timeout = 60
    connection_draining = true
    connection_draining_timeout = 60
}

resource "aws_autoscaling_group" "web" {

  min_size             = 1
  max_size             = 2
  
  health_check_type    = "ELB"
  load_balancers = [
    aws_elb.elb1.id
  ]

  launch_template {
    id      = aws_launch_template.web.id
    version = "$Latest"
  }

  enabled_metrics = [
    "GroupMinSize",
    "GroupMaxSize",
    "GroupDesiredCapacity",
    "GroupInServiceInstances",
    "GroupTotalInstances"
  ]

  metrics_granularity = "1Minute"

  vpc_zone_identifier  = [aws_subnet.main.id]

  # Required to redeploy without an outage.
  lifecycle {
    create_before_destroy = true
  }

  depends_on = [ 
    aws_s3_bucket_object.object
  ]

}

resource "aws_autoscaling_policy" "web_policy_up" {
  name = "web_policy_up"
  scaling_adjustment = 1
  adjustment_type = "ChangeInCapacity"
  cooldown = 180
  autoscaling_group_name = aws_autoscaling_group.web.name
}

resource "aws_cloudwatch_metric_alarm" "web_cpu_alarm_up" {
  alarm_name = "web_cpu_alarm_up"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods = "1"
  metric_name = "CPUUtilization"
  namespace = "AWS/EC2"
  period = "60"
  statistic = "Average"
  threshold = "50"

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.web.name
  }

  alarm_description = "This metric monitor EC2 instance CPU utilization"
  alarm_actions = [ aws_autoscaling_policy.web_policy_up.arn ]
}

resource "aws_autoscaling_policy" "web_policy_down" {
  name = "web_policy_down"
  scaling_adjustment = -1
  adjustment_type = "ChangeInCapacity"
  cooldown = 180
  autoscaling_group_name = aws_autoscaling_group.web.name
}

resource "aws_cloudwatch_metric_alarm" "web_cpu_alarm_down" {
  alarm_name = "web_cpu_alarm_down"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods = "1"
  metric_name = "CPUUtilization"
  namespace = "AWS/EC2"
  period = "120"
  statistic = "Average"
  threshold = "20"

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.web.name
  }

  alarm_description = "This metric monitor EC2 instance CPU utilization"
  alarm_actions = [ aws_autoscaling_policy.web_policy_down.arn ]
}
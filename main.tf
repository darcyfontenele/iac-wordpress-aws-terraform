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

//DATABASE

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

// SECURITY GROUP

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
    cidr_blocks = [aws_vpc.main.cidr_block]
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

// VPC/SUBNETS/INTERNET GATEWAY/ROUTING TABLE

resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
}

resource "aws_subnet" "main" {
  vpc_id                  = aws_vpc.main.id
  availability_zone = var.aws_az
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

// LOAD BALANCER

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
      target = "HTTP:80/wp-admin/images/wordpress-logo.svg"
      interval = 30
    }
    cross_zone_load_balancing = true
    idle_timeout = 60
    connection_draining = true
    connection_draining_timeout = 60
}

// INSTANCE TEMPLATE

resource "aws_launch_template" "web" {
  name = "web"
  instance_type = var.aws_instance_type
  key_name = var.aws_key_pair
  network_interfaces {
    subnet_id =  aws_subnet.main.id
    security_groups = [aws_security_group.web.id]
  }
  image_id = var.aws_ami
  placement {
    availability_zone = var.aws_az
  }
  user_data = filebase64("./files/userdata.sh")
  monitoring {
    enabled = true
  }
}

// AUTO SCALING GROUP

resource "aws_autoscaling_group" "web" {
  min_size             = 1
  max_size             = 4
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
  lifecycle {
    create_before_destroy = true
  }
  depends_on = [ 
    aws_s3_bucket_object.object
  ]
}

// POLICIES

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
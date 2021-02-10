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
output "dns_name" {
  description = "Load balancer DNS name to access the web resources."
  value = aws_elb.elb1.dns_name
}
variable "aws_region" {
    type = string
    description = "(optional) describe your variable"
    default = "us-east-2"
}

variable "aws_ami" {
    type = string
    description = ""
    default = "ami-0be2609ba883822ec"
}

variable "aws_instance_type" {
    type = string
    description = ""
    default = "t2.micro"
}

variable "aws_az" {
    type = string
    description = ""
    default = "us-east-2a"
}
variable "container_name" {
  type    = "string"
  default = "webinar-web-app"
}

variable "container_port" {
    type = "string"
    default = "80"
}

variable "aws_region" {
  type    = "string"
  default = "eu-west-1"
}

variable "alb_name" {
    type = "string"
    default = "aws-webinar"
}


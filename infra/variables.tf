variable "container_name" {
  type    = "string"
  default = "webinar-web-app"
}

variable "container_port" {
  type    = "string"
  default = "80"
}

variable "container_desired_count" {
  type    = "string"
  default = "2"
}

variable "container_desired_cpu" {
  type    = "string"
  default = "256"
}

variable "container_desired_memory" {
  type    = "string"
  default = "512"
}

variable "ecs_cluster_name" {
  type    = "string"
  default = "webinar"
}

variable "aws_region" {
  type    = "string"
  default = "eu-west-1"
}

variable "alb_name" {
  type    = "string"
  default = "aws-webinar"
}

variable "github_username" {
  type    = "string"
  default = "cobusbernard"
}

variable "github_repo_name" {
  type    = "string"
  default = "aws-containers-for-beginners"
}
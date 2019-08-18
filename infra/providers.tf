provider "aws" {
  version = "~> 2.0"
  region  = "eu-west-1"
  profile = "aws-webinar"
}

provider "github" {
  version    = "~> 2.2"
  token      = "${local.github_token}"
  organization = "${local.github_username}"
}

provider "template" {
  version = "~> 2.1"
}
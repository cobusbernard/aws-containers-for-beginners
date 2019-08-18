terraform {
  backend "s3" {
    bucket = "webinar-terraform-sample"
    key    = "statefiles"
    region = "eu-west-1"
    profile = "aws-webinar"
  }
}

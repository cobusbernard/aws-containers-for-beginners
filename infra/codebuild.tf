# To build the container, we need the following components:
# 1. An ECR repository to store the built image in.
# 2. A CodeBuild job to build and push the container. The build steps are defined in the buildspec.yml file.
# 3. An IAM policy that the build runs as with access to create images and push to ECR.

data "template_file" "codebuild_policy" {
  template = "${file("templates/codebuild_iam_policy.json")}"

  #   vars = {
  #     aws_s3_bucket_arn = "${aws_s3_bucket.source.arn}"
  #   }
}

resource "aws_iam_role" "codebuild_role" {
  name               = "codebuild-role"
  assume_role_policy = "${file("templates/codebuild_iam_role_policy.json")}"
}

resource "aws_iam_role_policy" "codebuild_policy" {
  name   = "codebuild-policy"
  role   = "${aws_iam_role.codebuild_role.id}"
  policy = "${data.template_file.codebuild_policy.rendered}"
}

resource "aws_ecr_repository" "ecr_repo" {
  name = "${var.container_name}"
}

data "template_file" "buildspec" {
  template = "${file("templates/buildspec.yml")}"

  vars = {
    container_name = "${var.container_name}"
    repository_url = "${aws_ecr_repository.ecr_repo.repository_url}"
    region         = "${var.aws_region}"
  }
}

resource "aws_codebuild_project" "build_image" {
  name          = "${var.container_name}-docker-build"
  build_timeout = "60"

  service_role = "${aws_iam_role.codebuild_role.arn}"

  artifacts {
    type = "NO_ARTIFACTS"
  }

  environment {
    compute_type = "BUILD_GENERAL1_SMALL"
    image        = "aws/codebuild/standard:1.0"
    type         = "LINUX_CONTAINER"
    # This is needed to allow building container images.
    privileged_mode = true
  }

  source {
    type                = "GITHUB"
    location            = "https://github.com/cobusbernard/aws-containers-for-beginners.git"
    git_clone_depth     = 1
    report_build_status = true
    buildspec           = "${data.template_file.buildspec.rendered}"
  }
}
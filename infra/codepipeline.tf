# To make use of CodePipeline, we will need a few components:
# 1. CodeBuild job (we already have one)
# 2. IAM role for CodePipeline to execute as
# 2. An S3 bucket to store the source code into
# 3. An ECS cluster to deploy to (which we already have)

resource "aws_s3_bucket" "webinar_source" {
  bucket        = "${var.container_name}-pipeline"
  acl           = "private"
  force_destroy = true
}

resource "aws_iam_role" "codepipeline_role" {
  name               = "codepipeline-role"
  assume_role_policy = "${file("templates/codepipeline_iam_role_policy.json")}"
}

data "template_file" "codepipeline_policy" {
  template = "${file("templates/codepipeline_iam_policy.json")}"

  vars = {
    codepipeline_bucket_arn = "${aws_s3_bucket.webinar_source.arn}"
  }
}

resource "aws_iam_role_policy" "codepipeline_policy" {
  name   = "codepipeline_policy"
  role   = "${aws_iam_role.codepipeline_role.id}"
  policy = "${data.template_file.codepipeline_policy.rendered}"
}

resource "aws_codepipeline" "webinar_pipeline" {
  name     = "${var.container_name}-pipeline"
  role_arn = "${aws_iam_role.codepipeline_role.arn}"

  artifact_store {
    location = "${aws_s3_bucket.webinar_source.bucket}"
    type     = "S3"
  }

  stage {
    name = "Source"

    action {
      name             = "Source"
      category         = "Source"
      owner            = "ThirdParty"
      provider         = "GitHub"
      version          = "1"
      output_artifacts = ["source"]

      configuration = {
        Owner  = "${var.github_username}"
        Repo   = "${var.github_repo_name}"
        Branch = "master"
      }
    }
  }

  stage {
    name = "Build"

    action {
      name             = "Build"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      version          = "1"
      input_artifacts  = ["source"]
      output_artifacts = ["imagedefinitions"]

      configuration = {
        ProjectName = "${var.container_name}-docker-build"
      }
    }
  }

  stage {
    name = "Production"

    action {
      name            = "Deploy"
      category        = "Deploy"
      owner           = "AWS"
      provider        = "ECS"
      input_artifacts = ["imagedefinitions"]
      version         = "1"

      configuration = {
        ClusterName = "${var.ecs_cluster_name}"
        ServiceName = "${var.container_name}"
        FileName    = "imagedefinitions.json"
      }
    }
  }
}

resource "aws_codepipeline_webhook" "webinar_app" {
  name            = "${var.container_name}-webhook-github"
  authentication  = "GITHUB_HMAC"
  target_action   = "Source"
  target_pipeline = "${aws_codepipeline.webinar_pipeline.name}"

  authentication_configuration {
    secret_token = "${local.webhook_secret}"
  }

  filter {
    json_path    = "$.ref"
    match_equals = "refs/heads/{Branch}"
  }
}

# Wire the CodePipeline webhook into a GitHub repository.
resource "github_repository_webhook" "webinar_app" {
  repository = "${var.github_repo_name}"

  configuration {
    url          = "${aws_codepipeline_webhook.webinar_app.url}"
    content_type = "json"
    insecure_ssl = true
    secret       = "${local.webhook_secret}"
  }

  events = ["push"]
}
# AWS Getting started with Containers Webinar

This repo is used to set up the infrastructure used to build and deploy a container to ECS Fargate for a webinar.

## Setup

1. Create an IAM user with sufficient permissions to create the infrastructure you require. Generate an API key for the user, and create a named profile in `~/.aws/credentials` that looks like this:
~~~
[aws-webinar]
aws_access_key_id = your_api_key
aws_secret_access_key = your_api_key_secret
~~~

2. Create an S3 bucket in your region of choice. Edit `infra/terraform-state.tf` by replacing the `bucket`, `region` and `profile` values to what you have configured.

3. Run `terraform init` in the `infra` directory.

4. In `infra/variables.tf`, change the `github_username` and `github_repo_name` defaults to your ones.

5. Create `infra/secret.tf` with the following:
~~~
locals {
  webhook_secret  = "web-hook-secret-shared-string"
  github_token    = "github-token-with-permission-to-create-webhooks"
  github_username = "cobusbernard"
}
~~~
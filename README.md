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

4. To connect the repo in GitHub with CodeBuild, it needs a GitHub access token. Generate one and then create the following file:
~~~
{
  "serverType": "GITHUB",
  "authType": "PERSONAL_ACCESS_TOKEN",
  "token": "my-github-token",
  "username": "my-github-username"
}
~~~
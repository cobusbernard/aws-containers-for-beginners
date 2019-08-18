resource "aws_ecs_cluster" "aws_ecs_cluster" {
  name = "${var.ecs_cluster_name}"
}

resource "aws_cloudwatch_log_group" "webinar_app" {
  name = "${var.ecs_cluster_name}-logs"
}


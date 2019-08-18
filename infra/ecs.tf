resource "aws_ecs_cluster" "aws_ecs_cluster" {
  name = "${var.ecs_cluster_name}"
}

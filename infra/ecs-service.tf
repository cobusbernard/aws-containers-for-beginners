# Now that we have a cluster and a CodePipeline, it needs to be able to deploy somewhere. For this, we need to define a task that can be used to run an ECS service.
# This requires:
# 1. An ECS task definition (which container, cpu & ram requirements, etc)
# 2. An ECS service definition (how many of a task to run)
# 3. IAM Role for ECS to execute as - this grants ECS service permission to interact with AWS resources like the Target Groups.
# 4. IAM Role for the ECS task definition - this grans the container permission to interact with AWS resources.
# 5. A log group to send logs to


resource "aws_cloudwatch_log_group" "webinar_app" {
  name = "${var.ecs_cluster_name}-logs"
}

# IAM Roles
## ECS Execution
resource "aws_iam_role" "ecs_execution_role" {
  name               = "ecs_execution_role"
  assume_role_policy = "${file("templates/ecs_execution_iam_role_policy.json")}"
}

resource "aws_iam_role_policy_attachment" "ecs_execution_policy_ecs_main" {
  role       = "${aws_iam_role.ecs_execution_role.id}"
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

## ECS Task
resource "aws_iam_role" "ecs_task_role" {
  name               = "ecs_task_role"
  assume_role_policy = "${file("templates/ecs_task_run_iam_role_policy.json")}"
}

data "template_file" "ecs_task_role_policy" {
  template = "${file("templates/ecs_task_run_iam_policy.json")}"
}

resource "aws_iam_policy" "ecs_task_role_policy" {
  name        = "ecs_task_role_policy"
  path        = "/"
  description = "Policy to run the ${var.container_name} task"

  policy = "${data.template_file.ecs_task_role_policy.rendered}"
}


resource "aws_iam_role_policy_attachment" "ecs_task_policy" {
  role       = "${aws_iam_role.ecs_task_role.id}"
  policy_arn = "${aws_iam_policy.ecs_task_role_policy.arn}"
}

data "template_file" "webinar_task" {
  template = "${file("templates/webinar_task.json")}"

  vars = {
    aws_region          = "${var.aws_region}"
    image               = "${aws_ecr_repository.webinar_repo.repository_url}"
    container_name      = "${var.container_name}"
    container_port      = "${var.container_port}"
    log_group           = "${aws_cloudwatch_log_group.webinar_app.name}"
    desired_task_cpu    = "${var.container_desired_cpu}"
    desired_task_memory = "${var.container_desired_memory}"
  }
}

resource "aws_ecs_task_definition" "webinar" {
  family                   = "${var.container_name}-app"
  container_definitions    = "${data.template_file.webinar_task.rendered}"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = "${var.container_desired_cpu}"
  memory                   = "${var.container_desired_memory}"

  execution_role_arn = "${aws_iam_role.ecs_execution_role.arn}"
  #  task_role_arn      = "${aws_iam_role.ecs_task_role.arn}"
}

resource "aws_security_group" "webinar_service" {
  name        = "ecs-service-${var.alb_name}"
  description = "ALB Security Group."
  vpc_id      = "${module.vpc.vpc_id}"

  tags = {
    Name = "alb-${var.alb_name}"
  }
}

resource "aws_security_group_rule" "webinar_service_allow_http" {
  type                     = "ingress"
  from_port                = 80
  to_port                  = 80
  protocol                 = "tcp"
  source_security_group_id = "${aws_security_group.alb.id}"

  security_group_id = "${aws_security_group.webinar_service.id}"
}

resource "aws_security_group_rule" "webinar_service_allow_egress" {
  type        = "egress"
  from_port   = 0
  to_port     = 65535
  protocol    = "-1"
  cidr_blocks = ["0.0.0.0/0"]

  security_group_id = "${aws_security_group.webinar_service.id}"
}

data "aws_ecs_task_definition" "webinar_current" {
  task_definition = "${aws_ecs_task_definition.webinar.family}"
}

resource "aws_ecs_service" "webinar" {
  name            = "${var.container_name}"
  task_definition = "${aws_ecs_task_definition.webinar.family}:${max("${aws_ecs_task_definition.webinar.revision}", "${data.aws_ecs_task_definition.webinar_current.revision}")}"

  cluster         = "${aws_ecs_cluster.aws_ecs_cluster.id}"
  launch_type     = "FARGATE"
  desired_count   = "${var.container_desired_count}"

  network_configuration {
    security_groups  = ["${aws_security_group.webinar_service.id}"]
    subnets          = "${module.vpc.private_subnets}"
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = "${aws_alb_target_group.webinar_service_target_group.arn}"
    container_name   = "${var.container_name}"
    container_port   = "${var.container_port}"
  }
}
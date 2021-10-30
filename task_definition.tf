data "template_file" "service" {
  template = coalesce(var.service_task_container_definitions, file("${path.module}/container-definitions/service.json.tpl"))

  vars = {
    name      = var.service_name
    image     = var.service_image
    command   = jsonencode(var.service_command)
    port      = var.service_port
    region    = var.region
    log_group = var.include_log_group == "yes" ? aws_cloudwatch_log_group.service[0].name : ""
  }
}

data "aws_iam_role" "ecs_task_execution_role" {
  name = "ecsTaskExecutionRole"
}

resource "aws_ecs_task_definition" "service" {
  family                = "${var.service_name}"
  container_definitions = data.template_file.service.rendered
  cpu                      = var.fargate_cpu
  memory                   = var.fargate_memory
  requires_compatibilities = ["FARGATE"]
  network_mode = var.service_task_network_mode
  pid_mode     = var.service_task_pid_mode
  task_role_arn = var.service_role
  execution_role_arn = data.aws_iam_role.ecs_task_execution_role.arn
  dynamic "volume" {
    for_each = var.service_volumes
    content {
      name      = volume.value.name
      host_path = lookup(volume.value, "host_path", null)
    }
  }
}

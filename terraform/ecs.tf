resource "aws_ecs_cluster" "ecs-pratice-cluster" {
  name = "ecs-pratice-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

resource "aws_ecs_task_definition" "ecs-pratice-task" {
  family                   = "ecs-pratice-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.ecs_execution.arn
  volume {
    name = "app-efs-volume"
    efs_volume_configuration {
      file_system_id = aws_efs_file_system.app_efs.id
      root_directory = "/"
    }
  }
  container_definitions = jsonencode([
    {
      name      = "app-container"
      image     = "${aws_ecr_repository.secertmanager_ecr_repo.repository_url}:latest"
      essential = true
      secrets = [
        {
          name      = "DB_PASSWORD"
          valueFrom = "${aws_secretsmanager_secret.app_secret.arn}:password::"
        }
      ]
      portMappings = [
        {
          containerPort = 80
          hostPort      = 80
          protocol      = "tcp"
        }
      ]
      mountPoints = [
        {
          sourceVolume  = "app-efs-volume"
          containerPath = "/mnt"
          readOnly      = false
        }
      ]
    }
  ])
}

resource "aws_security_group" "ecs-service_sg" {
  name        = "ecs-service-sg"
  description = "Security group for ECS service"
  vpc_id      = var.vpc_id
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"          # Allow all inbound traffic
    cidr_blocks = ["0.0.0.0/0"] # Allow HTTP traffic from anywhere
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"          # Allow all outbound traffic
    cidr_blocks = ["0.0.0.0/0"] # Allow all outbound traffic
  }

}

resource "aws_ecs_service" "ecs-secert" {
  name            = "ecs-secert-service"
  cluster         = aws_ecs_cluster.ecs-pratice-cluster.id
  task_definition = aws_ecs_task_definition.ecs-pratice-task.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = var.subnets # Replace with your subnet IDs
    security_groups  = [aws_security_group.ecs-service_sg.id]                   # Replace with your security group ID
    assign_public_ip = true
  }

  depends_on = [
    aws_iam_role_policy_attachment.ecs_execution_policy,
    aws_iam_role_policy_attachment.ecs_cloudwatch_policy,
    aws_iam_role_policy_attachment.ecs_ecr_policy,
    aws_iam_policy_attachment.ecs_secrets_policy
  ]

}
resource "aws_ecs_cluster" "ecs-pratice-cluster" {
  name = "ecs-pratice-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

resource "aws_ecs_task_definition" "ecs-pratice-task-a" {
  family                   = "ecs-pratice-task-app-service-a"
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
      image     = "${aws_ecr_repository.service_a.repository_url}:latest"
      essential = true
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
      environment = [
        {
          name  = "BACKEND_URL"
          value = "http://backend.service.local:8080"
        }
      ]
    }
  ])
}

resource "aws_ecs_task_definition" "ecs-pratice-task-b" {
  family                   = "ecs-pratice-task-app-service-b"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.ecs_execution.arn
  container_definitions = jsonencode([
    {
      name      = "app-container"
      image     = "${aws_ecr_repository.service_b.repository_url}:latest"
      essential = true
      secrets = [
        {
          name      = "DB_PASSWORD"
          valueFrom = "${aws_secretsmanager_secret.app_secret.arn}:password::"
        }
      ]
      portMappings = [
        {
          containerPort = 8080
          hostPort      = 8080
          protocol      = "tcp"
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

resource "aws_ecs_service" "service_a" {
  name            = "ecs-secert-service-a"
  cluster         = aws_ecs_cluster.ecs-pratice-cluster.id
  task_definition = aws_ecs_task_definition.ecs-pratice-task-a.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = var.subnets                            # Replace with your subnet IDs
    security_groups  = [aws_security_group.ecs-service_sg.id] # Replace with your security group ID
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.ecs_target_group.arn
    container_name   = "app-container"
    container_port   = 80
  }

  depends_on = [
    aws_iam_role_policy_attachment.ecs_execution_policy,
    aws_iam_role_policy_attachment.ecs_cloudwatch_policy,
    aws_iam_role_policy_attachment.ecs_ecr_policy,
    aws_iam_policy_attachment.ecs_secrets_policy
  ]
}

resource "aws_ecs_service" "service_b" {
  name            = "ecs-secert-service-b"
  cluster         = aws_ecs_cluster.ecs-pratice-cluster.id
  task_definition = aws_ecs_task_definition.ecs-pratice-task-b.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = var.subnets                            # Replace with your subnet IDs
    security_groups  = [aws_security_group.ecs-service_sg.id] # Replace with your security group ID
    assign_public_ip = true
  }

  service_registries {
    registry_arn = aws_service_discovery_service.backend_discovery.arn
  }

  depends_on = [
    aws_iam_role_policy_attachment.ecs_execution_policy,
    aws_iam_role_policy_attachment.ecs_cloudwatch_policy,
    aws_iam_role_policy_attachment.ecs_ecr_policy,
    aws_iam_policy_attachment.ecs_secrets_policy
  ]
}


resource "aws_ecs_task_definition" "blue" {
  family                   = "blue"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.ecs_execution.arn
  container_definitions = jsonencode([
    {
      name      = "blue-container"
      image     = "${aws_ecr_repository.blue.repository_url}:latest"
      essential = true
      portMappings = [
        {
          containerPort = 80
          hostPort      = 80
          protocol      = "tcp"
        }
      ]
    }
  ])
}

resource "aws_ecs_task_definition" "red" {
  family                   = "red"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.ecs_execution.arn
  container_definitions = jsonencode([
    {
      name      = "red-container"
      image     = "${aws_ecr_repository.red.repository_url}:latest"
      essential = true
      portMappings = [
        {
          containerPort = 80
          hostPort      = 80
          protocol      = "tcp"
        }
      ]
    }
  ])
}

resource "aws_ecs_service" "blue" {
  name            = "blue"
  cluster         = aws_ecs_cluster.ecs-pratice-cluster.id
  task_definition = aws_ecs_task_definition.blue.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = var.subnets                            # Replace with your subnet IDs
    security_groups  = [aws_security_group.ecs-service_sg.id] # Replace with your security group ID
    assign_public_ip = true
  }
  load_balancer {
    target_group_arn = aws_lb_target_group.blue_tg.arn
    container_name   = "blue-container"
    container_port   = 80
  }

  depends_on = [
    aws_iam_role_policy_attachment.ecs_execution_policy,
    aws_iam_role_policy_attachment.ecs_cloudwatch_policy,
    aws_iam_role_policy_attachment.ecs_ecr_policy,
    aws_iam_policy_attachment.ecs_secrets_policy
  ]
}

resource "aws_ecs_service" "red" {
  name            = "red"
  cluster         = aws_ecs_cluster.ecs-pratice-cluster.id
  task_definition = aws_ecs_task_definition.red.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = var.subnets                            # Replace with your subnet IDs
    security_groups  = [aws_security_group.ecs-service_sg.id] # Replace with your security group ID
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.red_tg.arn
    container_name   = "red-container"
    container_port   = 80
  }

  depends_on = [
    aws_iam_role_policy_attachment.ecs_execution_policy,
    aws_iam_role_policy_attachment.ecs_cloudwatch_policy,
    aws_iam_role_policy_attachment.ecs_ecr_policy,
    aws_iam_policy_attachment.ecs_secrets_policy
  ]
}
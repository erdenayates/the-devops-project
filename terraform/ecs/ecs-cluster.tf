resource "aws_ecs_cluster" "app_cluster" {
  name = "app-cluster"

  tags = {
    Name = "app-cluster"
  }
}

resource "aws_ecs_task_definition" "app_task" {
  family                   = "app-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"  # You can modify these as required
  memory                   = "512"  # You can modify these as required
  execution_role_arn       = aws_iam_role.ecs_execution_role.arn

  container_definitions = jsonencode([{
    name  = "app-container"
    image = "public.ecr.aws/h2n4d7m6/backend:latest"
    portMappings = [{
      containerPort = 80
      hostPort      = 80
    }]
  }])
}

resource "aws_iam_role" "ecs_service_role" {
  name = "ecs-service-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Principal = {
          Service = "ecs.amazonaws.com"
        },
        Effect = "Allow",
      }
    ]
  })

  tags = {
    Name = "ecs-service-role"
  }
}

resource "aws_iam_role_policy_attachment" "ecs_service_role_attachment" {
  role       = aws_iam_role.ecs_service_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceRole"
}

resource "aws_iam_role" "ecs_execution_role" {
  name = "ecs-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        },
        Effect = "Allow",
      }
    ]
  })

  tags = {
    Name = "ecs-execution-role"
  }
}

resource "aws_iam_role_policy_attachment" "ecs_execution_role_attachment" {
  role       = aws_iam_role.ecs_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_security_group" "ecs_sg" {
  name        = "ecs-sg"
  description = "ECS Security Group"
  vpc_id      = data.aws_vpc.main-vpc.id

  tags = {
    Name = "ecs-sg"
  }
}


resource "aws_security_group_rule" "ecs_inbound_rule_http" {
  type        = "ingress"
  from_port   = 80
  to_port     = 80
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]

  security_group_id = aws_security_group.ecs_sg.id
}

resource "aws_security_group_rule" "ecs_inbound_rule_https" {
  type        = "ingress"
  from_port   = 443
  to_port     = 443
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]

  security_group_id = aws_security_group.ecs_sg.id
}

resource "aws_security_group_rule" "ecs_outbound_rule" {
  type        = "egress"
  from_port   = 0   # Allow all ports
  to_port     = 0   # Allow all ports
  protocol    = "-1" # Allow all protocols
  cidr_blocks = ["0.0.0.0/0"]

  security_group_id = aws_security_group.ecs_sg.id
}


resource "aws_ecs_service" "app_service" {
  name            = "app-service"
  cluster         = aws_ecs_cluster.app_cluster.id
  task_definition = aws_ecs_task_definition.app_task.arn
  launch_type     = "FARGATE"

  desired_count = 1

  network_configuration {
    security_groups  = [aws_security_group.ecs_sg.id]
    subnets          = [data.aws_subnet.app_private_subnet_1.id, data.aws_subnet.app_private_subnet_2.id, data.aws_subnet.app_private_subnet_3.id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.app_tg.arn
    container_name   = "app-container"
    container_port   = 80
  }

  tags = {
    Name = "app-service"
  }
}

data "aws_subnet" "app_private_subnet_1" {
  filter {
    name   = "tag:Name"
    values = ["app-private-subnet-1"]
  }
}

data "aws_subnet" "app_private_subnet_2" {
  filter {
    name   = "tag:Name"
    values = ["app-private-subnet-2"]
  }
}

data "aws_subnet" "app_private_subnet_3" {
  filter {
    name   = "tag:Name"
    values = ["app-private-subnet-3"]
  }
}

data "aws_vpc" "main-vpc" {
  filter {
    name   = "tag:Name"
    values = ["main-vpc"]
  }
}

resource "aws_lb" "app_alb" {
  name               = "app-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.ecs_sg.id]
  enable_deletion_protection = false

  subnets = [
    data.aws_subnet.app_public_subnet_1.id,
    data.aws_subnet.app_public_subnet_2.id,
    data.aws_subnet.app_public_subnet_3.id
  ]

  enable_cross_zone_load_balancing = true

  tags = {
    Name = "app-alb"
  }
}

resource "aws_lb_target_group" "app_tg" {
  name     = "app-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.main-vpc.id
  target_type = "ip"

  health_check {
    enabled             = true
    interval            = 30
    path                = "/"
    port                = "80"
    protocol            = "HTTP"
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}


resource "aws_lb_listener" "app_lb_listener" {
  load_balancer_arn = aws_lb.app_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app_tg.arn
  }
}

data "aws_subnet" "app_public_subnet_1" {
  filter {
    name   = "tag:Name"
    values = ["public-subnet-1"]
  }
}

data "aws_subnet" "app_public_subnet_2" {
  filter {
    name   = "tag:Name"
    values = ["public-subnet-2"]
  }
}

data "aws_subnet" "app_public_subnet_3" {
  filter {
    name   = "tag:Name"
    values = ["public-subnet-3"]
  }
}

terraform {
  backend "s3" {
    bucket         = "the-lazy-devops-project-tfstate-bucket"
    key            = "terraform/ecs/terraform.tfstate"
    region         = "us-east-2"
    encrypt        = true
    dynamodb_table = "the-lazy-devops-project-tfstate-lock"
  }
}

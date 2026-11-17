resource "aws_mq_broker" "main" {
  broker_name = "${var.project_name}-${var.environment}-mq"

  engine_type         = "ActiveMQ"
  engine_version      = var.mq_engine_version
  host_instance_type  = var.mq_broker_instance_type
  deployment_mode     = var.environment == "prod" ? "ACTIVE_STANDBY_MULTI_AZ" : "SINGLE_INSTANCE"
  publicly_accessible = false
  subnet_ids          = var.environment == "prod" ? slice(aws_subnet.private[*].id, 0, 2) : [aws_subnet.private[0].id]
  security_groups     = [aws_security_group.mq.id]

  auto_minor_version_upgrade = true
  apply_immediately          = var.environment != "prod"

  user {
    username = "mqadmin"
    password = random_password.mq_password.result
  }

  encryption_options {
    use_aws_owned_key = true
  }

  logs {
    general = true
    audit   = var.environment == "prod"
  }

  tags = { Name = "${var.project_name}-mq-broker" }
}

resource "random_password" "mq_password" {
  length  = 24
  special = true
}

resource "aws_security_group" "mq" {
  name_prefix = "${var.project_name}-mq-"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port       = 61617
    to_port         = 61617
    protocol        = "tcp"
    security_groups = [aws_security_group.app.id]
    description     = "OpenWire over SSL"
  }

  ingress {
    from_port       = 8162
    to_port         = 8162
    protocol        = "tcp"
    security_groups = [aws_security_group.app.id]
    description     = "Web console"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.project_name}-mq-sg" }

  lifecycle { create_before_destroy = true }
}

resource "aws_db_instance" "oracle" {
  identifier     = "${var.project_name}-${var.environment}-oracle"
  engine         = "oracle-ee"
  engine_version = var.oracle_engine_version
  instance_class = var.oracle_instance_class
  license_model  = "bring-your-own-license"

  allocated_storage     = var.oracle_allocated_storage
  max_allocated_storage = var.oracle_allocated_storage * 2
  storage_type          = "gp3"
  storage_encrypted     = true

  db_name  = "APPDB"
  username = "oraadmin"
  manage_master_user_password = true

  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.oracle.id]
  multi_az               = var.environment == "prod"
  publicly_accessible    = false

  backup_retention_period = var.environment == "prod" ? 7 : 1
  deletion_protection     = var.environment == "prod"
  skip_final_snapshot     = var.environment != "prod"
  final_snapshot_identifier = var.environment == "prod" ? "${var.project_name}-oracle-final" : null

  performance_insights_enabled = var.environment == "prod"
  monitoring_interval          = var.environment == "prod" ? 60 : 0

  tags = { Name = "${var.project_name}-rds-oracle" }
}

resource "aws_security_group" "oracle" {
  name_prefix = "${var.project_name}-oracle-"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port       = 1521
    to_port         = 1521
    protocol        = "tcp"
    security_groups = [aws_security_group.app.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.project_name}-oracle-sg" }

  lifecycle { create_before_destroy = true }
}

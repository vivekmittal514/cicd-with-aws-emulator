resource "aws_rds_cluster" "aurora_postgresql" {
  cluster_identifier          = "${var.project_name}-${var.environment}-aurora-pg"
  engine                      = "aurora-postgresql"
  database_name               = "appdb"
  master_username             = "dbadmin"
  manage_master_user_password = true
  db_subnet_group_name        = aws_db_subnet_group.main.name
  vpc_security_group_ids      = [aws_security_group.aurora.id]
  storage_encrypted           = true
  deletion_protection         = var.environment == "prod"
  skip_final_snapshot         = var.environment != "prod"
  final_snapshot_identifier   = var.environment == "prod" ? "${var.project_name}-aurora-final" : null

  iam_database_authentication_enabled = true
  copy_tags_to_snapshot               = true
  enabled_cloudwatch_logs_exports     = ["postgresql"]

  lifecycle {
    ignore_changes = [global_cluster_identifier]
  }

  tags = { Name = "${var.project_name}-aurora-postgresql" }
}

resource "aws_rds_cluster_instance" "aurora_instances" {
  count                        = var.environment == "prod" ? 2 : 1
  identifier                   = "${var.project_name}-${var.environment}-aurora-${count.index}"
  cluster_identifier           = aws_rds_cluster.aurora_postgresql.id
  instance_class               = var.aurora_instance_class
  engine                       = aws_rds_cluster.aurora_postgresql.engine
  monitoring_interval          = 60
  monitoring_role_arn          = aws_iam_role.rds_enhanced_monitoring.arn
  performance_insights_enabled = true
}

resource "aws_iam_role" "rds_enhanced_monitoring" {
  name = "${var.project_name}-${var.environment}-rds-monitoring"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "monitoring.rds.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "rds_enhanced_monitoring" {
  role       = aws_iam_role.rds_enhanced_monitoring.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}

resource "aws_security_group" "aurora" {
  name_prefix = "${var.project_name}-aurora-"
  description = "Security group for Aurora PostgreSQL cluster"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "PostgreSQL from application layer"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.app.id]
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.project_name}-aurora-sg" }

  lifecycle { create_before_destroy = true }
}

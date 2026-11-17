resource "aws_rds_cluster" "aurora_postgresql" {
  cluster_identifier          = "${var.project_name}-${var.environment}-aurora-pg"
  engine                      = "aurora-postgresql"
  engine_version              = var.aurora_engine_version
  database_name               = "appdb"
  master_username             = "dbadmin"
  manage_master_user_password = true
  db_subnet_group_name        = aws_db_subnet_group.main.name
  vpc_security_group_ids      = [aws_security_group.aurora.id]
  storage_encrypted           = true
  deletion_protection         = var.environment == "prod"
  skip_final_snapshot         = var.environment != "prod"
  final_snapshot_identifier   = var.environment == "prod" ? "${var.project_name}-aurora-final" : null

  tags = { Name = "${var.project_name}-aurora-postgresql" }
}

resource "aws_rds_cluster_instance" "aurora_instances" {
  count              = var.environment == "prod" ? 2 : 1
  identifier         = "${var.project_name}-${var.environment}-aurora-${count.index}"
  cluster_identifier = aws_rds_cluster.aurora_postgresql.id
  instance_class     = var.aurora_instance_class
  engine             = aws_rds_cluster.aurora_postgresql.engine
  engine_version     = aws_rds_cluster.aurora_postgresql.engine_version
}

resource "aws_security_group" "aurora" {
  name_prefix = "${var.project_name}-aurora-"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.app.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.project_name}-aurora-sg" }

  lifecycle { create_before_destroy = true }
}

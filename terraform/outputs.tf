output "vpc_id" {
  value = aws_vpc.main.id
}

output "aurora_cluster_endpoint" {
  value = aws_rds_cluster.aurora_postgresql.endpoint
}

output "aurora_reader_endpoint" {
  value = aws_rds_cluster.aurora_postgresql.reader_endpoint
}

output "oracle_endpoint" {
  value = aws_db_instance.oracle.endpoint
}

output "eks_cluster_name" {
  value = aws_eks_cluster.main.name
}

output "eks_cluster_endpoint" {
  value = aws_eks_cluster.main.endpoint
}

output "mq_broker_id" {
  value = aws_mq_broker.main.id
}

output "mq_broker_endpoints" {
  value = aws_mq_broker.main.instances[*].endpoints
}

output "s3_app_data_bucket" {
  value = aws_s3_bucket.app_data.id
}

output "s3_artifacts_bucket" {
  value = aws_s3_bucket.artifacts.id
}

output "linux_instance_id" {
  value = aws_instance.linux.id
}

output "windows_instance_id" {
  value = aws_instance.windows.id
}

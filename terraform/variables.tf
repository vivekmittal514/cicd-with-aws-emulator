variable "aws_region" {
  description = "AWS region for all resources"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Deployment environment"
  type        = string
  default     = "dev"
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Must be dev, staging, or prod."
  }
}

variable "project_name" {
  description = "Project name used in resource naming"
  type        = string
  default     = "cicd-emulator"
}

variable "state_bucket" {
  description = "S3 bucket for Terraform state"
  type        = string
  default     = ""
}

variable "state_lock_table" {
  description = "DynamoDB table for state locking"
  type        = string
  default     = ""
}

# VPC
variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "AZs for multi-AZ resources"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b", "us-east-1c"]
}

# Aurora
variable "aurora_instance_class" {
  description = "Aurora PostgreSQL instance class"
  type        = string
  default     = "db.r6g.large"
}

variable "aurora_engine_version" {
  description = "Aurora PostgreSQL engine version"
  type        = string
  default     = "15.4"
}

# RDS Oracle
variable "oracle_instance_class" {
  description = "RDS Oracle instance class"
  type        = string
  default     = "db.m5.large"
}

variable "oracle_engine_version" {
  description = "Oracle engine version"
  type        = string
  default     = "19.0.0.0.ru-2024-01.rur-2024-01.r1"
}

variable "oracle_allocated_storage" {
  description = "Allocated storage in GB for Oracle"
  type        = number
  default     = 100
}

# EKS
variable "eks_cluster_version" {
  description = "Kubernetes version for EKS"
  type        = string
  default     = "1.29"
}

variable "eks_node_instance_types" {
  description = "Instance types for EKS managed node group"
  type        = list(string)
  default     = ["t3.medium"]
}

variable "eks_desired_capacity" {
  description = "Desired number of EKS worker nodes"
  type        = number
  default     = 2
}

# EC2
variable "ec2_linux_instance_type" {
  description = "Instance type for Linux EC2"
  type        = string
  default     = "t3.micro"
}

variable "ec2_windows_instance_type" {
  description = "Instance type for Windows EC2"
  type        = string
  default     = "t3.medium"
}

# Amazon MQ
variable "mq_broker_instance_type" {
  description = "Amazon MQ broker instance type"
  type        = string
  default     = "mq.t3.micro"
}

variable "mq_engine_version" {
  description = "Amazon MQ (ActiveMQ) engine version"
  type        = string
  default     = "5.17.6"
}

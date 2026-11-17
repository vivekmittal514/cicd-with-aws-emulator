import os
import boto3
import pytest


@pytest.fixture(scope="session")
def aws_session():
    """Create a boto3 session pointed at the AWS Emulator."""
    return boto3.Session(region_name=os.environ.get("AWS_REGION", "us-east-1"))


@pytest.fixture(scope="session")
def s3_client(aws_session):
    return aws_session.client("s3")


@pytest.fixture(scope="session")
def ec2_client(aws_session):
    return aws_session.client("ec2")


@pytest.fixture(scope="session")
def rds_client(aws_session):
    return aws_session.client("rds")


@pytest.fixture(scope="session")
def eks_client(aws_session):
    return aws_session.client("eks")


@pytest.fixture(scope="session")
def mq_client(aws_session):
    return aws_session.client("mq")


@pytest.fixture(scope="session")
def sts_client(aws_session):
    return aws_session.client("sts")

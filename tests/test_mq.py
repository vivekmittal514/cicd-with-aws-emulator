"""Integration tests for Amazon MQ against AWS Emulator."""
import uuid
import pytest
from botocore.exceptions import ClientError


def test_create_mq_broker(mq_client):
    broker_name = f"test-mq-{uuid.uuid4().hex[:8]}"
    response = mq_client.create_broker(
        BrokerName=broker_name,
        EngineType="ACTIVEMQ",
        EngineVersion="5.17.6",
        HostInstanceType="mq.t3.micro",
        DeploymentMode="SINGLE_INSTANCE",
        PubliclyAccessible=False,
        Users=[{
            "Username": "testadmin",
            "Password": "TestPassword123!",
        }],
    )
    assert response["BrokerId"] is not None
    assert response["BrokerArn"] is not None


def test_list_brokers(mq_client):
    response = mq_client.list_brokers()
    assert "BrokerSummaries" in response

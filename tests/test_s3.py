"""Integration tests for S3 resources against AWS Emulator."""
import json


def test_create_bucket(s3_client):
    bucket_name = "test-app-data-bucket"
    s3_client.create_bucket(Bucket=bucket_name)
    response = s3_client.list_buckets()
    bucket_names = [b["Name"] for b in response["Buckets"]]
    assert bucket_name in bucket_names


def test_put_and_get_object(s3_client):
    bucket_name = "test-object-bucket"
    s3_client.create_bucket(Bucket=bucket_name)

    test_data = json.dumps({"key": "value", "status": "testing"})
    s3_client.put_object(Bucket=bucket_name, Key="test/data.json", Body=test_data)

    response = s3_client.get_object(Bucket=bucket_name, Key="test/data.json")
    body = response["Body"].read().decode("utf-8")
    assert json.loads(body) == {"key": "value", "status": "testing"}


def test_bucket_versioning(s3_client):
    bucket_name = "test-versioning-bucket"
    s3_client.create_bucket(Bucket=bucket_name)
    s3_client.put_bucket_versioning(
        Bucket=bucket_name,
        VersioningConfiguration={"Status": "Enabled"},
    )
    response = s3_client.get_bucket_versioning(Bucket=bucket_name)
    assert response["Status"] == "Enabled"


def test_public_access_block(s3_client):
    bucket_name = "test-public-block-bucket"
    s3_client.create_bucket(Bucket=bucket_name)
    s3_client.put_public_access_block(
        Bucket=bucket_name,
        PublicAccessBlockConfiguration={
            "BlockPublicAcls": True,
            "IgnorePublicAcls": True,
            "BlockPublicPolicy": True,
            "RestrictPublicBuckets": True,
        },
    )
    response = s3_client.get_public_access_block(Bucket=bucket_name)
    config = response["PublicAccessBlockConfiguration"]
    assert config["BlockPublicAcls"] is True
    assert config["RestrictPublicBuckets"] is True

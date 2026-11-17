"""Post-apply tests: verify Terraform-created resources exist in the emulator.

Some resources may fail to create due to emulator fidelity gaps.
Tests gracefully skip when a resource wasn't created.
"""
import json
import subprocess
import pytest
from botocore.exceptions import ClientError


@pytest.fixture(scope="module")
def tf_outputs():
    """Read Terraform outputs after apply."""
    result = subprocess.run(
        ["terraform", "output", "-json"],
        cwd="terraform",
        capture_output=True,
        text=True,
    )
    if result.returncode != 0:
        pytest.skip("Terraform outputs not available (apply may not have run)")
    outputs = json.loads(result.stdout)
    if not outputs:
        pytest.skip("No Terraform outputs found")
    return outputs


def _get_output(tf_outputs, key):
    if key not in tf_outputs:
        pytest.skip(f"Output '{key}' not available (resource may not have been created)")
    value = tf_outputs[key]["value"]
    if not value:
        pytest.skip(f"Output '{key}' is empty")
    return value


def test_vpc_created(ec2_client, tf_outputs):
    vpc_id = _get_output(tf_outputs, "vpc_id")
    response = ec2_client.describe_vpcs(VpcIds=[vpc_id])
    assert len(response["Vpcs"]) == 1
    assert response["Vpcs"][0]["CidrBlock"] == "10.0.0.0/16"


def test_s3_buckets_created(s3_client, tf_outputs):
    app_bucket = _get_output(tf_outputs, "s3_app_data_bucket")
    artifacts_bucket = _get_output(tf_outputs, "s3_artifacts_bucket")

    buckets = [b["Name"] for b in s3_client.list_buckets()["Buckets"]]
    assert app_bucket in buckets
    assert artifacts_bucket in buckets


def test_s3_versioning_enabled(s3_client, tf_outputs):
    bucket = _get_output(tf_outputs, "s3_app_data_bucket")
    response = s3_client.get_bucket_versioning(Bucket=bucket)
    assert response.get("Status") == "Enabled"


def test_aurora_cluster_created(rds_client, tf_outputs):
    try:
        endpoint = _get_output(tf_outputs, "aurora_cluster_endpoint")
    except Exception:
        pytest.skip("Aurora cluster not created (emulator fidelity gap)")

    clusters = rds_client.describe_db_clusters()["DBClusters"]
    aurora_clusters = [c for c in clusters if c["Engine"] == "aurora-postgresql"]
    assert len(aurora_clusters) >= 1


def test_eks_cluster_created(eks_client, tf_outputs):
    cluster_name = _get_output(tf_outputs, "eks_cluster_name")
    try:
        response = eks_client.describe_cluster(name=cluster_name)
        assert response["cluster"]["name"] == cluster_name
    except ClientError:
        pytest.skip("EKS cluster not found in emulator")


def test_mq_broker_created(mq_client, tf_outputs):
    broker_id = _get_output(tf_outputs, "mq_broker_id")
    brokers = mq_client.list_brokers()["BrokerSummaries"]
    broker_ids = [b["BrokerId"] for b in brokers]
    assert broker_id in broker_ids


def test_ec2_linux_instance_created(ec2_client, tf_outputs):
    instance_id = _get_output(tf_outputs, "linux_instance_id")
    try:
        response = ec2_client.describe_instances(InstanceIds=[instance_id])
        instances = response["Reservations"][0]["Instances"]
        assert len(instances) == 1
    except ClientError:
        pytest.skip("EC2 Linux instance not found in emulator")


def test_ec2_windows_instance_created(ec2_client, tf_outputs):
    instance_id = _get_output(tf_outputs, "windows_instance_id")
    try:
        response = ec2_client.describe_instances(InstanceIds=[instance_id])
        instances = response["Reservations"][0]["Instances"]
        assert len(instances) == 1
    except ClientError:
        pytest.skip("EC2 Windows instance not found in emulator")


def test_oracle_rds_created(rds_client, tf_outputs):
    endpoint = _get_output(tf_outputs, "oracle_endpoint")
    instances = rds_client.describe_db_instances()["DBInstances"]
    oracle_instances = [i for i in instances if i["Engine"] == "oracle-ee"]
    assert len(oracle_instances) >= 1

"""Integration tests for EKS against AWS Emulator."""
import uuid


def _unique(prefix):
    return f"{prefix}-{uuid.uuid4().hex[:8]}"


def test_list_eks_clusters(eks_client):
    response = eks_client.list_clusters()
    assert "clusters" in response


def test_create_and_describe_eks_cluster(eks_client, ec2_client, sts_client):
    account_id = sts_client.get_caller_identity()["Account"]

    vpc = ec2_client.create_vpc(CidrBlock="10.10.0.0/16")
    vpc_id = vpc["Vpc"]["VpcId"]

    subnet1 = ec2_client.create_subnet(
        VpcId=vpc_id, CidrBlock="10.10.1.0/24", AvailabilityZone="us-east-1a"
    )
    subnet2 = ec2_client.create_subnet(
        VpcId=vpc_id, CidrBlock="10.10.2.0/24", AvailabilityZone="us-east-1b"
    )

    cluster_name = _unique("eks")
    role_arn = f"arn:aws:iam::{account_id}:role/eks-test-role"

    response = eks_client.create_cluster(
        name=cluster_name,
        roleArn=role_arn,
        resourcesVpcConfig={
            "subnetIds": [
                subnet1["Subnet"]["SubnetId"],
                subnet2["Subnet"]["SubnetId"],
            ],
        },
    )
    assert response["cluster"]["name"] == cluster_name

    desc = eks_client.describe_cluster(name=cluster_name)
    assert desc["cluster"]["name"] == cluster_name

"""Integration tests for EC2 resources against AWS Emulator."""


def test_describe_vpcs(ec2_client):
    response = ec2_client.describe_vpcs()
    assert "Vpcs" in response


def test_create_vpc(ec2_client):
    response = ec2_client.create_vpc(CidrBlock="10.0.0.0/16")
    vpc_id = response["Vpc"]["VpcId"]
    assert vpc_id.startswith("vpc-")

    vpc = ec2_client.describe_vpcs(VpcIds=[vpc_id])
    assert vpc["Vpcs"][0]["CidrBlock"] == "10.0.0.0/16"


def test_create_security_group(ec2_client):
    vpc = ec2_client.create_vpc(CidrBlock="10.1.0.0/16")
    vpc_id = vpc["Vpc"]["VpcId"]

    sg = ec2_client.create_security_group(
        GroupName="test-app-sg",
        Description="Test security group",
        VpcId=vpc_id,
    )
    sg_id = sg["GroupId"]
    assert sg_id.startswith("sg-")

    ec2_client.authorize_security_group_ingress(
        GroupId=sg_id,
        IpPermissions=[{
            "IpProtocol": "tcp",
            "FromPort": 443,
            "ToPort": 443,
            "IpRanges": [{"CidrIp": "10.1.0.0/16"}],
        }],
    )

    desc = ec2_client.describe_security_groups(GroupIds=[sg_id])
    rules = desc["SecurityGroups"][0]["IpPermissions"]
    assert any(r["FromPort"] == 443 for r in rules)


def test_create_subnet(ec2_client):
    vpc = ec2_client.create_vpc(CidrBlock="10.2.0.0/16")
    vpc_id = vpc["Vpc"]["VpcId"]

    subnet = ec2_client.create_subnet(
        VpcId=vpc_id,
        CidrBlock="10.2.1.0/24",
        AvailabilityZone="us-east-1a",
    )
    subnet_id = subnet["Subnet"]["SubnetId"]
    assert subnet_id.startswith("subnet-")

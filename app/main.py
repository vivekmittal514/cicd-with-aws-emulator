"""Sample application that uses the provisioned AWS resources."""
import os
import boto3
import json


def get_session():
    return boto3.Session(region_name=os.environ.get("AWS_REGION", "us-east-1"))


def check_s3():
    s3 = get_session().client("s3")
    buckets = s3.list_buckets()["Buckets"]
    return {"service": "s3", "status": "ok", "bucket_count": len(buckets)}


def check_rds():
    rds = get_session().client("rds")
    clusters = rds.describe_db_clusters()["DBClusters"]
    return {"service": "aurora-postgresql", "status": "ok", "cluster_count": len(clusters)}


def check_ec2():
    ec2 = get_session().client("ec2")
    instances = ec2.describe_instances()["Reservations"]
    return {"service": "ec2", "status": "ok", "reservation_count": len(instances)}


def check_eks():
    eks = get_session().client("eks")
    clusters = eks.list_clusters()["clusters"]
    return {"service": "eks", "status": "ok", "cluster_count": len(clusters)}


def check_mq():
    mq = get_session().client("mq")
    brokers = mq.list_brokers()["BrokerSummaries"]
    return {"service": "mq", "status": "ok", "broker_count": len(brokers)}


def health_check():
    results = []
    for check in [check_s3, check_rds, check_ec2, check_eks, check_mq]:
        try:
            results.append(check())
        except Exception as e:
            results.append({
                "service": check.__name__.replace("check_", ""),
                "status": "error",
                "error": str(e),
            })
    return results


if __name__ == "__main__":
    print(json.dumps(health_check(), indent=2))

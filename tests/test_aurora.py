"""Integration tests for Aurora PostgreSQL against AWS Emulator."""
import uuid


def _unique(prefix):
    return f"{prefix}-{uuid.uuid4().hex[:8]}"


def test_create_aurora_cluster(rds_client):
    cluster_id = _unique("aurora-pg")
    response = rds_client.create_db_cluster(
        DBClusterIdentifier=cluster_id,
        Engine="aurora-postgresql",
        MasterUsername="testadmin",
        MasterUserPassword="TestPassword123!",
        DatabaseName="testdb",
    )
    cluster = response["DBCluster"]
    assert cluster["DBClusterIdentifier"] == cluster_id
    assert cluster["Engine"] == "aurora-postgresql"


def test_describe_aurora_clusters(rds_client):
    response = rds_client.describe_db_clusters()
    assert "DBClusters" in response
    assert len(response["DBClusters"]) > 0


def test_create_aurora_instance(rds_client):
    cluster_id = _unique("aurora-inst")
    rds_client.create_db_cluster(
        DBClusterIdentifier=cluster_id,
        Engine="aurora-postgresql",
        MasterUsername="testadmin",
        MasterUserPassword="TestPassword123!",
        DatabaseName="testdb",
    )
    instance_id = _unique("aurora-inst")
    response = rds_client.create_db_instance(
        DBInstanceIdentifier=instance_id,
        DBClusterIdentifier=cluster_id,
        Engine="aurora-postgresql",
        DBInstanceClass="db.r6g.large",
    )
    assert response["DBInstance"]["DBInstanceIdentifier"] == instance_id

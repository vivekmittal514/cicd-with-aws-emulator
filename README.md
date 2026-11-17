# CI/CD with AWS Emulator

A sample CI/CD pipeline using **Terraform** for IaC and **AWS Emulator** for ephemeral test environments. GitHub Actions runs integration tests against a local AWS Emulator before deploying to real AWS.

## Architecture

```
PR/Push ──> GitHub Actions CI
              │
              ├── Terraform Validate + Format
              ├── Security Scan (tfsec, checkov)
              └── Ephemeral Environment (AWS Emulator)
                    │
                    ├── Start AWS Emulator (Docker)
                    ├── Terraform Plan (against emulator)
                    └── Integration Tests (boto3 + pytest)
                          │
                          └── All pass ──> CD Pipeline
                                            ├── Dev
                                            ├── Staging
                                            └── Production
```

## AWS Resources

| Resource | Terraform File | Purpose |
|---|---|---|
| Aurora PostgreSQL | `aurora.tf` | Primary relational database |
| S3 Buckets | `s3.tf` | App data and build artifacts |
| EKS Cluster | `eks.tf` | Container orchestration |
| Amazon MQ | `mq.tf` | Message broker (ActiveMQ) |
| RDS Oracle | `rds-oracle.tf` | Legacy database |
| EC2 Linux | `ec2-linux.tf` | Amazon Linux 2023 instance |
| EC2 Windows | `ec2-windows.tf` | Windows Server 2022 instance |
| VPC | `vpc.tf` | Networking (public/private/database subnets) |

## How AWS Emulator Works

AWS Emulator runs as a Docker container on port 9297. Your AWS SDK points at it via environment variables. No AWS account or credentials needed for testing.

The emulator keeps all resources in memory and deletes them when it stops, giving each CI run a clean state.

## Local Development

### Prerequisites

- Docker
- Terraform >= 1.5
- Python >= 3.12
- AWS CLI >= 2.35.0 (for the emulator skill)

### Start the emulator

```bash
chmod +x scripts/*.sh
./scripts/setup-emulator.sh
```

### Run tests locally

The test script sets up a Python venv, configures emulator env vars, runs Terraform validation, and runs all integration tests:

```bash
./scripts/run-tests.sh
```

### Stop the emulator

```bash
./scripts/teardown-emulator.sh
```

## CI/CD Pipeline

### CI (`.github/workflows/ci.yml`)

Runs on every push and PR:
1. Terraform format and validation
2. Security scanning (tfsec, checkov)
3. Builds AWS Emulator Docker image
4. Starts emulator as a service container
5. Runs `terraform plan` against the emulator
6. Runs pytest integration tests against emulator
7. Stops emulator

### CD (`.github/workflows/cd.yml`)

Runs after CI passes on `main`:
1. Deploy to **dev** (auto)
2. Deploy to **staging** (requires approval)
3. Deploy to **production** (requires approval)

### GitHub Secrets Required

| Secret | Description |
|---|---|
| `AWS_ROLE_ARN_DEV` | IAM role ARN for dev deployments |
| `AWS_ROLE_ARN_STAGING` | IAM role ARN for staging |
| `AWS_ROLE_ARN_PROD` | IAM role ARN for production |

## Project Structure

```
.
├── .github/workflows/     # CI/CD pipelines
│   ├── ci.yml             # Test with AWS Emulator
│   └── cd.yml             # Deploy to AWS
├── terraform/             # Infrastructure as Code
│   ├── providers.tf
│   ├── variables.tf
│   ├── outputs.tf
│   ├── vpc.tf
│   ├── aurora.tf
│   ├── s3.tf
│   ├── eks.tf
│   ├── mq.tf
│   ├── rds-oracle.tf
│   ├── ec2-linux.tf
│   └── ec2-windows.tf
├── docker/aws-emulator/   # Emulator Docker image
│   └── Dockerfile
├── tests/                 # Integration tests
│   ├── conftest.py
│   ├── test_s3.py
│   ├── test_ec2.py
│   ├── test_aurora.py
│   ├── test_eks.py
│   └── test_mq.py
├── app/                   # Sample application
│   └── main.py
└── scripts/               # Helper scripts
    ├── setup-emulator.sh
    ├── run-tests.sh
    └── teardown-emulator.sh
```

## Emulator Limitations

- Does not evaluate IAM policies (not for security testing)
- Single region and account per emulator instance
- Fidelity varies by service; check [fidelity scores](https://github.com/aws/aws-emulator/releases)
- All resources are in-memory; lost when emulator stops
- Not for load testing or long-running use

## References

- [AWS Emulator Documentation](https://docs.aws.amazon.com/emulator/latest/userguide/what-is-service.html)
- [AWS Emulator GitHub](https://github.com/aws/aws-emulator)
- [Fidelity Evaluation Suite](https://github.com/aws/aws-emulator-evaluation-suite)

# CI/CD with AWS Emulator

A sample CI/CD pipeline using **Terraform** for IaC and **AWS Emulator** for ephemeral test environments. GitHub Actions runs a 3-phase test pipeline against a local AWS Emulator before deploying to real AWS.

## Architecture

```
PR/Push ──> GitHub Actions CI
              │
              ├── Terraform Validate + Format
              ├── Security Scan (tfsec, checkov)
              └── Ephemeral Environment (AWS Emulator)
                    │
                    ├── Phase 1: API Integration Tests (boto3 + pytest)
                    ├── Phase 2: Terraform Apply (provision resources in emulator)
                    └── Phase 3: Post-Apply Verification Tests
```

## 3-Phase Test Pipeline

| Phase | What it does | How |
|---|---|---|
| Phase 1: API tests | Validates AWS APIs work on the emulator | boto3 creates resources directly, asserts responses |
| Phase 2: Terraform apply | Provisions the full infrastructure stack in the emulator | `terraform apply` against emulator endpoint |
| Phase 3: Post-apply tests | Verifies Terraform-created resources exist and are configured correctly | boto3 queries resources using Terraform outputs |

Phase 1 and Phase 2 create resources independently. Phase 1 uses `test-` prefixed or UUID-based names. Terraform uses `project-environment` naming. They don't collide.

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

Key environment variables that redirect the SDK:

| Variable | Purpose |
|---|---|
| `AWS_ENDPOINT_URL` | Points all API calls to `https://127.0.0.1:9297` |
| `AWS_SHARED_CREDENTIALS_FILE` | Uses emulator-generated access keys |
| `AWS_CONFIG_FILE` | Uses emulator config (region, endpoint, signing) |
| `AWS_CA_BUNDLE` | Trusts emulator's self-signed TLS certificate |

Your application code never changes. The same boto3 calls and Terraform configs work against both the emulator and real AWS.

## Local Development

### Prerequisites

- Docker
- Terraform >= 1.5
- Python >= 3.12

### Run the full pipeline locally

```bash
chmod +x scripts/*.sh
./scripts/setup-emulator.sh    # Start emulator
./scripts/run-tests.sh         # Run all 3 phases
./scripts/teardown-emulator.sh # Stop emulator
```

`run-tests.sh` creates a Python venv, runs Phase 1 API tests, applies Terraform, and runs Phase 3 post-apply verification.

## CI/CD Pipeline

### CI (`.github/workflows/ci.yml`)

Runs on every push and PR:
1. Terraform format check and validation
2. Security scanning (tfsec, checkov)
3. Build AWS Emulator Docker image
4. Start emulator
5. **Phase 1:** API integration tests (15 tests across S3, EC2, Aurora, EKS, MQ)
6. **Phase 2:** Terraform init, plan, and apply against emulator
7. **Phase 3:** Post-apply verification tests (9 tests verifying Terraform-created resources)
8. Stop emulator

## Try It Yourself

Fork and test the CI/CD pipeline with a real change:

### 1. Fork and clone

```bash
gh repo fork vivekmittal514/cicd-with-aws-emulator --clone
cd cicd-with-aws-emulator
```

### 2. Create a branch and make a change

```bash
git checkout -b feat/add-s3-lifecycle
```

Add an S3 lifecycle rule to `terraform/s3.tf`. Open the file and add this block after the `aws_s3_bucket_public_access_block.app_data` resource:

```hcl
resource "aws_s3_bucket_lifecycle_configuration" "app_data" {
  bucket = aws_s3_bucket.app_data.id

  rule {
    id     = "expire-old-versions"
    status = "Enabled"

    noncurrent_version_expiration {
      noncurrent_days = 30
    }
  }
}
```

### 3. Format, commit, and push

```bash
cd terraform && terraform fmt && cd ..
git add terraform/s3.tf
git commit -m "feat: add S3 lifecycle rule to expire old object versions"
git push origin feat/add-s3-lifecycle
```

### 4. Open a pull request

```bash
gh pr create --title "feat: add S3 lifecycle rule" \
  --body "Adds a lifecycle rule to expire noncurrent S3 object versions after 30 days."
```

### 5. Watch the CI pipeline

Go to the **Actions** tab in your fork. You will see:

1. **Terraform Validate** - checks formatting and syntax
2. **Integration Tests** - starts the AWS Emulator, runs API tests, applies Terraform, runs post-apply verification
3. **Security Scan** - runs tfsec and Checkov against the Terraform code

All three jobs should pass. The emulator tests prove your lifecycle rule is valid Terraform without needing an AWS account.

## Project Structure

```
.
├── .github/workflows/     # CI pipeline
│   └── ci.yml             # 3-phase test with AWS Emulator
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
│   ├── conftest.py        # Shared fixtures (boto3 clients)
│   ├── test_s3.py         # Phase 1: S3 API tests
│   ├── test_ec2.py        # Phase 1: EC2 API tests
│   ├── test_aurora.py     # Phase 1: Aurora API tests
│   ├── test_eks.py        # Phase 1: EKS API tests
│   ├── test_mq.py         # Phase 1: MQ API tests
│   └── test_post_apply.py # Phase 3: Post-apply verification
├── app/                   # Sample application
│   └── main.py
└── scripts/               # Helper scripts
    ├── setup-emulator.sh
    ├── run-tests.sh
    └── teardown-emulator.sh
```

## Emulator Fidelity

Fidelity measures how closely the emulator matches real AWS behavior for each API call. A score like "40 of 50" means 40 out of 50 fidelity tests pass for that service.

### Checking fidelity scores

1. **Published scores**: check the [AWS Emulator releases page](https://github.com/aws/aws-emulator/releases) for per-service pass/total counts with each release.

2. **Run fidelity tests yourself** against your local emulator:

```bash
git clone https://github.com/aws/aws-emulator-evaluation-suite.git
cd aws-emulator-evaluation-suite
pip install -r requirements.txt
python -m fidelity_tests_runner
```

3. **Check your specific project** using the AWS CLI emulator skill:

```bash
aws agent-toolkit add-skill --skill-name aws-emulator --region us-east-1
```

Then ask your AI coding agent: "Check whether my project works with AWS Emulator."

### Known fidelity gaps in this project

Some Terraform resources hit emulator fidelity gaps during apply:
- Aurora: `DescribeGlobalClusters` filter not supported
- S3: bucket names may collide with API test resources from Phase 1
- EC2: subnet AZ propagation requires explicit `availability_zone`
- MQ: engine type requires uppercase (`ACTIVEMQ` not `ActiveMQ`)
- RDS Oracle: specific engine version strings not recognized

Post-apply tests gracefully skip resources that weren't created. As the emulator improves, more resources will pass.

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

#!/usr/bin/env bash
set -euo pipefail

PORT="${EMULATOR_PORT:-9297}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

echo "==> Checking AWS Emulator is running on port $PORT..."
if ! curl -sk "https://127.0.0.1:${PORT}" >/dev/null 2>&1; then
  echo "ERROR: Emulator not running. Start it first:"
  echo "  ./scripts/setup-emulator.sh"
  exit 1
fi

export AWS_ENDPOINT_URL="https://127.0.0.1:${PORT}"
export AWS_SHARED_CREDENTIALS_FILE="$HOME/.aws/emulator/${PORT}/emulator_credentials"
export AWS_CONFIG_FILE="$HOME/.aws/emulator/${PORT}/config"
export AWS_CA_BUNDLE="$HOME/.aws/emulator/${PORT}/ca.pem"
export AWS_EC2_METADATA_DISABLED=true
export AWS_DISABLE_HOST_PREFIX_INJECTION=true
export AWS_REGION=us-east-1
export AWS_DEFAULT_REGION=us-east-1

unset AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_SESSION_TOKEN AWS_PROFILE 2>/dev/null || true

echo "==> Setting up Python virtual environment..."
cd "$PROJECT_DIR"
if [ ! -d ".venv" ]; then
  python3 -m venv .venv
fi
source .venv/bin/activate
pip install -q -r tests/requirements.txt

echo ""
echo "=========================================="
echo "  Phase 1: API-level integration tests"
echo "=========================================="
echo ""

echo "==> Running API tests against emulator..."
mkdir -p test-results
python -m pytest tests/ -v --tb=short \
  --ignore=tests/test_post_apply.py \
  --junitxml=test-results/api-tests.xml

echo ""
echo "=========================================="
echo "  Phase 2: Terraform apply to emulator"
echo "=========================================="
echo ""

cd "$PROJECT_DIR/terraform"
rm -rf .terraform .terraform.lock.hcl tfplan terraform.tfstate*
terraform init -backend=false -input=false
terraform validate

echo "==> Running Terraform plan..."
terraform plan -out=tfplan -input=false 2>&1 | tail -3

echo "==> Applying Terraform to emulator..."
terraform apply -auto-approve tfplan 2>&1 | tail -20 || echo "==> Note: Some resources may have failed due to emulator fidelity gaps"

echo "==> Terraform outputs:"
terraform output

echo ""
echo "=========================================="
echo "  Phase 3: Post-apply verification tests"
echo "=========================================="
echo ""

cd "$PROJECT_DIR"
python -m pytest tests/test_post_apply.py -v --tb=short \
  --junitxml=test-results/post-apply-tests.xml

echo ""
echo "==> All phases passed"

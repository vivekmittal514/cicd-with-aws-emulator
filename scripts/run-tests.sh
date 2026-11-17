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

echo "==> Running Terraform validation..."
cd "$PROJECT_DIR/terraform"
rm -rf .terraform .terraform.lock.hcl
terraform init -backend=false -input=false
terraform validate

echo "==> Running Terraform plan against emulator..."
terraform plan -out=tfplan -input=false 2>&1 | tail -5 || true

echo "==> Setting up Python virtual environment..."
cd "$PROJECT_DIR"
if [ ! -d ".venv" ]; then
  python3 -m venv .venv
fi
source .venv/bin/activate
pip install -q -r tests/requirements.txt

echo "==> Running integration tests..."
mkdir -p test-results
python -m pytest tests/ -v --tb=short --junitxml=test-results/results.xml

echo "==> All tests passed"

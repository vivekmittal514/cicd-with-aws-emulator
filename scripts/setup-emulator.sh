#!/usr/bin/env bash
set -euo pipefail

PORT="${EMULATOR_PORT:-9297}"
EMULATOR_IMAGE="aws-emulator"
CONTAINER_NAME="aws-emulator-ci"

echo "==> Building AWS Emulator Docker image..."
docker build -t "$EMULATOR_IMAGE" "$(dirname "$0")/../docker/aws-emulator/"

echo "==> Starting AWS Emulator on port $PORT..."
mkdir -p "$HOME/.aws/emulator"
docker rm -f "$CONTAINER_NAME" 2>/dev/null || true

docker run -d --rm \
  --name "$CONTAINER_NAME" \
  --memory=2g --memory-swap=2g \
  -p "127.0.0.1:${PORT}:${PORT}" \
  -e HOME="$HOME" \
  -v "$HOME/.aws/emulator:$HOME/.aws/emulator" \
  "$EMULATOR_IMAGE" -p "$PORT"

echo "==> Waiting for emulator to be ready..."
MAX_RETRIES=30
for i in $(seq 1 "$MAX_RETRIES"); do
  if curl -sk "https://127.0.0.1:${PORT}" >/dev/null 2>&1; then
    echo "==> Emulator ready on port $PORT"
    break
  fi
  if [ "$i" -eq "$MAX_RETRIES" ]; then
    echo "ERROR: Emulator did not start within ${MAX_RETRIES}s"
    docker logs "$CONTAINER_NAME"
    exit 1
  fi
  sleep 1
done

echo "==> Setting environment variables..."
cat <<EOF
Export these in your shell:

export AWS_ENDPOINT_URL=https://127.0.0.1:${PORT}
export AWS_SHARED_CREDENTIALS_FILE=~/.aws/emulator/${PORT}/emulator_credentials
export AWS_CONFIG_FILE=~/.aws/emulator/${PORT}/config
export AWS_CA_BUNDLE=~/.aws/emulator/${PORT}/ca.pem
export AWS_EC2_METADATA_DISABLED=true
export AWS_DISABLE_HOST_PREFIX_INJECTION=true
export AWS_REGION=us-east-1
export AWS_DEFAULT_REGION=us-east-1
EOF

#!/usr/bin/env bash
set -euo pipefail

CONTAINER_NAME="aws-emulator-ci"

echo "==> Stopping AWS Emulator..."
docker stop "$CONTAINER_NAME" 2>/dev/null || echo "Container already stopped"
echo "==> Emulator stopped"

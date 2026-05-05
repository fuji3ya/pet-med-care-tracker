#!/usr/bin/env bash
set -euo pipefail

DEVICE_NAME="${1:-iPhone 15}"
PORT="${SERVE_SIM_PORT:-3200}"

echo "Starting serve-sim for ${DEVICE_NAME} on port ${PORT}..."
echo "Open http://localhost:${PORT} after the Tend Pets app is running in Simulator."

npx --yes serve-sim "${DEVICE_NAME}" -p "${PORT}"

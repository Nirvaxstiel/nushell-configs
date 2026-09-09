#!/usr/bin/env bash
set -euo pipefail

DSH_PORT=3080
PROXY_PORT=3081

cleanup() {
    kill "${DSH_PID:-}" "${SOCAT_PID:-}" 2>/dev/null || true
}

trap cleanup EXIT INT TERM

cd /opt/deepseek-harness

pnpm dsh web \
    --host 127.0.0.1 \
    --port "$DSH_PORT" &
DSH_PID=$!

socat \
    TCP-LISTEN:"$PROXY_PORT",bind=0.0.0.0,reuseaddr,fork \
    TCP:127.0.0.1:"$DSH_PORT" &
SOCAT_PID=$!

wait "$DSH_PID"

#!/usr/bin/env bash
# Probe comfyui image: ComfyUI HTTP server answers /system_stats on port 8188.
set -euo pipefail

image=${1:?usage: probe-comfyui.sh <image>}
platform=${PROBE_PLATFORM:-linux/amd64}
cid=""
cleanup() { [ -n "$cid" ] && docker rm -f "$cid" >/dev/null 2>&1 || true; }
trap cleanup EXIT

cid=$(docker run -d --platform "$platform" -p 127.0.0.1::8188 "$image")
port=$(docker port "$cid" 8188/tcp | head -n1 | sed 's/.*://')

ready=0
for _ in $(seq 1 90); do
  if body=$(curl -sf "http://127.0.0.1:$port/system_stats" 2>/dev/null); then
    echo "ok: ComfyUI /system_stats: $(echo "$body" | head -c 200)"
    ready=1
    break
  fi
  sleep 2
done
[ "$ready" = 1 ] || { docker logs "$cid" >&2 || true; echo "FAIL: ComfyUI did not answer /system_stats" >&2; exit 1; }
echo "all comfyui probes passed for $image"

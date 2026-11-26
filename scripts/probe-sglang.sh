#!/usr/bin/env bash
# Probe sglang image: sglang Python module importable over SSH.
set -euo pipefail

image=${1:?usage: probe-sglang.sh <image>}
platform=${PROBE_PLATFORM:-linux/amd64}
work=$(mktemp -d)
cid=""
cleanup() { [ -n "$cid" ] && docker rm -f "$cid" >/dev/null 2>&1 || true; rm -rf "$work"; }
trap cleanup EXIT

ssh-keygen -q -t ed25519 -N '' -f "$work/id"
cid=$(docker run -d --platform "$platform" -p 127.0.0.1::22 -e SSH_PUBKEY="$(cat "$work/id.pub")" "$image")
port=$(docker port "$cid" 22/tcp | head -n1 | sed 's/.*://')
for _ in $(seq 1 60); do
  ssh-keyscan -p "$port" 127.0.0.1 2>/dev/null | grep -q ssh-ed25519 && break
  sleep 1
done

ver=$(ssh -F /dev/null -i "$work/id" -p "$port" -o IdentitiesOnly=yes -o BatchMode=yes \
  -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR \
  root@127.0.0.1 'python3 -c "import sglang, torch; print(sglang.__version__, torch.__version__)"')
echo "ok: sglang over SSH: $ver"
echo "all sglang probes passed for $image"

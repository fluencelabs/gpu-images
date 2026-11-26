#!/usr/bin/env bash
# Probe pytorch image: torch importable over SSH + authenticated JupyterLab on 8888.
set -euo pipefail

image=${1:?usage: probe-pytorch.sh <image>}
platform=${PROBE_PLATFORM:-linux/amd64}
work=$(mktemp -d)
cid=""
cleanup() { [ -n "$cid" ] && docker rm -f "$cid" >/dev/null 2>&1 || true; rm -rf "$work"; }
trap cleanup EXIT

ssh-keygen -q -t ed25519 -N '' -f "$work/id"
tok="probe-token-987654"
cid=$(docker run -d --platform "$platform" -p 127.0.0.1::22 -p 127.0.0.1::8888 \
  -e SSH_PUBKEY="$(cat "$work/id.pub")" -e JUPYTER_TOKEN="$tok" "$image")
ssh_port=$(docker port "$cid" 22/tcp | head -n1 | sed 's/.*://')
jup_port=$(docker port "$cid" 8888/tcp | head -n1 | sed 's/.*://')

for _ in $(seq 1 60); do
  ssh-keyscan -p "$ssh_port" 127.0.0.1 2>/dev/null | grep -q ssh-ed25519 && break
  sleep 1
done

torch_ver=$(ssh -F /dev/null -i "$work/id" -p "$ssh_port" -o IdentitiesOnly=yes -o BatchMode=yes \
  -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR \
  root@127.0.0.1 'python3 -c "import torch; print(torch.__version__, torch.version.cuda)"')
echo "ok: torch over SSH: $torch_ver"

# Wait for JupyterLab API on 8888
ready=0
for _ in $(seq 1 60); do
  code=$(curl -s -o /dev/null -w '%{http_code}' "http://127.0.0.1:$jup_port/api/status" || true)
  if [ "$code" = "403" ] || [ "$code" = "401" ]; then
    ready=1
    break
  fi
  sleep 1
done
[ "$ready" = 1 ] || { docker logs "$cid" >&2 || true; echo "FAIL: JupyterLab did not require auth (code=$code)" >&2; exit 1; }
echo "ok: JupyterLab refuses unauthenticated API access (HTTP $code)"

auth_code=$(curl -s -o /dev/null -w '%{http_code}' -H "Authorization: token $tok" "http://127.0.0.1:$jup_port/api/status")
[ "$auth_code" = "200" ] || { echo "FAIL: JupyterLab rejected valid token (HTTP $auth_code)" >&2; exit 1; }
echo "ok: JupyterLab accepts configured JUPYTER_TOKEN (HTTP 200)"
echo "all pytorch probes passed for $image"

#!/usr/bin/env bash
# Probe ollama image: ollama serve answers /api/version on port 11434 and CLI works over SSH.
set -euo pipefail

image=${1:?usage: probe-ollama.sh <image>}
platform=${PROBE_PLATFORM:-linux/amd64}
work=$(mktemp -d)
cid=""
cleanup() { [ -n "$cid" ] && docker rm -f "$cid" >/dev/null 2>&1 || true; rm -rf "$work"; }
trap cleanup EXIT

ssh-keygen -q -t ed25519 -N '' -f "$work/id"
cid=$(docker run -d --platform "$platform" -p 127.0.0.1::22 -p 127.0.0.1::11434 \
  -e SSH_PUBKEY="$(cat "$work/id.pub")" "$image")
ssh_port=$(docker port "$cid" 22/tcp | head -n1 | sed 's/.*://')
api_port=$(docker port "$cid" 11434/tcp | head -n1 | sed 's/.*://')

ready=0
for _ in $(seq 1 60); do
  if body=$(curl -sf "http://127.0.0.1:$api_port/api/version" 2>/dev/null); then
    echo "ok: Ollama /api/version: $body"
    ready=1
    break
  fi
  sleep 1
done
[ "$ready" = 1 ] || { docker logs "$cid" >&2 || true; echo "FAIL: Ollama did not answer /api/version" >&2; exit 1; }

for _ in $(seq 1 30); do
  ssh-keyscan -p "$ssh_port" 127.0.0.1 2>/dev/null | grep -q ssh-ed25519 && break
  sleep 1
done
cli=$(ssh -F /dev/null -i "$work/id" -p "$ssh_port" -o IdentitiesOnly=yes -o BatchMode=yes \
  -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR \
  root@127.0.0.1 'ollama --version')
echo "ok: ollama CLI over SSH: $cli"
echo "all ollama probes passed for $image"

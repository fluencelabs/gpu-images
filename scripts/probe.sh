#!/usr/bin/env bash
# Probe a built ubuntu-ssh image: key-only root login, entrypoint replacement, start without a key.
# Usage: scripts/probe.sh <image>
set -euo pipefail

image=${1:?usage: probe.sh <image>}
platform=${PROBE_PLATFORM:-linux/amd64}
label=gpu-images-probe
run_id="$$-$(date +%s)"
work=$(mktemp -d)

cleanup() {
  local ids
  ids=$(docker ps -aq --filter "label=$label=$run_id" 2>/dev/null || true)
  if [ -n "$ids" ]; then
    # shellcheck disable=SC2086
    docker rm -f $ids >/dev/null 2>&1 || true
  fi
  rm -rf "$work"
}
trap cleanup EXIT

fail() { echo "FAIL: $*" >&2; exit 1; }
pass() { echo "ok: $*"; }

ssh-keygen -q -t ed25519 -N '' -C probe-good -f "$work/good"
ssh-keygen -q -t ed25519 -N '' -C probe-bad -f "$work/bad"
ssh-keygen -q -t ed25519 -N '' -C probe-extra -f "$work/extra"

start() {
  docker run -d --platform "$platform" --label "$label=$run_id" -p 127.0.0.1::22 "$@"
}

port_of() { docker port "$1" 22/tcp | head -n1 | sed 's/.*://'; }

ssh_as() {
  local key=$1 port=$2
  shift 2
  ssh -F /dev/null -i "$key" -p "$port" -o IdentitiesOnly=yes -o BatchMode=yes \
    -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR \
    -o ConnectTimeout=5 root@127.0.0.1 "$@"
}

wait_ssh() {
  local c=$1 port
  port=$(port_of "$c")
  for _ in $(seq 1 60); do
    if ssh-keyscan -p "$port" 127.0.0.1 2>/dev/null | grep -q ssh-ed25519; then
      echo "$port"
      return 0
    fi
    sleep 1
  done
  docker logs "$c" >&2 || true
  fail "sshd of $c did not answer"
}

expect_login() {
  local c=$1 what=$2 port
  port=$(wait_ssh "$c")
  [ "$(ssh_as "$work/good" "$port" id -u)" = 0 ] || fail "$what: login with SSH_PUBKEY key"
  pass "$what: root login with the SSH_PUBKEY key"
}

pub=$(cat "$work/good.pub")

# Image carries no host keys.
if docker run --rm --platform "$platform" --label "$label=1" --entrypoint /bin/ls "$image" /etc/ssh \
  | grep -q ssh_host_; then
  fail "image contains host keys"
fi
pass "image contains no host keys"

# Default entrypoint and command.
c=$(start -e SSH_PUBKEY="$pub" -e FLUENCE_PROBE_ENV="ok-123" "$image")
expect_login "$c" "default"
port=$(port_of "$c")
[ "$(ssh_as "$work/good" "$port" 'printf %s "${FLUENCE_PROBE_ENV:-}"')" = "ok-123" ] \
  || fail "container env var not visible over SSH"
[ -z "$(ssh_as "$work/good" "$port" 'printf %s "${SSH_PUBKEY:-}"')" ] \
  || fail "SSH_PUBKEY leaked into SSH session env"
pass "container env preserved over SSH without leaking SSH_PUBKEY"
if ssh_as "$work/bad" "$port" true 2>/dev/null; then fail "foreign key accepted"; fi
pass "foreign key refused"
methods=$(ssh -F /dev/null -p "$port" -o BatchMode=yes -o PubkeyAuthentication=no \
  -o PreferredAuthentications=password,keyboard-interactive -o StrictHostKeyChecking=no \
  -o UserKnownHostsFile=/dev/null -o ConnectTimeout=5 root@127.0.0.1 true 2>&1 || true)
echo "$methods" | grep -q 'Permission denied (publickey)' || fail "password methods offered: $methods"
pass "password and keyboard-interactive not offered"
[ "$(docker exec "$c" sshd -T | grep -i '^passwordauthentication')" = "passwordauthentication no" ] \
  || fail "PasswordAuthentication is not no"
pass "sshd -T: passwordauthentication no"
key1=$(docker exec "$c" cat /etc/ssh/ssh_host_ed25519_key.pub)

# Existing keys are kept and SSH_PUBKEY is not duplicated on restart.
docker exec -i "$c" sh -c "cat >> /root/.ssh/authorized_keys" < "$work/extra.pub"
docker restart -t 2 "$c" >/dev/null
port=$(wait_ssh "$c")
[ "$(ssh_as "$work/extra" "$port" id -u)" = 0 ] || fail "existing key lost after restart"
[ "$(docker exec "$c" grep -cxF "$pub" /root/.ssh/authorized_keys)" = 1 ] || fail "SSH_PUBKEY duplicated"
pass "existing key kept, SSH_PUBKEY not duplicated"

# SIGTERM stops the container promptly.
t0=$(date +%s)
docker stop -t 20 "$c" >/dev/null
[ $(($(date +%s) - t0)) -lt 10 ] || fail "SIGTERM not handled: stop took the timeout"
pass "SIGTERM stops the container"

# Host keys differ between containers.
c=$(start -e SSH_PUBKEY="$pub" "$image")
wait_ssh "$c" >/dev/null
[ "$(docker exec "$c" cat /etc/ssh/ssh_host_ed25519_key.pub)" != "$key1" ] || fail "host keys shared"
pass "host keys generated per container"

# User command replaces CMD.
c=$(start -e SSH_PUBKEY="$pub" "$image" bash -c "sleep 600")
expect_login "$c" "command bash -c"

# User command replaces ENTRYPOINT as Akash SDL and Kubernetes do.
c=$(start -e SSH_PUBKEY="$pub" --entrypoint sh "$image" -c "sleep 600")
expect_login "$c" "entrypoint sh -c"
t0=$(date +%s)
docker stop -t 20 "$c" >/dev/null
[ $(($(date +%s) - t0)) -lt 10 ] || fail "entrypoint sh -c: SIGTERM not handled"
pass "entrypoint sh -c: SIGTERM stops the container"
c=$(start -e SSH_PUBKEY="$pub" --entrypoint bash "$image" -c "sleep 600")
expect_login "$c" "entrypoint bash -c"

# No SSH_PUBKEY: the container starts and lives.
c=$(start "$image")
wait_ssh "$c" >/dev/null
sleep 3
[ "$(docker inspect -f '{{.State.Running}}' "$c")" = true ] || fail "container without SSH_PUBKEY exited"
pass "starts and lives without SSH_PUBKEY"

echo "all probes passed for $image"

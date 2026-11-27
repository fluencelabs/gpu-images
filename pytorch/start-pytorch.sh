#!/bin/sh
# Start authenticated JupyterLab (unless JUPYTER_ENABLE=0).
set -eu

if [ "${JUPYTER_ENABLE:-1}" = "0" ]; then
  echo "fluence-pytorch: JUPYTER_ENABLE=0; staying up for SSH" >&2
  exec sleep infinity
fi

token="${JUPYTER_TOKEN:-}"
if [ -z "$token" ]; then
  token=$(python3 -c 'import secrets; print(secrets.token_urlsafe(32))')
  mkdir -p /root/.jupyter
  chmod 700 /root/.jupyter
  printf '%s\n' "$token" > /root/.jupyter/token
  chmod 600 /root/.jupyter/token
  echo "fluence-pytorch: generated Jupyter token saved in /root/.jupyter/token" >&2
fi

port="${JUPYTER_PORT:-8888}"
root_dir="${JUPYTER_ROOT_DIR:-/workspace}"
mkdir -p "$root_dir"

exec jupyter lab \
  --ip=0.0.0.0 \
  --port="$port" \
  --no-browser \
  --allow-root \
  --IdentityProvider.token="$token" \
  --ServerApp.root_dir="$root_dir"

#!/bin/sh
# Start ComfyUI on 0.0.0.0:8188 (falling back to --cpu when no NVIDIA device is present).
set -eu

port="${COMFYUI_PORT:-8188}"
extra=""
if [ ! -e /dev/nvidia0 ]; then
  echo "fluence-comfyui: no /dev/nvidia0 detected; starting in --cpu mode" >&2
  extra="--cpu"
fi

# shellcheck disable=SC2086
exec python3 /opt/ComfyUI/main.py --listen 0.0.0.0 --port "$port" $extra ${COMFYUI_ARGS:-}

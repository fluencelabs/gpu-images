#!/bin/sh
# Serve a model via SGLang when SGLANG_MODEL or MODEL is set; otherwise stay up for SSH.
set -eu

model="${SGLANG_MODEL:-${MODEL:-}}"
if [ -z "$model" ]; then
  echo "fluence-sglang: SGLANG_MODEL/MODEL is not set; container is ready over SSH (run: python3 -m sglang.launch_server --model-path <model> --host 0.0.0.0 --port 30000)" >&2
  exec sleep infinity
fi

port="${SGLANG_PORT:-30000}"
# shellcheck disable=SC2086
exec python3 -m sglang.launch_server --model-path "$model" --host 0.0.0.0 --port "$port" ${SGLANG_ARGS:-}

#!/bin/sh
# Serve a model via vLLM OpenAI API when VLLM_MODEL or MODEL is set; otherwise stay up for SSH.
set -eu

model="${VLLM_MODEL:-${MODEL:-}}"
if [ -z "$model" ]; then
  echo "fluence-vllm: VLLM_MODEL/MODEL is not set; container is ready over SSH (run: vllm serve <model> --host 0.0.0.0 --port 8000)" >&2
  exec sleep infinity
fi

port="${VLLM_PORT:-8000}"
# shellcheck disable=SC2086
exec vllm serve "$model" --host 0.0.0.0 --port "$port" ${VLLM_ARGS:-}

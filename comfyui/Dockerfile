FROM docker.io/pytorch/pytorch:2.11.0-cuda12.8-cudnn9-runtime@sha256:eee11b3b3872a8c838e35ef48f08b2d5def2080902c7f666831310ca1a0ef2be

ARG COMFYUI_VERSION=v0.46.0
ARG COMFYUI_MANAGER_VERSION=4.4.3
ARG DEBIAN_FRONTEND=noninteractive
ENV PIP_BREAK_SYSTEM_PACKAGES=1

COPY shared/rootfs/ /
RUN --mount=type=bind,source=shared/install-ssh.sh,target=/tmp/install-ssh.sh \
    sh /tmp/install-ssh.sh \
 && apt-get update \
 && apt-get install -y --no-install-recommends \
      git libgl1 libglib2.0-0 ffmpeg wget jq \
 && rm -rf /var/lib/apt/lists/* \
 && git clone --depth 1 --branch "${COMFYUI_VERSION}" \
      https://github.com/comfyanonymous/ComfyUI.git /opt/ComfyUI \
 && git clone --depth 1 --branch "${COMFYUI_MANAGER_VERSION}" \
      https://github.com/Comfy-Org/ComfyUI-Manager.git /opt/ComfyUI/custom_nodes/ComfyUI-Manager \
 && grep -viE '^(torch|torchvision|torchaudio)([<>=!~ ]|$)' /opt/ComfyUI/requirements.txt > /tmp/comfy-reqs.txt \
 && pip install --no-cache-dir -r /tmp/comfy-reqs.txt \
 && if [ -f /opt/ComfyUI/custom_nodes/ComfyUI-Manager/requirements.txt ]; then \
      pip install --no-cache-dir -r /opt/ComfyUI/custom_nodes/ComfyUI-Manager/requirements.txt; \
    fi \
 && rm -f /tmp/comfy-reqs.txt

COPY comfyui/start-comfyui.sh /usr/local/bin/fluence-comfyui
RUN chmod 755 /usr/local/bin/fluence-comfyui

LABEL org.opencontainers.image.source="https://github.com/fluencelabs/gpu-images" \
      org.opencontainers.image.licenses="Apache-2.0"

ENV PATH="/usr/local/bin:${PATH}"
WORKDIR /opt/ComfyUI
EXPOSE 22 8188
ENTRYPOINT ["/usr/bin/tini", "--", "/usr/local/lib/fluence-ssh/entrypoint"]
CMD ["/usr/local/bin/fluence-comfyui"]

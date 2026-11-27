FROM docker.io/pytorch/pytorch:2.11.0-cuda12.8-cudnn9-runtime@sha256:eee11b3b3872a8c838e35ef48f08b2d5def2080902c7f666831310ca1a0ef2be

ARG DEBIAN_FRONTEND=noninteractive
ENV PIP_BREAK_SYSTEM_PACKAGES=1
COPY shared/rootfs/ /
RUN --mount=type=bind,source=shared/install-ssh.sh,target=/tmp/install-ssh.sh \
    sh /tmp/install-ssh.sh \
 && apt-get update \
 && apt-get install -y --no-install-recommends \
      git build-essential tmux htop wget jq unzip \
 && rm -rf /var/lib/apt/lists/* \
 && pip install --no-cache-dir jupyterlab ipykernel ipywidgets uv

COPY pytorch/start-pytorch.sh /usr/local/bin/fluence-pytorch
RUN chmod 755 /usr/local/bin/fluence-pytorch && mkdir -p /workspace

LABEL org.opencontainers.image.source="https://github.com/fluencelabs/gpu-images" \
      org.opencontainers.image.licenses="Apache-2.0"

ENV PATH="/usr/local/bin:${PATH}"
WORKDIR /workspace
EXPOSE 22 8888
ENTRYPOINT ["/usr/bin/tini", "--", "/usr/local/lib/fluence-ssh/entrypoint"]
CMD ["/usr/local/bin/fluence-pytorch"]

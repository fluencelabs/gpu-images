FROM docker.io/nvidia/cuda:12.8.2-devel-ubuntu24.04@sha256:7fc48a36965c6d0e5c9717dd899b2851cabb2dfef43d95dd12046a2d40bdc90f

ARG DEBIAN_FRONTEND=noninteractive
COPY shared/rootfs/ /
RUN --mount=type=bind,source=shared/install-ssh.sh,target=/tmp/install-ssh.sh \
    sh /tmp/install-ssh.sh \
 && apt-get update \
 && apt-get install -y --no-install-recommends \
      git build-essential cmake ninja-build pkg-config \
      python3 python3-pip python3-venv \
      tmux htop wget jq unzip \
 && rm -rf /var/lib/apt/lists/*

LABEL org.opencontainers.image.source="https://github.com/fluencelabs/gpu-images" \
      org.opencontainers.image.licenses="Apache-2.0"

ENV PATH="/usr/local/bin:${PATH}"
WORKDIR /workspace
EXPOSE 22
ENTRYPOINT ["/usr/bin/tini", "--", "/usr/local/lib/fluence-ssh/entrypoint"]
CMD ["sleep", "infinity"]

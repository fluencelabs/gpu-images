FROM docker.io/vllm/vllm-openai:v0.34.0@sha256:20fdb089454afbb324efa4110a2c025ff7b27cc1a086e07aa580b18df8ad1ce1

ARG DEBIAN_FRONTEND=noninteractive
COPY shared/rootfs/ /
RUN --mount=type=bind,source=shared/install-ssh.sh,target=/tmp/install-ssh.sh \
    sh /tmp/install-ssh.sh

COPY vllm/start-vllm.sh /usr/local/bin/fluence-vllm
RUN chmod 755 /usr/local/bin/fluence-vllm

LABEL org.opencontainers.image.source="https://github.com/fluencelabs/gpu-images" \
      org.opencontainers.image.licenses="Apache-2.0"

ENV PATH="/usr/local/bin:${PATH}"
EXPOSE 22 8000
ENTRYPOINT ["/usr/bin/tini", "--", "/usr/local/lib/fluence-ssh/entrypoint"]
CMD ["/usr/local/bin/fluence-vllm"]

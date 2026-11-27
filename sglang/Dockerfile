FROM docker.io/lmsysorg/sglang:v0.5.23-runtime@sha256:3ce6da3e5ea0fee2dac6a23b528cb294fedd31ca74a55a4511f709c5e01e8652

ARG DEBIAN_FRONTEND=noninteractive
COPY shared/rootfs/ /
RUN --mount=type=bind,source=shared/install-ssh.sh,target=/tmp/install-ssh.sh \
    sh /tmp/install-ssh.sh

COPY sglang/start-sglang.sh /usr/local/bin/fluence-sglang
RUN chmod 755 /usr/local/bin/fluence-sglang

LABEL org.opencontainers.image.source="https://github.com/fluencelabs/gpu-images" \
      org.opencontainers.image.licenses="Apache-2.0"

ENV PATH="/usr/local/bin:${PATH}"
EXPOSE 22 30000
ENTRYPOINT ["/usr/bin/tini", "--", "/usr/local/lib/fluence-ssh/entrypoint"]
CMD ["/usr/local/bin/fluence-sglang"]

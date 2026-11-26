ARG UBUNTU_VERSION=24.04

FROM docker.io/library/ubuntu:24.04@sha256:fe81560990fae86dc4743202b2cb4d3df98d0bcf949173cecef15ce1127ef852 AS base-24.04
FROM docker.io/library/ubuntu:22.04@sha256:076e7bf82319619f28dd0aa9c02ab34b055ad37100395b4f49a2ffba04fb5e11 AS base-22.04

FROM base-${UBUNTU_VERSION}

ARG DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get -y upgrade && rm -rf /var/lib/apt/lists/*

COPY shared/rootfs/ /
RUN --mount=type=bind,source=shared/install-ssh.sh,target=/tmp/install-ssh.sh \
    sh /tmp/install-ssh.sh

LABEL org.opencontainers.image.source="https://github.com/fluencelabs/gpu-images" \
      org.opencontainers.image.licenses="Apache-2.0"

ENV PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
EXPOSE 22
ENTRYPOINT ["/usr/bin/tini", "--", "/usr/local/lib/fluence-ssh/entrypoint"]
CMD ["sleep", "infinity"]

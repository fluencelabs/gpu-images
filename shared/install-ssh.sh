#!/bin/sh
# Install the shared Fluence SSH + tini runtime layer and apply OS security updates.
set -eu

export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get -y upgrade
apt-get install -y --no-install-recommends \
  openssh-server ca-certificates curl less vim-tiny iproute2 procps tini
rm -rf /var/lib/apt/lists/*
rm -f /etc/ssh/ssh_host_*

chmod 755 /usr/local/lib/fluence-ssh/entrypoint /usr/local/lib/fluence-ssh/shell-shim
ln -sf ../lib/fluence-ssh/shell-shim /usr/local/bin/sh
ln -sf ../lib/fluence-ssh/shell-shim /usr/local/bin/bash

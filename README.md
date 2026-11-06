# gpu-images

Public base container images for Fluence GPU containers, published on Docker Hub
under `docker.io/fluencelabs`.

## ubuntu-ssh

`docker.io/fluencelabs/ubuntu-ssh` — Ubuntu with an OpenSSH server that the image
starts by itself, for GPU containers reached over SSH. Platform: `linux/amd64`.

| Tags | Base |
|---|---|
| `24.04`, `24.04-YYYYMMDD` | Ubuntu 24.04 LTS |
| `22.04`, `22.04-YYYYMMDD` | Ubuntu 22.04 LTS |

Images are rebuilt on every change to `main` and weekly, picking up Ubuntu
security updates. The version tag (`24.04`) moves to the latest build; the dated
tag (`24.04-20261106`) names one build.

### Contract

- **`SSH_PUBKEY`** — one or more OpenSSH public keys, one per line. At start every
  key not yet present in `/root/.ssh/authorized_keys` is appended; keys already in
  the file are kept, duplicates are not added. Without `SSH_PUBKEY` the container
  still starts, and only keys already in the file are accepted.
- **Login** — `root`, by key only: password and keyboard-interactive
  authentication are off, `PermitRootLogin prohibit-password`.
- **Host keys** — generated when a container starts; the image contains none, so
  containers never share host keys.
- **Port** — `22/tcp`.
- **Command** — by default `sleep infinity`: the container lives until stopped.
  A command you pass runs after sshd has started. `tini` is PID 1 and forwards
  `SIGTERM`, so `docker stop` and pod termination are immediate.
- **Entrypoint replaced by `sh -c "<command>"`** — what Kubernetes `command` and
  Akash SDL `command: ["sh", "-c"]` do — still starts sshd: the image puts an `sh`
  into `/usr/local/bin`, ahead of `/bin` on `PATH`; run as PID 1 it does the same
  start-up and then runs `/bin/sh` under `tini`. Run as any other process it is
  plain `/bin/sh`. Other entrypoint replacements (`bash -c`, an absolute
  `/bin/sh`) skip sshd.
- **Packages** — openssh-server, ca-certificates, curl, less, vim-tiny, iproute2,
  procps, tini.

### Pinning a digest

Version tags move weekly. To keep one build, reference it by digest:

```sh
docker buildx imagetools inspect docker.io/fluencelabs/ubuntu-ssh:24.04 \
  --format '{{json .Manifest.Digest}}'
# docker.io/fluencelabs/ubuntu-ssh:24.04@sha256:<digest>
```

The digest of every published build is also printed in the summary of its
workflow run.

### Example

```sh
docker run -d -p 2222:22 -e SSH_PUBKEY="$(cat ~/.ssh/id_ed25519.pub)" \
  docker.io/fluencelabs/ubuntu-ssh:24.04
ssh -p 2222 root@localhost
```

## License

[Apache-2.0](LICENSE)

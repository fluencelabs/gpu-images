# gpu-images

Public container images for Fluence GPU containers, published on GitHub Container
Registry under `ghcr.io/fluencelabs` (with optional mirrors on Docker Hub under
`docker.io/fluencelabs`). Platform: `linux/amd64`.

## ubuntu-ssh

`ghcr.io/fluencelabs/ubuntu-ssh` — minimal Ubuntu with an OpenSSH server that the
image starts by itself, for GPU containers reached over SSH. Host NVIDIA drivers
and GPUs are mounted by the runtime; CUDA Toolkit, Python, and ML frameworks are
not preinstalled.

| Tags | Base |
|---|---|
| `24.04`, `24.04-YYYYMMDD` | Ubuntu 24.04 LTS |
| `22.04`, `22.04-YYYYMMDD` | Ubuntu 22.04 LTS |

Images are rebuilt on every change to `main` and weekly, picking up Ubuntu
security updates. The version tag (`24.04`) moves to the latest build; the dated
tag (`24.04-20261127`) names one immutable build.

## Shared SSH Contract

Every image in this repository shares the `shared/` SSH and `tini` runtime layer:

- **`SSH_PUBKEY`** — one or more OpenSSH public keys, one per line. At start every
  key not yet present in `/root/.ssh/authorized_keys` is appended; keys already in
  the file are kept, duplicates are not added. Without `SSH_PUBKEY` the container
  still starts, and only keys already in the file are accepted.
- **Login** — `root`, by key only: password and keyboard-interactive
  authentication are off, `PermitRootLogin prohibit-password`.
- **Host keys** — generated when a container starts; images contain none, so
  containers never share host keys.
- **Container environment** — single-line container environment variables (such as
  `PATH`, `CUDA_HOME`, `LD_LIBRARY_PATH`, `HF_TOKEN`) are preserved for SSH
  sessions via `/etc/environment`, excluding `SSH_PUBKEY`.
- **Port** — `22/tcp` (plus any workload-specific port).
- **Command** — `tini` is PID 1 and forwards `SIGTERM`, so `docker stop` and pod
  termination are immediate.
- **Entrypoint replaced by `sh -c "<command>"` or `bash -c "<command>"`** — what
  Kubernetes `command` and Akash SDL `command: ["sh", "-c"]` do — still starts
  sshd: images put `sh` and `bash` into `/usr/local/bin`, ahead of `/bin` on
  `PATH`; run as PID 1 they run the same start-up and then exec `/bin/sh` or
  `/bin/bash` under `tini`.

## Pinning a build

Version tags move weekly. To keep one build, use its dated tag or digest:

```sh
docker buildx imagetools inspect ghcr.io/fluencelabs/ubuntu-ssh:24.04 \
  --format '{{json .Manifest.Digest}}'
# ghcr.io/fluencelabs/ubuntu-ssh:24.04@sha256:<digest>
```

The digest of every published build is also printed in the summary of its
workflow run.

## Example

```sh
docker run -d -p 2222:22 -e SSH_PUBKEY="$(cat ~/.ssh/id_ed25519.pub)" \
  ghcr.io/fluencelabs/ubuntu-ssh:24.04
ssh -p 2222 root@localhost
```

## License

[Apache-2.0](LICENSE)

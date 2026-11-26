# gpu-images

Public container images for Fluence GPU containers, published on GitHub Container
Registry under `ghcr.io/fluencelabs` and mirrored to Docker Hub under
`docker.io/fluencelabs`. Platform: `linux/amd64`.

## Images

| Image | Tags | Ports | Base / Contents |
|---|---|---|---|
| `ghcr.io/fluencelabs/ubuntu-ssh` | `24.04`, `22.04` (+ `-YYYYMMDD`) | `22/tcp` | Minimal Ubuntu LTS + OpenSSH. Host NVIDIA drivers and GPUs are mounted by the runtime; CUDA Toolkit, Python, and ML frameworks are not preinstalled. |
| `ghcr.io/fluencelabs/cuda-devel` | `12.8-ubuntu24.04` (+ `-YYYYMMDD`) | `22/tcp` | NVIDIA CUDA 12.8.2 devel (`nvcc`, headers), Ubuntu 24.04, `build-essential`, `cmake`, `ninja`, Python 3, `git`, `tmux`, `htop`. |
| `ghcr.io/fluencelabs/pytorch` | `2.11-cuda12.8` (+ `-YYYYMMDD`) | `22/tcp`, `8888/tcp` | PyTorch 2.11 + CUDA 12.8 + cuDNN 9 + authenticated JupyterLab (`JUPYTER_TOKEN` or generated in `/root/.jupyter/token`; `JUPYTER_ENABLE=0` for SSH only) + `uv`. |
| `ghcr.io/fluencelabs/vllm` | `0.34` (+ `-YYYYMMDD`) | `22/tcp`, `8000/tcp` | vLLM OpenAI-compatible server (`v0.34.0`). Set `VLLM_MODEL` or `MODEL` to auto-serve on `:8000`; otherwise stays up for SSH. |
| `ghcr.io/fluencelabs/sglang` | `0.5` (+ `-YYYYMMDD`) | `22/tcp`, `30000/tcp` | SGLang runtime (`v0.5.23`). Set `SGLANG_MODEL` or `MODEL` to auto-serve on `:30000`; otherwise stays up for SSH. |
| `ghcr.io/fluencelabs/comfyui` | `0.46-cuda12.8` (+ `-YYYYMMDD`) | `22/tcp`, `8188/tcp` | ComfyUI `v0.46.0` + ComfyUI-Manager `4.4.3` on PyTorch 2.11 / CUDA 12.8, listening on `:8188`. |
| `ghcr.io/fluencelabs/ollama` | `0.40` (+ `-YYYYMMDD`) | `22/tcp`, `11434/tcp` | Ollama `0.40.18` (`ollama serve` listening on `0.0.0.0:11434`) + SSH. |

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
- **Command** — `tini` is PID 1 and forwards `SIGTERM`, so `docker stop` and pod
  termination are immediate.
- **Entrypoint replaced by `sh -c "<command>"` or `bash -c "<command>"`** — what
  Kubernetes `command` and Akash SDL `command: ["sh", "-c"]` do — still starts
  sshd: images put `sh` and `bash` into `/usr/local/bin`, ahead of `/bin` on
  `PATH`; run as PID 1 they run the same start-up and then exec `/bin/sh` or
  `/bin/bash` under `tini`.

## Automated Security Updates

- **Weekly security rebuilds:** every image workflow runs on a weekly Monday
  schedule with `--pull --no-cache`, applies `apt-get upgrade` security patches,
  runs `scripts/probe.sh` + its workload probe, and publishes both the moving
  version tag (`24.04`) and an immutable dated tag (`24.04-YYYYMMDD`).
- **Base image digest updates:** `.github/dependabot.yml` checks pinned
  `FROM ...@sha256:...` base images and GitHub Actions weekly and opens PRs
  gated by the full SSH and workload probe suite.
- **Vulnerability scanning:** every build scans the resulting image with Trivy
  (`HIGH`/`CRITICAL`, fixable CVEs), writes a count summary to the job summary,
  and uploads SARIF results to GitHub Security.

## Pinning a build

Version tags move weekly. To keep one build, use its dated tag or digest:

```sh
docker buildx imagetools inspect ghcr.io/fluencelabs/ubuntu-ssh:24.04 \
  --format '{{json .Manifest.Digest}}'
# ghcr.io/fluencelabs/ubuntu-ssh:24.04@sha256:<digest>
```

## Example

```sh
docker run -d -p 2222:22 -e SSH_PUBKEY="$(cat ~/.ssh/id_ed25519.pub)" \
  ghcr.io/fluencelabs/ubuntu-ssh:24.04
ssh -p 2222 root@localhost
```

## License

[Apache-2.0](LICENSE)

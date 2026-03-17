# AI Server Setup — Multi-Cloud GPU Instances

Central repo for deploying AI workloads (ComfyUI, LLM experiments) across ephemeral GPU instances.
Clone on any new server and run `scripts/startup.sh` to be fully operational.

**S3 is the persistence layer** — models, outputs, and configs sync to/from AWS S3 so you can
migrate between providers (Vast.ai, bare-metal VMs, RunPod, etc.) without re-downloading.

---

## Quick Start (New Instance)

```bash
# 1. Clone the repo (use HTTPS or your PAT)
git clone https://github.com/armanisadeghi/ai-setup.git
cd ai-setup

# 2. Create your secrets file (see config section below)
cp config/env_secrets.template  "$WORKSPACE/.env_secrets"    # or wherever $WORKSPACE is
# Then edit .env_secrets with your real keys

# 3. Run startup
bash scripts/startup.sh
```

`startup.sh` auto-detects paths, creates a venv if needed, installs ComfyUI + custom nodes,
syncs workflows, and pulls models from S3.

---

## Configuration System

All scripts source `config/resolve-config.sh` which resolves settings in this order
(later wins):

1. **`config/defaults.env`** — shared defaults (committed to git)
2. **`config/config.local.env`** — per-server overrides (gitignored)
3. **`$WORKSPACE/.env_secrets`** — secrets on the machine (gitignored)
4. **Auto-detection** — fills anything still unset (WORKSPACE, VENV, CUDA, etc.)

### Auto-Detected Paths

| Variable | Vast.ai | Bare VM (typical) |
|----------|---------|-------------------|
| `WORKSPACE` | `/workspace` | `$HOME/workspace` |
| `VENV` | `/venv/main` | `$WORKSPACE/.venv` |
| `COMFYUI_DIR` | `$WORKSPACE/ComfyUI` | `$WORKSPACE/ComfyUI` |
| `PYTORCH_INDEX_URL` | Based on CUDA version | Based on CUDA version |

To override any of these, set them in `config/config.local.env`.

### Secrets (`.env_secrets`)

Place this file in `$WORKSPACE/.env_secrets` on each server:

```bash
AWS_ACCESS_KEY_ID=...
AWS_SECRET_ACCESS_KEY=...
HF_TOKEN=...
CIVITAI_API_KEY=...
GIT_PAT=...
```

---

## S3 Persistence

```bash
# Check what would sync (dry run)
bash scripts/s3-sync.sh status

# Pull models from S3 to local
bash scripts/s3-sync.sh pull

# Push everything to S3 (before destroying instance)
bash scripts/s3-sync.sh push
```

| S3 Path | Contents |
|---------|----------|
| `s3://matrx-models/comfyui-models/` | Model weights |
| `s3://matrx-models/comfyui-outputs/` | Generated images/videos |
| `s3://matrx-models/comfyui-workflows/` | Workflow JSONs |
| `s3://matrx-models/config/` | Encrypted secrets backup |

---

## Directory Map (relative to `$WORKSPACE`)

```
$WORKSPACE/
├── .venv/                       ← Python virtual environment (or /venv/main on Vast.ai)
├── .env_secrets                 ← API keys (AWS, HF, CivitAI) — gitignored
├── comfyui.log                  ← ComfyUI runtime log
└── ComfyUI/
    ├── models/
    │   ├── diffusion_models/    ← WAN 2.2 T2V/I2V models
    │   ├── text_encoders/       ← T5-XXL text encoder
    │   ├── clip_vision/         ← CLIP vision encoder
    │   ├── vae/                 ← VAE models
    │   ├── checkpoints/         ← SD checkpoints
    │   ├── loras/               ← LoRA weights
    │   └── controlnet/          ← ControlNet models
    ├── custom_nodes/            ← Installed custom nodes
    ├── output/                  ← Generated images/videos
    ├── input/                   ← Input images/videos
    └── user/default/workflows/  ← Saved workflows

ai-setup/                        ← THIS REPO
├── README.md
├── config/
│   ├── resolve-config.sh        ← Central config resolver (sourced by all scripts)
│   ├── defaults.env             ← Shared defaults (in git)
│   └── config.local.env         ← Per-server overrides (gitignored)
├── scripts/
│   ├── startup.sh               ← Master startup script
│   ├── safe-shutdown.sh         ← Pre-destroy S3 sync + git push
│   ├── s3-sync.sh               ← S3 pull/push/status
│   ├── install-custom-nodes.sh  ← Custom node installer
│   ├── install-packages.sh      ← Extra pip packages
│   ├── download-wan-video.sh    ← WAN Video model downloader
│   ├── backup-workflows.sh      ← Backup workflows to repo
│   ├── upload-outputs-to-s3.sh  ← Upload outputs to S3
│   └── instance-status.sh       ← Quick status check
├── comfyui/
│   ├── workflows/               ← WAN 2.2 workflow JSONs
│   └── extra_model_paths.yaml
├── provisioning/
│   └── provisioning.sh          ← Vast.ai auto-provisioning
└── docs/
    ├── server-registry.md       ← Known server instances
    ├── models-inventory.md      ← Model inventory
    ├── storage-guide.md         ← Storage strategy
    ├── comfyui-setup.md         ← ComfyUI configuration
    └── wan-video-setup.md       ← WAN Video 2.2 guide
```

---

## Scripts Reference

| Script | Purpose |
|--------|---------|
| `startup.sh` | Full setup: venv, ComfyUI, nodes, workflows, S3 pull, launch |
| `safe-shutdown.sh` | S3 push, workflow backup, git commit+push — run before destroying |
| `s3-sync.sh pull\|push\|status` | Sync models/outputs/workflows to/from S3 |
| `instance-status.sh` | Quick GPU/disk/ComfyUI health check |
| `install-custom-nodes.sh` | Install/update custom nodes from the NODES array |
| `download-wan-video.sh` | Download WAN 2.2 models from HuggingFace |
| `upload-outputs-to-s3.sh` | Upload generated outputs to S3 |
| `backup-workflows.sh` | Copy workflows from ComfyUI to repo |

---

## New Instance Setup (From Scratch)

```bash
# 1. SSH in
ssh -p PORT user@IP

# 2. Install essentials (skip if the base image has them)
sudo apt-get update && sudo apt-get install -y python3-pip python3-venv ffmpeg git-lfs

# 3. Install AWS CLI
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o /tmp/awscliv2.zip
cd /tmp && unzip -q awscliv2.zip && sudo ./aws/install && cd -

# 4. Clone this repo
git clone https://github.com/armanisadeghi/ai-setup.git
cd ai-setup

# 5. Set up secrets
# Create $WORKSPACE/.env_secrets with your keys (see config section above)

# 6. Run startup — handles everything else
bash scripts/startup.sh
```

---

## Server Registry

See [docs/server-registry.md](docs/server-registry.md) for a list of all known server instances
(providers, specs, access details).

## Docs Index

- [docs/server-registry.md](docs/server-registry.md) — Known server instances
- [docs/storage-guide.md](docs/storage-guide.md) — Storage strategy
- [docs/comfyui-setup.md](docs/comfyui-setup.md) — ComfyUI configuration
- [docs/wan-video-setup.md](docs/wan-video-setup.md) — WAN Video 2.2 guide
- [docs/models-inventory.md](docs/models-inventory.md) — Model inventory

# AI Server Setup — Multi-Cloud GPU Instance

This repo is the single source of truth for our AI server setup.
Clone it on any new GPU instance and run `scripts/startup.sh` to be fully operational.

S3 is used as the persistence layer — models, outputs, and configs sync to/from AWS S3
so you can migrate between providers (Vast.ai, custom VMs, etc.) without re-downloading.

---

## Quick Start (New Instance)

```bash
cd /home/user
git clone https://github.com/armanisadeghi/ai-setup.git
cd ai-setup
bash scripts/startup.sh
```

---

## Current Instance

| Field | Value |
|-------|-------|
| Provider | Custom VM (Prague, Czech Republic) |
| GPU | 1x NVIDIA A100-SXM4-80GB |
| CPU | 8 cores |
| RAM | 128 GiB |
| Disk | 100 GiB (single volume, no separate persistent storage) |
| CUDA | 12.6 |
| PyTorch | 2.10.0+cu126 |
| Python | 3.12.3 |
| OS | Ubuntu 24.04.4 LTS |
| Public IP | 80.188.223.202 |
| Cost | ~$1.145/hr |

### Port Forwards

| Service | Internal Port | External Port | URL |
|---------|--------------|---------------|-----|
| **SSH** | 22 | 10218 | `ssh -p 10218 user@80.188.223.202` |
| **ComfyUI** | 8188 | 10246 | `http://80.188.223.202:10246` |
| **API (8000)** | 8000 | 10241 | `http://80.188.223.202:10241` |
| **API (8001)** | 8001 | 10242 | `http://80.188.223.202:10242` |
| **Web (8080)** | 8080 | 10243 | `http://80.188.223.202:10243` |
| **Web (3000)** | 3000 | 10244 | `http://80.188.223.202:10244` |
| **Web (3001)** | 3001 | 10245 | `http://80.188.223.202:10245` |
| **Jupyter** | 8888 | 10219 | `http://80.188.223.202:10219` |

---

## Storage — S3-Based Persistence

This instance uses a single 100 GiB disk with no separate persistent volume.
**AWS S3 is the persistence layer** — all important data syncs to S3 so you can
destroy this instance and recreate it on any provider without losing work.

### What Lives Where

| Data | Location | Backed to S3? |
|------|----------|--------------|
| Models (~45 GB) | `/home/user/workspace/ComfyUI/models/` | Yes → `s3://matrx-models/comfyui-models/` |
| Outputs | `/home/user/workspace/ComfyUI/output/` | Yes → `s3://matrx-models/comfyui-outputs/` |
| Workflows | `/home/user/workspace/ComfyUI/user/default/workflows/` | Yes (also in git) |
| Secrets | `/home/user/workspace/.env_secrets` | Yes (encrypted) |
| Scripts/Config | `/home/user/ai-setup/` | Git repo |
| Python venv | `/home/user/workspace/.venv/` | No (recreated by startup.sh) |

### S3 Sync Commands

```bash
# Check what would sync (dry run)
bash /home/user/ai-setup/scripts/s3-sync.sh status

# Pull models from S3 to local
bash /home/user/ai-setup/scripts/s3-sync.sh pull

# Push everything to S3 (before destroying instance)
bash /home/user/ai-setup/scripts/s3-sync.sh push
```

### Disk Budget (100 GiB total)

| Component | Size |
|-----------|------|
| OS + CUDA + packages | ~16 GiB |
| Python venv (PyTorch) | ~8 GiB |
| ComfyUI + custom nodes | ~1 GiB |
| WAN 2.2 models (fp8) | ~45 GiB |
| **Free for outputs** | **~29 GiB** |

---

## Directory Map

```
/home/user/
├── workspace/                       ← Main working directory
│   ├── .venv/                       ← Python virtual environment
│   ├── .env_secrets                 ← API keys (AWS, HF, CivitAI)
│   ├── comfyui.log                  ← ComfyUI runtime log
│   └── ComfyUI/                     ← ComfyUI installation
│       ├── models/
│       │   ├── diffusion_models/    ← WAN 2.2 T2V/I2V models
│       │   ├── text_encoders/       ← T5-XXL text encoder
│       │   ├── clip_vision/         ← CLIP vision encoder
│       │   ├── vae/                 ← VAE models
│       │   ├── checkpoints/         ← SD checkpoints
│       │   ├── loras/               ← LoRA weights
│       │   └── controlnet/          ← ControlNet models
│       ├── custom_nodes/            ← Installed custom nodes
│       ├── output/                  ← Generated images/videos
│       ├── input/                   ← Input images/videos
│       └── user/default/workflows/  ← Saved workflows
└── ai-setup/                        ← THIS REPO
    ├── README.md
    ├── docs/
    ├── scripts/
    │   ├── startup.sh               ← Master startup script
    │   ├── safe-shutdown.sh         ← Pre-destroy S3 sync + git push
    │   ├── s3-sync.sh               ← S3 pull/push/status
    │   ├── install-custom-nodes.sh  ← Custom node installer
    │   └── instance-status.sh       ← Quick status check
    └── comfyui/
        ├── workflows/               ← WAN 2.2 workflow JSONs
        └── extra_model_paths.yaml
```

---

## Services

ComfyUI runs as a systemd service and auto-starts on boot.

```bash
# Check status
sudo systemctl status comfyui

# Restart
sudo systemctl restart comfyui

# View logs
journalctl -u comfyui -f
# or: tail -f /home/user/workspace/comfyui.log
```

---

## Installed Models

| Model | Path | Size | Type |
|-------|------|------|------|
| WAN 2.2 T2V 14B fp8 (high noise) | `diffusion_models/` | 14.3 GB | Text-to-Video |
| WAN 2.2 T2V 14B fp8 (low noise) | `diffusion_models/` | 14.3 GB | Text-to-Video |
| WAN 2.2 5B combo (fp16) | `diffusion_models/` | 10.0 GB | T2V + I2V |
| UMT5-XXL fp8 text encoder | `text_encoders/` | 6.7 GB | Text encoder |
| WAN 2.2 VAE | `vae/` | 1.4 GB | VAE |
| WAN 2.1 VAE | `vae/` | 0.25 GB | VAE |
| CLIP Vision H | `clip_vision/` | 1.3 GB | Vision encoder |

---

## SSH Access

```bash
ssh -p 10218 user@80.188.223.202
```

---

## Docs Index

- [docs/storage-guide.md](docs/storage-guide.md) — Storage guide
- [docs/comfyui-setup.md](docs/comfyui-setup.md) — ComfyUI configuration
- [docs/wan-video-setup.md](docs/wan-video-setup.md) — WAN Video 2.2 guide
- [docs/models-inventory.md](docs/models-inventory.md) — Model inventory

---

## New Instance Setup (From Scratch)

```bash
# 1. SSH in
ssh -p PORT user@IP

# 2. Install essentials
sudo apt-get update && sudo apt-get install -y python3-pip python3-venv ffmpeg git-lfs

# 3. Install AWS CLI
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o /tmp/awscliv2.zip
cd /tmp && unzip -q awscliv2.zip && sudo ./aws/install

# 4. Clone this repo
cd /home/user
git clone https://github.com/armanisadeghi/ai-setup.git

# 5. Set up secrets
cp ai-setup/scripts/.env_secrets.template workspace/.env_secrets
# Edit with your AWS/HF/CivitAI keys

# 6. Run startup (creates venv, installs PyTorch, ComfyUI, pulls models from S3)
bash ai-setup/scripts/startup.sh
```

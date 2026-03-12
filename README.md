# AI Server Setup — Vast.ai H200 Instance

This repo is the single source of truth for our Vast.ai AI server setup.
Clone it immediately after spinning up a new instance and run `scripts/startup.sh` to be fully operational.

---

## Quick Start (New Instance)

```bash
cd /workspace
git clone https://github.com/YOUR_USERNAME/ai-setup.git
cd ai-setup
bash scripts/startup.sh
```

---

## Instance Info

| Field | Value |
|-------|-------|
| Provider | Vast.ai |
| GPU | 1x NVIDIA H200 (140.4 GB VRAM) |
| CPU | AMD EPYC 9554 64-Core (32 allocated) |
| RAM | 193.5 GB (2 GB allocated to container overhead) |
| CUDA | 12.9 (max 13.1) |
| PyTorch | 2.9.1+cu128 |
| Python | 3.12.12 |
| Base Image | `vastai/comfy_v0.15.1-cuda-12.9-py312` |
| Instance ID | 32752468 |
| Machine ID | 53973 |
| Datacenter | 355522 |
| Public IP | 212.247.220.158 |
| Cost | ~$2.49/hr (running) |
| Volume ID | Local-32752467 |

> **Note:** The IP address and Instance ID change every time you spin up a new instance.
> The GPU/machine may also change unless you use the same `Machine ID 53973` in your Vast.ai template.

---

## Storage — The Most Important Thing to Understand

This is a Docker container. There are **two storage areas** and understanding the difference will save you from losing work.

### `/workspace` — PERSISTENT (2 TB) ✅ SAFE
- Mounted from a physical block device (`Local-32752467`) on the host machine
- **Survives instance stop/start and re-creation**
- You pay for this storage 24/7 even when the server is off
- This is where ALL models, custom nodes, outputs, and your work should live
- **HuggingFace cache is here**: `/workspace/.hf_home`
- **ComfyUI is here**: `/workspace/ComfyUI`

### `/` (Container Root) — EPHEMERAL (200 GB) ⚠️ LOST ON STOP
- The Docker container's overlay filesystem
- **DESTROYED when you stop or terminate the instance**
- Contains the OS, Python venv (`/venv/main`), CUDA tools
- The base image rebuilds all of this from the Vast.ai image on each startup
- Do NOT put models or important work here

### What Survives a Stop/Start?

| Location | Persists? | Notes |
|----------|-----------|-------|
| `/workspace/*` | ✅ Yes | Your persistent volume |
| `/workspace/ComfyUI/` | ✅ Yes | ComfyUI code, models, nodes, outputs |
| `/workspace/.hf_home/` | ✅ Yes | HuggingFace model cache |
| `/root/` | ❌ No | Home dir is rebuilt from image |
| `/venv/main/` | ❌ No | Python env is rebuilt from image |
| `/opt/` | ❌ No | System tools, rebuilt from image |
| `/tmp/` | ❌ No | Temp files |

> **The volume is "Local"**: The `Local-` prefix on our volume ID means the storage
> lives on the same physical NVMe drives as the compute. It is NOT a cloud/network volume.
> This means it can only be attached to instances running on Machine ID 53973.
> If you ever rent a different machine, you'd need to migrate the volume data.

---

## Directory Map

```
/workspace/                          ← EVERYTHING important lives here
├── ComfyUI/                         ← Main ComfyUI installation
│   ├── models/                      ← All model weights
│   │   ├── checkpoints/             ← Stable Diffusion checkpoints (.safetensors)
│   │   ├── diffusion_models/        ← Flux, WAN Video, etc.
│   │   ├── text_encoders/           ← T5, CLIP text encoders
│   │   ├── vae/                     ← VAE models
│   │   ├── loras/                   ← LoRA weights
│   │   ├── controlnet/              ← ControlNet models
│   │   └── upscale_models/          ← ESRGAN, etc.
│   ├── custom_nodes/                ← Installed custom node extensions
│   │   └── ComfyUI-Manager/         ← Node manager (pre-installed)
│   ├── output/                      ← Generated images/videos go here
│   ├── input/                       ← Input images/videos
│   └── user/                        ← ComfyUI user data, saved workflows
├── .hf_home/                        ← HuggingFace model cache (HF_HOME)
├── .venv-backups/                   ← venv snapshot backups
└── ai-setup/                        ← THIS REPO
    ├── README.md                    ← You are here
    ├── docs/                        ← Detailed documentation
    ├── scripts/                     ← Startup and setup scripts
    ├── comfyui/                     ← Our ComfyUI config and workflows
    └── provisioning/                ← Vast.ai provisioning scripts

/opt/workspace-internal/ComfyUI/     ← READ-ONLY base ComfyUI from Docker image
/opt/model_store/                    ← Pre-baked models from base image (small set)
/venv/main/                          ← Python virtual environment (EPHEMERAL)
```

---

## Services & Access

When the instance is running, these services are available through the instance's public IP.
All ports are mapped through Vast.ai's port forwarding.

| Service | External Port | URL Pattern |
|---------|--------------|-------------|
| **ComfyUI** | 8188 | `http://212.247.220.158:PORT` |
| **Jupyter Lab** | 8080 | `http://212.247.220.158:PORT` |
| **Instance Portal** | 1111 | `http://212.247.220.158:PORT` |
| **API Wrapper** | 8288 | `http://212.247.220.158:PORT/docs` |
| **Syncthing** | 8384 | `http://212.247.220.158:PORT` |

> The external ports change with each new instance. Find the actual mapped ports in
> the Vast.ai console under your instance's "Connect" info, or check `/etc/portal.yaml`.

---

## What's Pre-Installed (Base Image)

The `vastai/comfy_v0.15.1-cuda-12.9-py312` image provides:

- **PyTorch** 2.9.1+cu128 (CUDA 12.8)
- **xformers** 0.0.33
- **transformers** 5.2.0
- **ComfyUI** v0.15.1 (synced to `/workspace/ComfyUI` on first boot)
- **ComfyUI-Manager** (pre-installed custom node)
- **Jupyter Lab** (accessible on port 8080)
- **Syncthing** (for file sync)
- **Conda/Miniforge** at `/opt/miniforge3`
- **NVM + Node.js** v24.12.0
- **Vast CLI** at `/opt/vast-cli`

---

## Environment Variables (Key Ones)

```bash
DATA_DIRECTORY=/workspace/
HF_HOME=/workspace/.hf_home
COMFYUI_ARGS=--disable-auto-launch --disable-xformers --port 18188 --enable-cors-header
CONDA_PREFIX=/venv/main
CUDA_HOME=/usr/local/cuda
PYTORCH_BACKEND=cu128
```

---

## How the Instance Starts Up

1. Vast.ai pulls the Docker image and starts the container
2. `/workspace` is mounted from the persistent volume
3. If `/workspace/ComfyUI` doesn't exist, it's copied from `/opt/workspace-internal/ComfyUI`
4. The provisioning script is downloaded and run (URL in `PROVISIONING_SCRIPT` env var)
5. ComfyUI starts on internal port 18188 (mapped to external 8188)
6. Jupyter starts on port 8080

The `PROVISIONING_SCRIPT` env var (set in your Vast.ai instance template) controls what
gets installed at boot. Point this to your own script to automate everything.

---

## SSH Access

```bash
ssh root@212.247.220.158 -p SSH_PORT
```

> SSH port changes with each instance. Find it in the Vast.ai console.
> Public key is set via the Vast.ai account SSH key settings.

---

## Docs Index

- [docs/storage-guide.md](docs/storage-guide.md) — Deep dive on storage
- [docs/comfyui-setup.md](docs/comfyui-setup.md) — ComfyUI configuration and nodes
- [docs/wan-video-setup.md](docs/wan-video-setup.md) — WAN Video 2.2 installation guide
- [docs/models-inventory.md](docs/models-inventory.md) — What models we have and where

---

## Repo Setup (First Time)

```bash
cd /workspace/ai-setup
git init
git remote add origin https://github.com/YOUR_USERNAME/ai-setup.git
git add .
git commit -m "Initial setup documentation"
git push -u origin main
```

Then in your Vast.ai instance template, set:
- **On-start script**: `cd /workspace && git clone https://github.com/YOUR_USERNAME/ai-setup.git || (cd ai-setup && git pull) && bash ai-setup/scripts/startup.sh`

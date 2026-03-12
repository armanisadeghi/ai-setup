# Storage Guide — Vast.ai Instance

## TL;DR

**Only put things you want to keep in `/workspace/`.**
Everything else is wiped when the instance stops.

---

## Physical Storage on This Machine

The host machine has 5x NVMe drives totaling ~18TB:
- `nvme0n1`, `nvme1n1`, `nvme4n1`, `nvme5n1` — 3.5TB each (used for Docker)
- `nvme2n1 + nvme3n1` — RAID-1 mirror (~1.7TB) used for the OS/nvidia drivers

The container gets access to this via two mechanisms:

### 1. Container Root Filesystem (`/`) — Ephemeral

```
overlay   200G  584M  200G   1%  /
```

- 200 GB allocated to this container from host NVMe pool
- Docker overlay filesystem (reads from image layers, writes to a top layer)
- **Completely gone** when the instance is stopped/terminated
- Fast (direct NVMe), but temporary

### 2. Workspace Volume (`/workspace`) — Persistent

```
/dev/mapper/vgdocker-lv_docker   2.0T   6.8G   2.0T   1%   /workspace
```

- 2 TB XFS filesystem on LVM (`vgdocker-lv_docker`)
- Mounted directly into the container
- **Survives instance stop and restart**
- Volume ID: `Local-32752467`
- You pay for the storage 24/7 regardless of whether the instance is running

---

## The "Local" Volume Explained

Our volume ID starts with `Local-`. This is Vast.ai's terminology meaning:

- The storage is on the **same physical host** as the compute (Machine ID 53973)
- It is NOT a cloud/network storage (no `cloud-` prefix)
- This is faster (direct NVMe, ~17,000 MB/s) than a network volume would be
- **Limitation**: This volume can ONLY be mounted to instances on Machine ID 53973

If that machine becomes unavailable, you would need to rent a different machine and
either migrate the data or accept re-downloading models. For truly portable storage,
Vast.ai offers cloud volumes (slower but machine-agnostic).

---

## Shared Memory

```
shm   94G   0   94G   0%   /dev/shm
```

94 GB of shared memory (`/dev/shm`) is available. This is useful for:
- Large model inference (can use it as RAM overflow)
- Inter-process communication
- Temporary fast storage within a session

---

## Current Disk Usage

As of initial setup:
- `/workspace` total: 2.0 TB
- Used: ~6.8 GB (just ComfyUI code, one checkpoint)
- Available for models: ~1.99 TB

### Model Size Reference

| Model | Size | Notes |
|-------|------|-------|
| WAN Video 2.2 (720p) | ~26 GB | Main diffusion weights |
| WAN Video 2.2 (480p) | ~26 GB | Same model, different config |
| WAN Video CLIP | ~1.3 GB | Text encoder |
| WAN Video T5-XXL | ~10 GB | Text encoder |
| WAN Video VAE | ~400 MB | VAE |
| Flux.1-dev | ~24 GB | Diffusion model |
| SD XL Base | ~6.9 GB | Already installed! |
| SD 1.5 | ~2 GB | Symlinked from model_store |

With 1.99 TB available, there is plenty of space.

---

## What Happens on Each Boot

```
Instance starts
    → Docker image pulled/reused
    → /workspace volume mounted
    → /workspace/ComfyUI exists? → No → copy from /opt/workspace-internal/ComfyUI
    → Provisioning script runs (PROVISIONING_SCRIPT env var)
    → ComfyUI launches on port 18188
    → Jupyter launches on port 8080
```

The key insight: ComfyUI and all models in `/workspace/ComfyUI/` are there on each boot
because they're on the persistent volume. The Python environment (`/venv/main`) is
rebuilt from the Docker image each time, but since it's the same image, packages
are already there.

---

## HuggingFace Cache

HuggingFace models are cached at `/workspace/.hf_home` (set via `HF_HOME` env var).
This means any model downloaded via `huggingface_hub` or `transformers` will persist
between sessions and not need to be re-downloaded.

If you use `from_pretrained()` in Python, models are cached here automatically.

---

## Recommendations

### Do store in `/workspace/`:
- All model weights (`.safetensors`, `.ckpt`, `.pt`, `.bin`, `.gguf`)
- ComfyUI custom nodes
- ComfyUI workflows (they're already in `/workspace/ComfyUI/user/`)
- Generated outputs you want to keep
- Python scripts, notebooks
- This repo (`/workspace/ai-setup/`)

### Do NOT rely on (outside `/workspace/`):
- Pip packages installed outside the base venv (they'll be gone on restart)
- Files in `/root/`, `/tmp/`, `/opt/` (except model_store which is read-only base)
- Anything written to the container root filesystem

### For pip packages you need permanently:
Add them to `scripts/startup.sh` in this repo so they get installed on each boot,
OR add them to your Vast.ai provisioning script.

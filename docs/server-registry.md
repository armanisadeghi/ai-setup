# Server Registry

All known GPU server instances used with this repo.

---

## Server 1 — Vast.ai H200 (Original)

| Field | Value |
|-------|-------|
| **Provider** | Vast.ai |
| **Machine ID** | 53973 |
| **GPU** | 1x NVIDIA H200 140GB HBM3e |
| **CPU** | AMD EPYC 9124 (16 cores) |
| **RAM** | ~250 GiB |
| **Disk** | ~2 TB persistent (`/workspace`) |
| **CUDA** | 12.9 |
| **Base Image** | `vastai/comfy_v0.15.1-cuda-12.9-py312` |
| **Python** | 3.12 (in `/venv/main`) |
| **OS** | Docker container (Ubuntu-based) |
| **Location** | N/A |
| **Cost** | ~$2.49/hr |
| **Status** | On-demand (not always running) |

### Paths (Vast.ai)
- WORKSPACE: `/workspace`
- VENV: `/venv/main`
- ComfyUI: `/workspace/ComfyUI`
- Secrets: `/workspace/.env_secrets`

### Access
- SSH port and IP assigned dynamically by Vast.ai per instance
- ComfyUI exposed on dynamically assigned port

### Notes
- Docker-based with persistent `/workspace` volume survives reboots
- Uses `provisioning/provisioning.sh` as Vast.ai on-start script
- supervisord manages ComfyUI process

---

## Server 2 — Prague A100 (Custom VM)

| Field | Value |
|-------|-------|
| **Provider** | Custom VM provider |
| **Instance ID** | `db7c1932-82c0-4ca3-a98b-bcb6f9f549e7` |
| **GPU** | 1x NVIDIA A100-SXM4-80GB |
| **CPU** | 8 cores |
| **RAM** | 128 GiB |
| **Disk** | 100 GiB (single volume, no separate persistent storage) |
| **CUDA** | 12.6 |
| **PyTorch** | 2.10.0+cu126 |
| **Python** | 3.12.3 |
| **OS** | Ubuntu 24.04.4 LTS (bare metal, no Docker) |
| **Location** | Prague, Czech Republic |
| **Public IP** | 80.188.223.202 |
| **Cost** | ~$1.145/hr |
| **Status** | Active (as of 2025) |

### Port Forwards

| Service | Internal Port | External Port |
|---------|--------------|---------------|
| SSH | 22 | 10218 |
| ComfyUI | 8188 | 10246 |
| API (8000) | 8000 | 10241 |
| API (8001) | 8001 | 10242 |
| Web (8080) | 8080 | 10243 |
| Web (3000) | 3000 | 10244 |
| Web (3001) | 3001 | 10245 |
| Jupyter | 8888 | 10219 |

### Paths (Prague A100)
- WORKSPACE: `/home/user/workspace`
- VENV: `/home/user/workspace/.venv`
- ComfyUI: `/home/user/workspace/ComfyUI`
- Repo: `/home/user/ai-setup`
- Secrets: `/home/user/workspace/.env_secrets`

### Services
- ComfyUI runs as systemd service (`comfyui.service`), auto-starts on boot
- `sudo systemctl status|restart|stop comfyui`
- Logs: `journalctl -u comfyui -f` or `tail -f /home/user/workspace/comfyui.log`

### Installed Models (as of initial setup)

| Model | Size |
|-------|------|
| WAN 2.2 T2V 14B fp8 (high noise) | 14.3 GB |
| WAN 2.2 T2V 14B fp8 (low noise) | 14.3 GB |
| WAN 2.2 5B combo (fp16) | 10.0 GB |
| UMT5-XXL fp8 text encoder | 6.7 GB |
| WAN 2.2 VAE | 1.4 GB |
| WAN 2.1 VAE | 0.25 GB |
| CLIP Vision H | 1.3 GB |

### Disk Budget (100 GiB total)

| Component | Size |
|-----------|------|
| OS + CUDA + packages | ~16 GiB |
| Python venv (PyTorch) | ~8 GiB |
| ComfyUI + custom nodes | ~1 GiB |
| WAN 2.2 models (fp8) | ~45 GiB |
| **Free** | **~29 GiB** |

### Notes
- No Docker — bare Ubuntu with systemd
- Single 100 GiB disk — disk budget is tight, rely on S3 for persistence
- SSH: `ssh -p 10218 user@80.188.223.202`

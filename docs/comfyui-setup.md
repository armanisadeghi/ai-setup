# ComfyUI Setup Guide

## Installation Status

ComfyUI is **already installed** at `/workspace/ComfyUI` from the base image.
Version: 0.15.1 (as of instance creation)

The instance uses `vastai/comfy_v0.15.1-cuda-12.9-py312` which pre-installs ComfyUI
into the workspace volume on first boot.

---

## Key Paths

```
/workspace/ComfyUI/
├── main.py                   ← ComfyUI entry point
├── models/
│   ├── checkpoints/          ← SD checkpoints (.safetensors, .ckpt)
│   ├── diffusion_models/     ← Flux, WAN Video, etc.
│   ├── text_encoders/        ← T5, CLIP text encoders for Flux/WAN
│   ├── clip/                 ← CLIP models
│   ├── vae/                  ← VAE models
│   ├── loras/                ← LoRA models
│   ├── controlnet/           ← ControlNet models
│   ├── upscale_models/       ← ESRGAN upscalers
│   ├── audio_encoders/       ← Audio models (for video w/ audio)
│   └── configs/              ← Model config files
├── custom_nodes/
│   └── ComfyUI-Manager/      ← Already installed!
├── output/                   ← Generated images/videos saved here
├── input/                    ← Drop input images/videos here
└── user/
    └── default/
        └── workflows/        ← Saved workflows
```

---

## Currently Installed Models

| Model | Path | Size | Notes |
|-------|------|------|-------|
| realvisxlV50 Lightning | `checkpoints/realvisxlV50_v50LightningBakedvae.safetensors` | 6.6 GB | Fast XL model |
| SD 1.5 fp16 | `checkpoints/v1-5-pruned-emaonly-fp16.safetensors` | ~2 GB | Symlink to /opt/model_store |

---

## Running ComfyUI

ComfyUI starts automatically when the instance boots. Startup args:
```
--disable-auto-launch --disable-xformers --port 18188 --enable-cors-header
```

If you need to restart it manually:
```bash
cd /workspace/ComfyUI
source /venv/main/bin/activate
python main.py --disable-auto-launch --disable-xformers --port 18188 --enable-cors-header
```

Or use the supervisor:
```bash
supervisorctl restart comfyui
```

---

## Custom Nodes

### Pre-installed
- **ComfyUI-Manager** — Install/update other nodes from UI

### Installing Additional Nodes

**Method 1: Via ComfyUI-Manager UI** (recommended for one-off installs)
- Open ComfyUI in browser → Manager button → Install Custom Nodes

**Method 2: Via startup script** (recommended for nodes that should always be present)
Add to `scripts/startup.sh`:
```bash
cd /workspace/ComfyUI/custom_nodes
git clone https://github.com/AUTHOR/NODE_NAME
pip install -r NODE_NAME/requirements.txt
```

**Method 3: Via Vast.ai provisioning script**
Add to `provisioning/provisioning.sh` in the `NODES` array.

### Our Custom Node List

See [../comfyui/custom_nodes.txt](../comfyui/custom_nodes.txt) for the complete list
of nodes we install. The startup script handles cloning/updating all of them.

---

## Updating ComfyUI

```bash
cd /workspace/ComfyUI
git pull
pip install -r requirements.txt
```

> ⚠️ The `/workspace/ComfyUI` directory is under git tracking from the official
> ComfyUI repo. Don't push to it. If you want to track your ComfyUI config
> separately, use the `comfyui/` folder in this repo.

---

## extra_model_paths.yaml

To tell ComfyUI to also look for models in custom directories, create:
```
/workspace/ComfyUI/extra_model_paths.yaml
```

See [../comfyui/extra_model_paths.yaml](../comfyui/extra_model_paths.yaml) for our
config. The startup script copies this to the right place.

---

## ComfyUI API

The API wrapper is available at port 8288. Swagger docs at `/docs`.

Direct ComfyUI API: `http://INSTANCE_IP:8188/api/`

```bash
# Check if ComfyUI is running
curl http://localhost:18188/system_stats
```

---

## Workflow Backups

Workflows created in ComfyUI are saved to:
```
/workspace/ComfyUI/user/default/workflows/
```

To back them up to this repo:
```bash
cp /workspace/ComfyUI/user/default/workflows/*.json /workspace/ai-setup/comfyui/workflows/
cd /workspace/ai-setup
git add comfyui/workflows/
git commit -m "Backup workflows"
git push
```

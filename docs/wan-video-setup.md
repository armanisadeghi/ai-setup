# WAN Video 2.2 — ComfyUI Setup Guide

WAN Video 2.2 (Wan2.2) is Alibaba's video generation model. It runs natively in ComfyUI
via custom nodes. The H200 with 140GB VRAM is ideal for it.

---

## Models Required

All models go in `/workspace/ComfyUI/models/` subdirectories.
Total download size: ~38 GB for the full 720p setup.

### WAN 2.2 T2V (Text to Video) — 720p

| File | Destination | Size | Source |
|------|-------------|------|--------|
| `Wan2.2-T2V-14B-...` | `diffusion_models/` | ~26 GB | HuggingFace |
| `umt5-xxl-enc-bf16.pth` | `text_encoders/` | ~10 GB | HuggingFace |
| `clip_vision_h.pth` | `clip_vision/` | ~0.6 GB | HuggingFace |
| `Wan2.2_VAE.pth` | `vae/` | ~0.4 GB | HuggingFace |

### WAN 2.2 I2V (Image to Video)

| File | Destination | Size | Source |
|------|-------------|------|--------|
| `Wan2.2-I2V-14B-...` | `diffusion_models/` | ~26 GB | HuggingFace |
| (same text encoder/vae as T2V above) | | | |

---

## Required Custom Nodes

These nodes provide WAN Video support in ComfyUI.
The startup script will install them automatically.

### Option A: Native ComfyUI WAN nodes (recommended for 2.2)
ComfyUI 0.15.1+ has built-in support for WAN via the standard video generation nodes.
No extra node required if using latest ComfyUI.

### Option B: ComfyUI-WanVideoWrapper (community node)
```bash
cd /workspace/ComfyUI/custom_nodes
git clone https://github.com/kijai/ComfyUI-WanVideoWrapper
pip install -r ComfyUI-WanVideoWrapper/requirements.txt
```

### VideoHelperSuite (for video input/output handling)
```bash
cd /workspace/ComfyUI/custom_nodes
git clone https://github.com/Kosinkadink/ComfyUI-VideoHelperSuite
pip install -r ComfyUI-VideoHelperSuite/requirements.txt
```

---

## Download Script

Run this to download all WAN 2.2 models:

```bash
bash /workspace/ai-setup/scripts/download-wan-video.sh
```

Or manually:

```bash
# Activate venv
source /venv/main/bin/activate

# Install huggingface_hub if needed
pip install huggingface_hub

# Download WAN 2.2 T2V model (720p)
python3 -c "
from huggingface_hub import snapshot_download
snapshot_download(
    repo_id='Wan-AI/Wan2.2-T2V-14B',
    local_dir='/workspace/ComfyUI/models/diffusion_models/Wan2.2-T2V-14B'
)
"

# Download text encoder (T5-XXL)
python3 -c "
from huggingface_hub import hf_hub_download
hf_hub_download(
    repo_id='Comfy-Org/Wan_2.1_ComfyUI_repackaged',
    filename='split_files/text_encoders/umt5_xxl_fp8_e4m3fn_scaled.safetensors',
    local_dir='/workspace/ComfyUI/models/text_encoders/'
)
"
```

> Note: Exact filenames may vary. Check the HuggingFace repo pages for current files:
> - https://huggingface.co/Wan-AI/Wan2.2-T2V-14B
> - https://huggingface.co/Wan-AI/Wan2.2-I2V-14B

---

## VRAM Requirements

| Mode | VRAM | Notes |
|------|------|-------|
| 720p T2V, full precision | ~40-60 GB | Comfortable on H200 (140GB) |
| 720p T2V, fp8 quantized | ~18-20 GB | Even faster |
| 480p T2V | ~18-25 GB | |
| I2V | ~40-60 GB | |

The H200 with 140 GB VRAM can run WAN in full precision without any quantization tricks.

---

## Basic Workflow

1. Open ComfyUI in browser
2. Load a WAN Video workflow (see `comfyui/workflows/wan-video-t2v.json`)
3. Set your positive and negative prompts
4. Set resolution (720x480 or 1280x720) and frame count (typically 81 frames = ~3s at 24fps)
5. Queue prompt

### Recommended Settings for H200

```
Resolution: 1280x720
Frames: 81 (3.375 seconds at 24fps) or 121 (5s)
Steps: 20-30
CFG: 4.0-7.0
Sampler: euler or dpm++
```

---

## Output Videos

Generated videos are saved to:
```
/workspace/ComfyUI/output/
```

To download them, use:
- Jupyter Lab file browser (port 8080)
- `scp root@IP:PORT:/workspace/ComfyUI/output/VIDEO.mp4 ./`
- Syncthing (port 8384) for continuous sync

---

## Troubleshooting

**Out of memory / OOM error**
- Use fp8 quantized models instead of full fp16
- Reduce batch size or frame count
- Add `--lowvram` or `--medvram` to `COMFYUI_ARGS` (not needed on H200 usually)

**Video is choppy or artifacts**
- Increase steps (try 30-50)
- Reduce CFG scale slightly

**"Model not found" errors**
- Check model path in ComfyUI node matches actual file location
- Restart ComfyUI after moving models (it rescans on start)

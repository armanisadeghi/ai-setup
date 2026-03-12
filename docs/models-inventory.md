# Models Inventory

Track all models downloaded to this instance's persistent storage.
Update this file when you add or remove models.

Last updated: 2026-03-12

---

## Checkpoints (`/workspace/ComfyUI/models/checkpoints/`)

| Filename | Type | Size | Source | Notes |
|----------|------|------|--------|-------|
| `realvisxlV50_v50LightningBakedvae.safetensors` | SDXL | 6.6 GB | CivitAI (798204) | Fast lightning model, baked VAE |
| `v1-5-pruned-emaonly-fp16.safetensors` | SD1.5 | ~2 GB | HuggingFace | Symlink to /opt/model_store |

## Diffusion Models (`/workspace/ComfyUI/models/diffusion_models/`)

| Filename | Type | Size | Source | Notes |
|----------|------|------|--------|-------|
| _(none yet)_ | | | | See WAN video setup guide |

## Text Encoders (`/workspace/ComfyUI/models/text_encoders/`)

| Filename | Type | Size | Source | Notes |
|----------|------|------|--------|-------|
| _(none yet)_ | | | | |

## VAE (`/workspace/ComfyUI/models/vae/`)

| Filename | Type | Size | Source | Notes |
|----------|------|------|--------|-------|
| _(none yet)_ | | | | |

## LoRA (`/workspace/ComfyUI/models/loras/`)

| Filename | Type | Size | Source | Notes |
|----------|------|------|--------|-------|
| _(none yet)_ | | | | |

## Upscale Models (`/workspace/ComfyUI/models/upscale_models/`)

| Filename | Type | Size | Source | Notes |
|----------|------|------|--------|-------|
| _(none yet)_ | | | | |

---

## Storage Usage Summary

```
/workspace/ComfyUI/models/   ~6.8 GB currently
/workspace/.hf_home/         ~0 GB (no HF models yet)
/workspace/ total used:      ~6.8 GB / 2.0 TB
```

Run this to get current usage:
```bash
du -sh /workspace/ComfyUI/models/*/
du -sh /workspace/.hf_home/
df -h /workspace
```

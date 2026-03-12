#!/bin/bash
# =============================================================================
# download-wan-video.sh — Download WAN Video 2.2 models
#
# Run once after setting up the instance.
# Models are saved to /workspace/ComfyUI/models/ (persistent storage).
#
# Estimated download sizes:
#   T2V 14B model: ~26 GB
#   T5-XXL text encoder: ~10 GB
#   CLIP vision: ~0.6 GB
#   VAE: ~0.4 GB
#   Total: ~37 GB
# =============================================================================

set -e

source /venv/main/bin/activate

COMFYUI_MODELS="/workspace/ComfyUI/models"

echo "============================================="
echo "  WAN Video 2.2 Model Downloader"
echo "  $(date)"
echo "============================================="
echo ""
echo "Storage available:"
df -h /workspace | tail -1
echo ""

# Ensure destination dirs exist
mkdir -p "$COMFYUI_MODELS/diffusion_models"
mkdir -p "$COMFYUI_MODELS/text_encoders"
mkdir -p "$COMFYUI_MODELS/clip_vision"
mkdir -p "$COMFYUI_MODELS/vae"

# Install huggingface_hub if needed
pip install --quiet huggingface_hub hf_transfer

# Enable faster transfers
export HF_HUB_ENABLE_HF_TRANSFER=1

echo "--- Downloading WAN 2.2 T2V 14B (Text-to-Video) ---"
echo "NOTE: This is ~26 GB. Go get a coffee."
python3 << 'EOF'
from huggingface_hub import snapshot_download
import os

# WAN 2.2 T2V — Text to Video (720p capable)
# Check https://huggingface.co/Wan-AI for the exact repo name
print("Downloading Wan2.2-T2V-14B diffusion model...")
snapshot_download(
    repo_id="Wan-AI/Wan2.2-T2V-14B",
    local_dir="/workspace/ComfyUI/models/diffusion_models/Wan2.2-T2V-14B",
    ignore_patterns=["*.md", "*.txt", "*.py"],
)
print("✓ T2V model downloaded")
EOF

echo ""
echo "--- Downloading Text Encoders (Comfy-Org repackaged) ---"
python3 << 'EOF'
from huggingface_hub import hf_hub_download

# T5-XXL text encoder (fp8, smaller but quality loss minimal)
print("Downloading T5-XXL text encoder (fp8)...")
hf_hub_download(
    repo_id="Comfy-Org/Wan_2.1_ComfyUI_repackaged",
    filename="split_files/text_encoders/umt5_xxl_fp8_e4m3fn_scaled.safetensors",
    local_dir="/workspace/ComfyUI/models/text_encoders/",
)
print("✓ T5-XXL downloaded")

# CLIP vision encoder
print("Downloading CLIP vision encoder...")
hf_hub_download(
    repo_id="Comfy-Org/Wan_2.1_ComfyUI_repackaged",
    filename="split_files/clip_vision/clip_vision_h.safetensors",
    local_dir="/workspace/ComfyUI/models/clip_vision/",
)
print("✓ CLIP vision downloaded")

# VAE
print("Downloading VAE...")
hf_hub_download(
    repo_id="Comfy-Org/Wan_2.1_ComfyUI_repackaged",
    filename="split_files/vae/wan_2.1_vae.safetensors",
    local_dir="/workspace/ComfyUI/models/vae/",
)
print("✓ VAE downloaded")
EOF

echo ""
echo "============================================="
echo "  Download Complete!"
echo "============================================="
echo ""
du -sh "$COMFYUI_MODELS/diffusion_models/"
du -sh "$COMFYUI_MODELS/text_encoders/"
du -sh "$COMFYUI_MODELS/clip_vision/"
du -sh "$COMFYUI_MODELS/vae/"
echo ""
echo "Restart ComfyUI to pick up the new models:"
echo "  supervisorctl restart comfyui"
echo "  OR"
echo "  Refresh ComfyUI in your browser"
echo ""

# Update inventory reminder
echo "Don't forget to update docs/models-inventory.md with the new models!"

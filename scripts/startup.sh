#!/bin/bash
# =============================================================================
# startup.sh — Master startup script for Vast.ai H200 instance
#
# Run this after spinning up a new instance:
#   bash /workspace/ai-setup/scripts/startup.sh
#
# This script is idempotent — safe to run multiple times.
# =============================================================================

set -e

WORKSPACE="/workspace"
COMFYUI_DIR="$WORKSPACE/ComfyUI"
REPO_DIR="$WORKSPACE/ai-setup"
VENV="$CONDA_PREFIX"

echo "============================================="
echo "  AI Server Startup Script"
echo "  $(date)"
echo "============================================="

# --- Restore Git Config (ephemeral /root is wiped on restart) ---
git config --global user.name "Arman Isadeghi"
git config --global user.email "arman@armansadeghi.com"
git config --global credential.helper "store --file /workspace/.git-credentials"
echo "[✓] Git identity restored"

# Activate Python environment
source /venv/main/bin/activate
echo "[✓] Python environment: $(python3 --version)"
echo "[✓] VENV: $VIRTUAL_ENV"

# --- GPU Check ---
echo ""
echo "--- GPU Status ---"
nvidia-smi --query-gpu=name,memory.total,memory.free,temperature.gpu --format=csv,noheader 2>/dev/null || echo "nvidia-smi not available"

# --- Install Custom Nodes ---
echo ""
echo "--- Installing/Updating Custom Nodes ---"
bash "$REPO_DIR/scripts/install-custom-nodes.sh"

# --- Copy ComfyUI Config Files ---
echo ""
echo "--- Applying ComfyUI Config ---"
if [ -f "$REPO_DIR/comfyui/extra_model_paths.yaml" ]; then
    cp "$REPO_DIR/comfyui/extra_model_paths.yaml" "$COMFYUI_DIR/extra_model_paths.yaml"
    echo "[✓] Copied extra_model_paths.yaml"
fi

# --- Install Additional Python Packages ---
echo ""
echo "--- Installing Additional Python Packages ---"
bash "$REPO_DIR/scripts/install-packages.sh"

# --- Sync Workflows from Repo ---
echo ""
echo "--- Syncing Workflows ---"
if [ -d "$REPO_DIR/comfyui/workflows" ]; then
    mkdir -p "$COMFYUI_DIR/user/default/workflows"
    cp -n "$REPO_DIR/comfyui/workflows/"*.json "$COMFYUI_DIR/user/default/workflows/" 2>/dev/null || true
    echo "[✓] Workflows synced (existing files not overwritten)"
fi

# --- Print Status ---
echo ""
echo "============================================="
echo "  Startup Complete!"
echo "============================================="
echo ""
echo "Workspace usage:"
df -h /workspace | tail -1
echo ""
echo "Model storage:"
du -sh "$COMFYUI_DIR/models"/ 2>/dev/null | sort -h || true
echo ""
echo "ComfyUI running? Check:"
echo "  curl http://localhost:18188/system_stats"
echo ""
echo "Access ComfyUI: http://$(cat /etc/forward_host 2>/dev/null || echo 'IP'):$(cat /etc/forward_port 2>/dev/null || echo '8188')"
echo ""

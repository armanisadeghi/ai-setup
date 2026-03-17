#!/bin/bash
# =============================================================================
# startup.sh — Master startup script for GPU instance
#
# Run this after spinning up a new instance or after a reboot:
#   bash /home/user/ai-setup/scripts/startup.sh
#
# This script is idempotent — safe to run multiple times.
# =============================================================================

set -e

WORKSPACE="/home/user/workspace"
COMFYUI_DIR="$WORKSPACE/ComfyUI"
REPO_DIR="/home/user/ai-setup"
VENV="$WORKSPACE/.venv"

echo "============================================="
echo "  AI Server Startup Script"
echo "  $(date)"
echo "============================================="

# --- Load Secrets ---
if [ -f "$WORKSPACE/.env_secrets" ]; then
    source "$WORKSPACE/.env_secrets"
    echo "[OK] Secrets loaded from $WORKSPACE/.env_secrets"
else
    echo "[!] WARNING: $WORKSPACE/.env_secrets not found"
    echo "    Create it with your AWS/HF/CivitAI keys"
fi

# --- Git Config ---
git config --global user.name "Arman Isadeghi"
git config --global user.email "arman@armansadeghi.com"
echo "[OK] Git identity configured"

# --- Activate Python environment ---
if [ -d "$VENV" ]; then
    source "$VENV/bin/activate"
    echo "[OK] Python environment: $(python3 --version)"
else
    echo "[!] No venv found at $VENV — creating one..."
    python3 -m venv "$VENV"
    source "$VENV/bin/activate"
    pip install --upgrade pip setuptools wheel
    pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu126
    echo "[OK] Created new venv with PyTorch"
fi

# --- GPU Check ---
echo ""
echo "--- GPU Status ---"
nvidia-smi --query-gpu=name,memory.total,memory.free,temperature.gpu --format=csv,noheader 2>/dev/null || echo "nvidia-smi not available"

# --- Ensure ComfyUI is installed ---
if [ ! -d "$COMFYUI_DIR" ]; then
    echo "[!] ComfyUI not found — cloning..."
    cd "$WORKSPACE"
    git clone https://github.com/comfyanonymous/ComfyUI.git
    cd "$COMFYUI_DIR"
    pip install -r requirements.txt
fi

# --- Install Custom Nodes ---
echo ""
echo "--- Installing/Updating Custom Nodes ---"
bash "$REPO_DIR/scripts/install-custom-nodes.sh"

# --- Copy ComfyUI Config Files ---
echo ""
echo "--- Applying ComfyUI Config ---"
if [ -f "$REPO_DIR/comfyui/extra_model_paths.yaml" ]; then
    cp "$REPO_DIR/comfyui/extra_model_paths.yaml" "$COMFYUI_DIR/extra_model_paths.yaml"
    echo "[OK] Copied extra_model_paths.yaml"
fi

# --- Sync Workflows from Repo ---
echo ""
echo "--- Syncing Workflows ---"
if [ -d "$REPO_DIR/comfyui/workflows" ]; then
    mkdir -p "$COMFYUI_DIR/user/default/workflows"
    cp -n "$REPO_DIR/comfyui/workflows/"*.json "$COMFYUI_DIR/user/default/workflows/" 2>/dev/null || true
    echo "[OK] Workflows synced (existing files not overwritten)"
fi

# --- Sync models from S3 (if configured) ---
echo ""
echo "--- S3 Model Sync ---"
if [ -n "$AWS_ACCESS_KEY_ID" ] && [ -n "$S3_BUCKET" ]; then
    echo "Checking S3 for models..."
    bash "$REPO_DIR/scripts/s3-sync.sh" pull 2>&1 || echo "[!] S3 sync failed or skipped"
else
    echo "[!] AWS credentials not configured — skipping S3 sync"
    echo "    Set credentials in $WORKSPACE/.env_secrets"
fi

# --- Start ComfyUI ---
echo ""
echo "--- Starting ComfyUI ---"
COMFYUI_PID=$(pgrep -f "python.*main.py.*8188" || true)
if [ -n "$COMFYUI_PID" ]; then
    echo "[OK] ComfyUI already running (PID: $COMFYUI_PID)"
else
    cd "$COMFYUI_DIR"
    nohup "$VENV/bin/python" main.py \
        --listen 0.0.0.0 \
        --port 8188 \
        --disable-auto-launch \
        --enable-cors-header \
        > "$WORKSPACE/comfyui.log" 2>&1 &
    echo "[OK] ComfyUI started (PID: $!, log: $WORKSPACE/comfyui.log)"
fi

# --- Print Status ---
echo ""
echo "============================================="
echo "  Startup Complete!"
echo "============================================="
echo ""
echo "Disk usage:"
df -h / | tail -1
echo ""
echo "Model storage:"
du -sh "$COMFYUI_DIR/models/"*/ 2>/dev/null | grep -v "^0" | sort -h || echo "  (no models yet)"
echo ""
echo "ComfyUI: http://80.188.223.202:10246"
echo "Log:     tail -f $WORKSPACE/comfyui.log"
echo ""

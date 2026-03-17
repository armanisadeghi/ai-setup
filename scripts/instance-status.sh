#!/bin/bash
# =============================================================================
# instance-status.sh — Quick status check for the instance
# Run at any time to see what's going on
# =============================================================================

# --- Load centralized config ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../config/resolve-config.sh"

echo "============================================="
echo "  Instance Status — $(date)"
echo "============================================="

echo ""
echo "--- GPU ---"
nvidia-smi --query-gpu=name,memory.total,memory.free,memory.used,temperature.gpu,utilization.gpu --format=csv,noheader 2>/dev/null || echo "nvidia-smi unavailable"

echo ""
echo "--- Disk ---"
df -h /

echo ""
echo "--- Model Storage ---"
du -sh "$COMFYUI_DIR/models/"*/ 2>/dev/null | sort -h

echo ""
echo "--- ComfyUI ---"
curl -s "http://localhost:$COMFYUI_PORT/system_stats" 2>/dev/null | python3 -m json.tool 2>/dev/null | head -10 || echo "ComfyUI not responding on port $COMFYUI_PORT"

echo ""
echo "--- Running Processes ---"
ps aux | grep -E "comfyui|main.py|jupyter" | grep -v grep

echo ""
echo "--- Config ---"
echo "WORKSPACE:   $WORKSPACE"
echo "COMFYUI_DIR: $COMFYUI_DIR"
echo "VENV:        $VENV"
echo "REPO_DIR:    $REPO_DIR"
echo ""

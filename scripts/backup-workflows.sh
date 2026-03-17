#!/bin/bash
# =============================================================================
# backup-workflows.sh — Save ComfyUI workflows back to this repo
#
# Run this any time you create/update workflows in ComfyUI that you want
# to preserve in the git repo.
# =============================================================================

set -e

# --- Load centralized config ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../config/resolve-config.sh"

COMFYUI_WORKFLOWS="$COMFYUI_DIR/user/default/workflows"
REPO_WORKFLOWS="$REPO_DIR/comfyui/workflows"

mkdir -p "$REPO_WORKFLOWS"

if [ ! -d "$COMFYUI_WORKFLOWS" ]; then
    echo "No workflows directory found at $COMFYUI_WORKFLOWS"
    exit 0
fi

count=$(ls "$COMFYUI_WORKFLOWS"/*.json 2>/dev/null | wc -l)
echo "Found $count workflow(s) to backup"

cp "$COMFYUI_WORKFLOWS"/*.json "$REPO_WORKFLOWS/" 2>/dev/null || true

echo "Workflows copied to $REPO_WORKFLOWS"
echo ""
echo "To commit and push:"
echo "  cd $REPO_DIR"
echo "  git add comfyui/workflows/"
echo "  git commit -m 'Backup workflows $(date +%Y-%m-%d)'"
echo "  git push"

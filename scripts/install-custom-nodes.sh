#!/bin/bash
# =============================================================================
# install-custom-nodes.sh — Install/update all custom ComfyUI nodes
#
# Add nodes to the NODES array below.
# Each entry is a git repo URL.
# The script clones if not present, pulls if already cloned.
# =============================================================================

set -e

# --- Load centralized config ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../config/resolve-config.sh"

NODES_DIR="$COMFYUI_DIR/custom_nodes"

# --- Node List ---
# Add/remove nodes here. ComfyUI-Manager is pre-installed by the base image.
NODES=(
    # Video generation
    "https://github.com/kijai/ComfyUI-WanVideoWrapper"
    "https://github.com/Kosinkadink/ComfyUI-VideoHelperSuite"

    # Image utilities
    "https://github.com/cubiq/ComfyUI_essentials"

    # Workflow quality of life
    "https://github.com/pythongosssss/ComfyUI-Custom-Scripts"
    "https://github.com/rgthree/rgthree-comfy"
)

echo "[custom-nodes] Installing/updating ${#NODES[@]} nodes..."

for repo in "${NODES[@]}"; do
    # Skip commented lines (empty after eval)
    [[ -z "$repo" ]] && continue

    dir_name="${repo##*/}"
    node_path="$NODES_DIR/$dir_name"
    requirements="$node_path/requirements.txt"

    if [ -d "$node_path" ]; then
        echo "[custom-nodes] Updating: $dir_name"
        cd "$node_path"
        git pull --quiet
        cd -
    else
        echo "[custom-nodes] Installing: $dir_name"
        git clone --quiet "$repo" "$node_path"
    fi

    if [ -f "$requirements" ]; then
        echo "[custom-nodes]   Installing requirements for $dir_name"
        pip install --quiet --no-cache-dir -r "$requirements"
    fi
done

echo "[custom-nodes] Done."

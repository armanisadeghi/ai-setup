#!/bin/bash
# =============================================================================
# provisioning.sh — Vast.ai provisioning script
#
# This runs automatically every time the instance starts.
# To use this: in your Vast.ai instance template, set the "On-start Script" to the
# raw GitHub URL of this file, e.g.:
#   https://raw.githubusercontent.com/armanisadeghi/ai-setup/main/provisioning/provisioning.sh
#
# Or set the PROVISIONING_SCRIPT environment variable in your Vast.ai template.
#
# This replaces the default provisioning from vast-ai/base-image.
# NOTE: This file is Vast.ai-specific. For other providers, use scripts/startup.sh.
# =============================================================================

# On Vast.ai, /venv/main exists by default. On other platforms, fall back.
if [ -f /venv/main/bin/activate ]; then
    source /venv/main/bin/activate
elif [ -f "${WORKSPACE:-.}/.venv/bin/activate" ]; then
    source "$WORKSPACE/.venv/bin/activate"
fi

COMFYUI_DIR="${WORKSPACE}/ComfyUI"

# =============================================================================
# CONFIGURE BELOW — Add what you want installed/downloaded every boot
# =============================================================================

APT_PACKAGES=(
    # "ffmpeg"     # Uncomment if you need ffmpeg for video processing
    # "git-lfs"    # Uncomment for large file support
)

PIP_PACKAGES=(
    # "package-name"
)

NODES=(
    # Uncomment nodes you want auto-installed:
    # "https://github.com/kijai/ComfyUI-WanVideoWrapper"
    # "https://github.com/Kosinkadink/ComfyUI-VideoHelperSuite"
    # "https://github.com/cubiq/ComfyUI_essentials"
)

# Models to download on first boot (only if file doesn't already exist)
# Format: "url|destination_directory|filename"
# Leave empty if you prefer to download manually.
CHECKPOINT_MODELS=(
    # Pre-installed by base image:
    # "https://civitai.com/api/download/models/798204?type=Model&format=SafeTensor&size=full&fp=fp16"
)

UNET_MODELS=(
    # Add WAN 2.2 or other diffusion models here
)

LORA_MODELS=()
VAE_MODELS=()
ESRGAN_MODELS=()
CONTROLNET_MODELS=()

# =============================================================================
# Clone/update this setup repo on every boot
# =============================================================================
SETUP_REPO="https://github.com/armanisadeghi/ai-setup.git"
SETUP_DIR="${WORKSPACE}/ai-setup"

# =============================================================================
# DO NOT EDIT BELOW THIS LINE (unless you know what you're doing)
# =============================================================================

function provisioning_start() {
    echo "=== Provisioning Start: $(date) ==="

    # Clone or update the setup repo
    if [ -n "$SETUP_REPO" ]; then
        if [ -d "$SETUP_DIR/.git" ]; then
            echo "Updating setup repo..."
            cd "$SETUP_DIR" && git pull --quiet
        else
            echo "Cloning setup repo..."
            git clone --quiet "$SETUP_REPO" "$SETUP_DIR"
        fi
    fi

    provisioning_get_apt_packages
    provisioning_get_nodes
    provisioning_get_pip_packages

    provisioning_get_files \
        "${COMFYUI_DIR}/models/checkpoints" \
        "${CHECKPOINT_MODELS[@]}"

    provisioning_get_files \
        "${COMFYUI_DIR}/models/unet" \
        "${UNET_MODELS[@]}"

    provisioning_get_files \
        "${COMFYUI_DIR}/models/loras" \
        "${LORA_MODELS[@]}"

    provisioning_get_files \
        "${COMFYUI_DIR}/models/controlnet" \
        "${CONTROLNET_MODELS[@]}"

    provisioning_get_files \
        "${COMFYUI_DIR}/models/vae" \
        "${VAE_MODELS[@]}"

    provisioning_get_files \
        "${COMFYUI_DIR}/models/upscale_models" \
        "${ESRGAN_MODELS[@]}"

    echo "=== Provisioning Complete: $(date) ==="
}

function provisioning_get_apt_packages() {
    if [[ ${#APT_PACKAGES[@]} -gt 0 ]]; then
        apt-get install -y "${APT_PACKAGES[@]}"
    fi
}

function provisioning_get_pip_packages() {
    if [[ ${#PIP_PACKAGES[@]} -gt 0 ]]; then
        pip install --no-cache-dir "${PIP_PACKAGES[@]}"
    fi
}

function provisioning_get_nodes() {
    for repo in "${NODES[@]}"; do
        dir="${repo##*/}"
        path="${COMFYUI_DIR}/custom_nodes/${dir}"
        requirements="${path}/requirements.txt"
        if [[ -d $path ]]; then
            echo "Updating node: ${dir}"
            cd "$path" && git pull --quiet
        else
            echo "Cloning node: ${dir}"
            git clone --quiet "$repo" "$path"
        fi
        if [[ -e $requirements ]]; then
            pip install --no-cache-dir -r "$requirements"
        fi
    done
}

function provisioning_get_files() {
    local destination=$1
    shift
    local files=("$@")
    mkdir -p "$destination"
    for url in "${files[@]}"; do
        local filename="${url##*/}"
        # Strip query params from filename
        filename="${filename%%\?*}"
        local filepath="${destination}/${filename}"
        if [[ ! -f "$filepath" ]]; then
            echo "Downloading: $filename → $destination"
            wget -q --show-progress -O "$filepath" "$url" || {
                echo "ERROR: Failed to download $url"
                rm -f "$filepath"
            }
        else
            echo "Already exists, skipping: $filename"
        fi
    done
}

provisioning_start

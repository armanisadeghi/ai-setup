#!/bin/bash
# =============================================================================
# resolve-config.sh — Central config resolver for all scripts
#
# Sources defaults, local overrides, and secrets, then auto-detects anything
# left unset (paths, CUDA version, etc.).
#
# Usage (at the top of any script):
#   SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
#   source "$SCRIPT_DIR/../config/resolve-config.sh"
#
# Resolution order (later wins):
#   1. config/defaults.env        — shared defaults (in git)
#   2. config/config.local.env    — per-server overrides (gitignored)
#   3. .env_secrets               — secrets on the machine (gitignored)
#   4. Auto-detection             — fills in anything still unset
# =============================================================================

# Locate the repo root (parent of config/)
CONFIG_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$CONFIG_DIR/.." && pwd)"

# --- 1. Load defaults ---
if [ -f "$CONFIG_DIR/defaults.env" ]; then
    set -a
    source "$CONFIG_DIR/defaults.env"
    set +a
fi

# --- 2. Load local overrides (per-server, gitignored) ---
if [ -f "$CONFIG_DIR/config.local.env" ]; then
    set -a
    source "$CONFIG_DIR/config.local.env"
    set +a
fi

# --- 3. Auto-detect WORKSPACE ---
if [ -z "$WORKSPACE" ]; then
    # Check common locations in order of preference
    if [ -d "/workspace" ] && [ -w "/workspace" ]; then
        WORKSPACE="/workspace"                          # Vast.ai / RunPod
    elif [ -d "$HOME/workspace" ]; then
        WORKSPACE="$HOME/workspace"                     # Custom VMs
    else
        WORKSPACE="$HOME/workspace"                     # Fallback: create it
        mkdir -p "$WORKSPACE"
    fi
fi

# --- 4. Auto-detect COMFYUI_DIR ---
if [ -z "$COMFYUI_DIR" ]; then
    if [ -d "$WORKSPACE/ComfyUI" ]; then
        COMFYUI_DIR="$WORKSPACE/ComfyUI"
    elif [ -d "/opt/workspace-internal/ComfyUI" ]; then
        COMFYUI_DIR="$WORKSPACE/ComfyUI"               # Vast.ai syncs here
    else
        COMFYUI_DIR="$WORKSPACE/ComfyUI"               # Default
    fi
fi

# --- 5. Auto-detect VENV ---
if [ -z "$VENV" ]; then
    if [ -d "/venv/main" ]; then
        VENV="/venv/main"                               # Vast.ai image
    elif [ -n "$CONDA_PREFIX" ] && [ -d "$CONDA_PREFIX" ]; then
        VENV="$CONDA_PREFIX"                            # Conda env
    elif [ -d "$WORKSPACE/.venv" ]; then
        VENV="$WORKSPACE/.venv"                         # Local venv
    else
        VENV="$WORKSPACE/.venv"                         # Default: will create
    fi
fi

# --- 6. Load secrets (lives on the machine, never in git) ---
SECRETS_FILE="${SECRETS_FILE:-$WORKSPACE/.env_secrets}"
if [ -f "$SECRETS_FILE" ]; then
    set -a
    source "$SECRETS_FILE"
    set +a
fi

# --- 7. Auto-detect CUDA version and PyTorch index URL ---
if [ -z "$PYTORCH_INDEX_URL" ]; then
    CUDA_VER=""
    if command -v nvcc &>/dev/null; then
        CUDA_VER=$(nvcc --version 2>/dev/null | grep -oP 'release \K[0-9]+\.[0-9]+' | head -1)
    elif [ -f /usr/local/cuda/version.txt ]; then
        CUDA_VER=$(grep -oP '[0-9]+\.[0-9]+' /usr/local/cuda/version.txt | head -1)
    elif command -v nvidia-smi &>/dev/null; then
        CUDA_VER=$(nvidia-smi 2>/dev/null | grep -oP 'CUDA Version: \K[0-9]+\.[0-9]+' | head -1)
    fi

    case "$CUDA_VER" in
        12.8|12.9|13.*)  PYTORCH_INDEX_URL="https://download.pytorch.org/whl/cu128" ;;
        12.6|12.7)       PYTORCH_INDEX_URL="https://download.pytorch.org/whl/cu126" ;;
        12.4|12.5)       PYTORCH_INDEX_URL="https://download.pytorch.org/whl/cu124" ;;
        12.1|12.2|12.3)  PYTORCH_INDEX_URL="https://download.pytorch.org/whl/cu121" ;;
        11.*)            PYTORCH_INDEX_URL="https://download.pytorch.org/whl/cu118" ;;
        *)               PYTORCH_INDEX_URL="https://download.pytorch.org/whl/cu126" ;;  # safe default
    esac
fi

# --- 8. Derive S3 paths ---
S3_BUCKET="${AWS_BUCKET_MODELS:-matrx-models}"
S3_PREFIX="s3://$S3_BUCKET"

# --- Export everything so subprocesses see it ---
export WORKSPACE COMFYUI_DIR VENV REPO_DIR SECRETS_FILE
export COMFYUI_PORT COMFYUI_ARGS
export GIT_USER_NAME GIT_USER_EMAIL
export AWS_BUCKET_MODELS AWS_REGION S3_BUCKET S3_PREFIX
export S3_MODELS_PREFIX S3_OUTPUTS_PREFIX S3_WORKFLOWS_PREFIX S3_CONFIG_PREFIX
export S3_MOUNT_MODELS S3_MOUNT_CACHE
export PYTORCH_INDEX_URL

# Summary (only if sourced interactively or with DEBUG)
if [ "${AI_SETUP_DEBUG:-0}" = "1" ]; then
    echo "[config] REPO_DIR=$REPO_DIR"
    echo "[config] WORKSPACE=$WORKSPACE"
    echo "[config] COMFYUI_DIR=$COMFYUI_DIR"
    echo "[config] VENV=$VENV"
    echo "[config] SECRETS_FILE=$SECRETS_FILE"
    echo "[config] CUDA=$CUDA_VER  PYTORCH_INDEX_URL=$PYTORCH_INDEX_URL"
    echo "[config] S3_BUCKET=$S3_BUCKET"
fi

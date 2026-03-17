#!/bin/bash
# =============================================================================
# mount-s3.sh — Mount S3 bucket as local filesystem via s3fs
#
# Mounts s3://matrx-models/ (or configured bucket) so all models, loras,
# checkpoints, etc. appear as local files. ComfyUI sees them via
# extra_model_paths.yaml.
#
# Usage:
#   bash scripts/mount-s3.sh          # mount
#   bash scripts/mount-s3.sh unmount  # unmount
#   bash scripts/mount-s3.sh status   # check mount status
#
# Called automatically by startup.sh.
# =============================================================================

set -e

# --- Load centralized config ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../config/resolve-config.sh"

ACTION="${1:-mount}"

S3_MOUNT_MODELS="${S3_MOUNT_MODELS:-/mnt/s3-models}"
S3_MOUNT_CACHE="${S3_MOUNT_CACHE:-/tmp/s3fs-cache}"

# The S3 bucket is mounted at the root; models are at $S3_MOUNT_MODELS/comfyui-models/
# This also gives access to workflows, outputs, etc.
S3_MODELS_DIR="$S3_MOUNT_MODELS/comfyui-models"

# --- Validate ---
if [ -z "$AWS_ACCESS_KEY_ID" ] || [ -z "$AWS_SECRET_ACCESS_KEY" ]; then
    echo "[!] AWS credentials not set — cannot mount S3"
    echo "    Configure $SECRETS_FILE"
    exit 1
fi

if ! command -v s3fs &>/dev/null; then
    echo "[!] s3fs not installed. Installing..."
    sudo apt-get update -qq && sudo apt-get install -y -qq s3fs
fi

function do_mount() {
    # Already mounted?
    if mountpoint -q "$S3_MOUNT_MODELS" 2>/dev/null; then
        echo "[OK] S3 already mounted at $S3_MOUNT_MODELS"
        return 0
    fi

    echo "[s3fs] Mounting s3://$S3_BUCKET/ → $S3_MOUNT_MODELS"

    # Create mount point and cache dir
    sudo mkdir -p "$S3_MOUNT_MODELS"
    sudo chown "$(id -u):$(id -g)" "$S3_MOUNT_MODELS"
    mkdir -p "$S3_MOUNT_CACHE"

    # Write credentials file (s3fs needs this)
    S3FS_PASSWD="$HOME/.passwd-s3fs"
    echo "${AWS_ACCESS_KEY_ID}:${AWS_SECRET_ACCESS_KEY}" > "$S3FS_PASSWD"
    chmod 600 "$S3FS_PASSWD"

    # Ensure user_allow_other is enabled in fuse.conf
    if ! grep -q '^user_allow_other' /etc/fuse.conf 2>/dev/null; then
        sudo bash -c 'echo "user_allow_other" >> /etc/fuse.conf'
    fi

    # Mount the full bucket with caching and allow_other for ComfyUI
    s3fs "$S3_BUCKET" "$S3_MOUNT_MODELS" \
        -o passwd_file="$S3FS_PASSWD" \
        -o url="https://s3.${AWS_REGION}.amazonaws.com" \
        -o endpoint="${AWS_REGION}" \
        -o use_path_request_style \
        -o use_cache="$S3_MOUNT_CACHE" \
        -o ensure_diskfree=5120 \
        -o multireq_max=5 \
        -o parallel_count=10 \
        -o max_stat_cache_size=10000 \
        -o stat_cache_expire=300 \
        -o allow_other \
        -o mp_umask=022 \
        -o uid="$(id -u)" \
        -o gid="$(id -g)" \
        -o default_acl=private \
        -o retries=3

    if mountpoint -q "$S3_MOUNT_MODELS" 2>/dev/null; then
        echo "[OK] S3 bucket mounted at $S3_MOUNT_MODELS"
        echo "     Models:    $S3_MODELS_DIR"
        echo "     Workflows: $S3_MOUNT_MODELS/comfyui-workflows/"
        echo "     Cache:     $S3_MOUNT_CACHE"
        ls "$S3_MODELS_DIR/" 2>/dev/null | head -20
    else
        echo "[!] Mount may have failed — check with: mount | grep s3fs"
    fi
}

function do_unmount() {
    if mountpoint -q "$S3_MOUNT_MODELS" 2>/dev/null; then
        echo "[s3fs] Unmounting $S3_MOUNT_MODELS..."
        sudo umount "$S3_MOUNT_MODELS" 2>/dev/null || fusermount -u "$S3_MOUNT_MODELS"
        echo "[OK] Unmounted"
    else
        echo "[~] $S3_MOUNT_MODELS is not mounted"
    fi
}

function do_status() {
    echo "=== S3 Mount Status ==="
    echo ""
    if mountpoint -q "$S3_MOUNT_MODELS" 2>/dev/null; then
        echo "Status: MOUNTED"
        echo "Mount:  $S3_MOUNT_MODELS"
        echo "Models: $S3_MODELS_DIR"
        echo ""
        echo "Model directories:"
        ls -la "$S3_MODELS_DIR/" 2>/dev/null | head -30
        echo ""
        echo "Cache size: $(du -sh "$S3_MOUNT_CACHE" 2>/dev/null | cut -f1 || echo 'empty')"
    else
        echo "Status: NOT MOUNTED"
        echo ""
        echo "To mount: bash scripts/mount-s3.sh"
    fi
}

case "$ACTION" in
    mount)    do_mount ;;
    unmount)  do_unmount ;;
    status)   do_status ;;
    *)
        echo "Usage: $0 {mount|unmount|status}"
        exit 1
        ;;
esac

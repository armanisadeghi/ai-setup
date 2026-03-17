#!/bin/bash
# =============================================================================
# s3-sync.sh — Sync models, outputs, and configs to/from AWS S3
#
# Usage:
#   bash s3-sync.sh pull     # Download models/configs from S3 to local
#   bash s3-sync.sh push     # Upload models/outputs/configs to S3
#   bash s3-sync.sh status   # Show what would sync (dry-run)
#
# This is the core persistence mechanism for ephemeral GPU instances.
# All large files (models, outputs) live in S3 and are pulled on demand.
# =============================================================================

set -e

# --- Load centralized config ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../config/resolve-config.sh"

ACTION="${1:-status}"

if [ -z "$AWS_ACCESS_KEY_ID" ]; then
    echo "[!] AWS_ACCESS_KEY_ID not set. Configure $SECRETS_FILE"
    exit 1
fi

function s3_pull() {
    echo "=== S3 PULL — Downloading to local ==="
    echo ""

    # Sync models (skip if already present locally — no overwrite)
    echo "--- Models ---"
    aws s3 sync "$S3_PREFIX/comfyui-models/" "$COMFYUI_DIR/models/" \
        --no-progress \
        --size-only \
        2>&1 || echo "[!] Model sync had errors"

    # Sync workflows
    echo ""
    echo "--- Workflows ---"
    aws s3 sync "$S3_PREFIX/comfyui-workflows/" "$COMFYUI_DIR/user/default/workflows/" \
        --no-progress \
        2>&1 || echo "[!] Workflow sync had errors"

    # Sync env secrets (if stored in S3)
    echo ""
    echo "--- Secrets ---"
    aws s3 cp "$S3_PREFIX/config/.env_secrets" "$WORKSPACE/.env_secrets" \
        2>/dev/null || echo "[~] No secrets in S3 (using local)"

    echo ""
    echo "[OK] Pull complete"
    df -h / | tail -1
}

function s3_push() {
    echo "=== S3 PUSH — Uploading to S3 ==="
    echo ""

    # Upload models to S3 (for migration to new instances)
    echo "--- Models ---"
    aws s3 sync "$COMFYUI_DIR/models/" "$S3_PREFIX/comfyui-models/" \
        --no-progress \
        --size-only \
        --exclude "*.tmp" \
        --exclude "*.part" \
        2>&1 || echo "[!] Model upload had errors"

    # Upload outputs (generated images/videos)
    echo ""
    echo "--- Outputs ---"
    aws s3 sync "$COMFYUI_DIR/output/" "$S3_PREFIX/comfyui-outputs/" \
        --no-progress \
        --exclude "*.tmp" \
        2>&1 || echo "[!] Output upload had errors"

    # Upload workflows
    echo ""
    echo "--- Workflows ---"
    aws s3 sync "$COMFYUI_DIR/user/default/workflows/" "$S3_PREFIX/comfyui-workflows/" \
        --no-progress \
        2>&1 || echo "[!] Workflow upload had errors"

    # Upload secrets (encrypted at rest in S3)
    echo ""
    echo "--- Secrets ---"
    if [ -f "$WORKSPACE/.env_secrets" ]; then
        aws s3 cp "$WORKSPACE/.env_secrets" "$S3_PREFIX/config/.env_secrets" \
            --sse AES256 \
            2>&1 || echo "[!] Secrets upload failed"
    fi

    echo ""
    echo "[OK] Push complete"
}

function s3_status() {
    echo "=== S3 SYNC STATUS (dry-run) ==="
    echo ""
    echo "Bucket: $S3_BUCKET"
    echo "Local models: $(du -sh "$COMFYUI_DIR/models/" 2>/dev/null | cut -f1 || echo 'none')"
    echo "Local outputs: $(du -sh "$COMFYUI_DIR/output/" 2>/dev/null | cut -f1 || echo 'none')"
    echo ""

    echo "--- What would be PULLED from S3 ---"
    aws s3 sync "$S3_PREFIX/comfyui-models/" "$COMFYUI_DIR/models/" \
        --dryrun --size-only 2>&1 | head -20 || echo "(nothing)"

    echo ""
    echo "--- What would be PUSHED to S3 ---"
    aws s3 sync "$COMFYUI_DIR/models/" "$S3_PREFIX/comfyui-models/" \
        --dryrun --size-only --exclude "*.tmp" --exclude "*.part" 2>&1 | head -20 || echo "(nothing)"

    echo ""
    echo "--- S3 bucket contents ---"
    aws s3 ls "$S3_PREFIX/" 2>&1 | head -20 || echo "(empty or no access)"
}

case "$ACTION" in
    pull)  s3_pull  ;;
    push)  s3_push  ;;
    status) s3_status ;;
    *)
        echo "Usage: $0 {pull|push|status}"
        exit 1
        ;;
esac

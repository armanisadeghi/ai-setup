#!/bin/bash
# =============================================================================
# upload-outputs-to-s3.sh — Upload ComfyUI generated outputs to S3
#
# Syncs all images and videos from ComfyUI's output folder to:
#   s3://matrx-models/comfyui-outputs/
#
# Usage:
#   bash /workspace/ai-setup/scripts/upload-outputs-to-s3.sh          # sync all
#   bash /workspace/ai-setup/scripts/upload-outputs-to-s3.sh --dry-run  # preview only
#   bash /workspace/ai-setup/scripts/upload-outputs-to-s3.sh --today    # today's files only
#
# Runs automatically from safe-shutdown.sh before stopping the instance.
# Can also be run any time manually, or on a cron schedule.
# =============================================================================

set -e

# --- Load secrets ---
if [ -f /workspace/.env_secrets ]; then
    source /workspace/.env_secrets
else
    echo "[!] ERROR: /workspace/.env_secrets not found"
    echo "    AWS credentials are required. Cannot upload."
    exit 1
fi

# --- Validate credentials ---
if [ -z "$AWS_ACCESS_KEY_ID" ] || [ -z "$AWS_SECRET_ACCESS_KEY" ]; then
    echo "[!] ERROR: AWS_ACCESS_KEY_ID or AWS_SECRET_ACCESS_KEY not set in .env_secrets"
    exit 1
fi

export AWS_ACCESS_KEY_ID
export AWS_SECRET_ACCESS_KEY
export AWS_DEFAULT_REGION="${AWS_REGION:-us-east-2}"

BUCKET="${AWS_BUCKET_MODELS:-matrx-models}"
OUTPUT_DIR="/workspace/ComfyUI/output"
S3_PREFIX="comfyui-outputs"
DRY_RUN=""
TODAY_ONLY=false

# --- Parse args ---
for arg in "$@"; do
    case "$arg" in
        --dry-run) DRY_RUN="--dryrun" ;;
        --today)   TODAY_ONLY=true ;;
    esac
done

echo ""
echo "╔══════════════════════════════════════════════════════════╗"
echo "║         Uploading ComfyUI Outputs → S3                  ║"
echo "╚══════════════════════════════════════════════════════════╝"
echo ""
echo "  Source:      $OUTPUT_DIR"
echo "  Destination: s3://$BUCKET/$S3_PREFIX/"
[ -n "$DRY_RUN" ] && echo "  Mode:        DRY RUN — no files will be uploaded"
echo ""

# --- Check aws cli is available ---
if ! command -v aws &>/dev/null; then
    echo "[!] aws CLI not found. Installing..."
    pip install awscli --quiet
    echo "[✓] aws CLI installed"
fi

# --- Check output dir exists ---
if [ ! -d "$OUTPUT_DIR" ]; then
    echo "[~] Output directory $OUTPUT_DIR does not exist — nothing to upload"
    exit 0
fi

# --- Count files ---
TOTAL_FILES=$(find "$OUTPUT_DIR" -type f \( -name "*.png" -o -name "*.jpg" -o -name "*.jpeg" -o -name "*.webp" -o -name "*.mp4" -o -name "*.webm" -o -name "*.gif" \) | wc -l)
echo "  Files found: $TOTAL_FILES image/video files"

if [ "$TOTAL_FILES" -eq 0 ]; then
    echo "[~] No output files found — nothing to upload"
    exit 0
fi

TOTAL_SIZE=$(du -sh "$OUTPUT_DIR" 2>/dev/null | cut -f1 || echo "?")
echo "  Total size:  $TOTAL_SIZE"
echo ""

# --- Upload ---
if [ "$TODAY_ONLY" = true ]; then
    # Upload only files modified today
    TODAY=$(date +%Y-%m-%d)
    TEMP_LIST=$(mktemp)
    find "$OUTPUT_DIR" -type f \( -name "*.png" -o -name "*.jpg" -o -name "*.jpeg" -o -name "*.webp" -o -name "*.mp4" -o -name "*.webm" -o -name "*.gif" \) -newer /tmp/.today_marker 2>/dev/null > "$TEMP_LIST" || true
    touch -d "$TODAY" /tmp/.today_marker 2>/dev/null || true
    FILE_COUNT=$(wc -l < "$TEMP_LIST")
    echo "--- Uploading today's $FILE_COUNT files ---"
    # Fall back to full sync for today's directory if it exists
    if [ -d "$OUTPUT_DIR/$TODAY" ]; then
        aws s3 sync "$OUTPUT_DIR/$TODAY" "s3://$BUCKET/$S3_PREFIX/$TODAY/" \
            $DRY_RUN \
            --exclude "*.txt" \
            --storage-class STANDARD_IA \
            2>&1
    else
        aws s3 sync "$OUTPUT_DIR" "s3://$BUCKET/$S3_PREFIX/" \
            $DRY_RUN \
            --exclude "*.txt" \
            --storage-class STANDARD_IA \
            2>&1
    fi
    rm -f "$TEMP_LIST"
else
    echo "--- Syncing all outputs ---"
    aws s3 sync "$OUTPUT_DIR" "s3://$BUCKET/$S3_PREFIX/" \
        $DRY_RUN \
        --exclude "*.txt" \
        --storage-class STANDARD_IA \
        2>&1
fi

if [ -z "$DRY_RUN" ]; then
    echo ""
    echo "[✓] Upload complete → s3://$BUCKET/$S3_PREFIX/"
    echo ""
    echo "  View in AWS Console:"
    echo "  https://s3.console.aws.amazon.com/s3/buckets/$BUCKET?prefix=$S3_PREFIX/"
else
    echo ""
    echo "[✓] Dry run complete — run without --dry-run to actually upload"
fi
echo ""

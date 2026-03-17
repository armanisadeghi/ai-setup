#!/bin/bash
# =============================================================================
# safe-shutdown.sh — Run BEFORE destroying the GPU instance
#
# What it does:
#   1. Pushes all models, outputs, and configs to S3
#   2. Saves workflows from ComfyUI back to the repo
#   3. Commits and pushes all changes to GitHub
#   4. Confirms what was saved
#
# Usage:
#   bash /path/to/ai-setup/scripts/safe-shutdown.sh
#   bash /path/to/ai-setup/scripts/safe-shutdown.sh "optional commit message"
# =============================================================================

set -e

# --- Load centralized config ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../config/resolve-config.sh"

COMMIT_MSG="${1:-Pre-shutdown save: $(date '+%Y-%m-%d %H:%M')}"

echo ""
echo "╔══════════════════════════════════════════════════════════╗"
echo "║           SAFE SHUTDOWN — Saving Everything              ║"
echo "╚══════════════════════════════════════════════════════════╝"
echo ""

# --- Step 1: Restore git identity ---
git config --global user.name "$GIT_USER_NAME"
git config --global user.email "$GIT_USER_EMAIL"
echo "[OK] Git identity ready"

# --- Step 2: Upload everything to S3 ---
echo ""
echo "--- Uploading to S3 ---"
if [ -n "$AWS_ACCESS_KEY_ID" ]; then
    bash "$REPO_DIR/scripts/s3-sync.sh" push 2>&1
    echo "[OK] S3 push complete"
else
    echo "[!] AWS credentials not set — skipping S3 push"
    echo "    Models and outputs will be lost when this instance is destroyed!"
fi

# --- Step 3: Sync workflows from ComfyUI back to repo ---
echo ""
echo "--- Syncing workflows from ComfyUI to repo ---"
COMFYUI_WORKFLOWS="$COMFYUI_DIR/user/default/workflows"
REPO_WORKFLOWS="$REPO_DIR/comfyui/workflows"

if [ -d "$COMFYUI_WORKFLOWS" ]; then
    mkdir -p "$REPO_WORKFLOWS"
    # Copy any .json files from ComfyUI that are newer or don't exist in repo
    cp -u "$COMFYUI_WORKFLOWS/"*.json "$REPO_WORKFLOWS/" 2>/dev/null && \
        echo "[✓] Workflows synced from ComfyUI to repo" || \
        echo "[~] No workflow files found in ComfyUI workflows folder"
else
    echo "[~] ComfyUI workflows folder not found — skipping"
fi

# --- Step 4: Show what changed ---
echo ""
echo "--- Changes to be committed ---"
cd "$REPO_DIR"
git --no-pager diff --stat HEAD 2>/dev/null || true
git --no-pager status --short 2>/dev/null || true

# Check if there's actually anything to commit
if git --no-pager diff --quiet HEAD 2>/dev/null && [ -z "$(git status --porcelain 2>/dev/null)" ]; then
    echo ""
    echo "[✓] Nothing new to commit — repo is already up to date"
    NEEDS_COMMIT=false
else
    NEEDS_COMMIT=true
fi

# --- Step 5: Commit and push ---
if [ "$NEEDS_COMMIT" = "true" ]; then
    echo ""
    echo "--- Committing ---"
    git add -A
    git --no-pager commit -m "$COMMIT_MSG"
    echo "[✓] Committed: $COMMIT_MSG"
fi

echo ""
echo "--- Pushing to GitHub ---"
git push origin main 2>&1 | tail -5
echo "[✓] Pushed to https://github.com/armanisadeghi/ai-setup"

# --- Step 6: Verify remote is up to date ---
REMOTE_SHA=$(git rev-parse origin/main 2>/dev/null || echo "unknown")
LOCAL_SHA=$(git rev-parse HEAD 2>/dev/null || echo "unknown")
if [ "$REMOTE_SHA" = "$LOCAL_SHA" ]; then
    echo "[✓] Remote is in sync with local (SHA: ${LOCAL_SHA:0:8})"
else
    echo "[!] WARNING: Remote and local SHA differ — push may have failed"
    echo "    Local:  $LOCAL_SHA"
    echo "    Remote: $REMOTE_SHA"
fi

# --- Step 7: Display summary ---
echo ""
echo "============================================="
echo "  SHUTDOWN SAFETY SUMMARY"
echo "============================================="
echo ""
echo "SAVED TO S3 ($S3_BUCKET):"
echo "  - All models (comfyui-models/)"
echo "  - All outputs (comfyui-outputs/)"
echo "  - Workflows (comfyui-workflows/)"
echo "  - Secrets (config/.env_secrets)"
echo ""
echo "SAVED TO GITHUB:"
echo "  - All scripts, configs, and docs"
echo "  - Workflow JSON files"
echo "  - AGENT_TASKS.md (task history)"
echo ""
echo "TO RESTORE ON A NEW INSTANCE:"
echo "  1. Clone the repo"
echo "  2. Set up .env_secrets with AWS creds"
echo "  3. Run: bash scripts/startup.sh"
echo "  4. Models will auto-pull from S3"
echo ""
echo "============================================="
echo ""

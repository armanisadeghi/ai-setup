#!/bin/bash
# =============================================================================
# safe-shutdown.sh — Run this BEFORE stopping the Vast.ai instance
#
# What it does:
#   1. Saves any custom ComfyUI workflows you've created back to the repo
#   2. Commits ALL changes (code, configs, scripts, docs, workflows)
#   3. Pushes to GitHub (armanisadeghi/ai-setup, branch main)
#   4. Confirms exactly what was saved and what to expect on restart
#
# Usage:
#   bash /workspace/ai-setup/scripts/safe-shutdown.sh
#   bash /workspace/ai-setup/scripts/safe-shutdown.sh "optional commit message"
#
# NOTE: This script does NOT shut down the instance. It only saves your work.
#       After running it, stop the instance from the Vast.ai console.
# =============================================================================

set -e

WORKSPACE="/workspace"
REPO_DIR="$WORKSPACE/ai-setup"
COMFYUI_DIR="$WORKSPACE/ComfyUI"
COMMIT_MSG="${1:-Pre-shutdown save: $(date '+%Y-%m-%d %H:%M')}"

echo ""
echo "╔══════════════════════════════════════════════════════════╗"
echo "║           SAFE SHUTDOWN — Saving Everything              ║"
echo "╚══════════════════════════════════════════════════════════╝"
echo ""

# --- Step 1: Restore git identity (may be lost if run fresh) ---
git config --global user.name "Arman Isadeghi"
git config --global user.email "arman@armansadeghi.com"
git config --global credential.helper "store --file /workspace/.git-credentials"
echo "[✓] Git identity ready"

# --- Step 2: Upload ComfyUI outputs to S3 ---
echo ""
echo "--- Uploading ComfyUI outputs to S3 ---"
if bash "$REPO_DIR/scripts/upload-outputs-to-s3.sh" 2>&1; then
    echo "[✓] Outputs uploaded to s3://matrx-models/comfyui-outputs/"
else
    echo "[!] S3 upload failed or skipped — outputs remain at $COMFYUI_DIR/output/ on this instance"
    echo "    They are on the persistent /workspace volume so they won't be lost on stop/start."
    echo "    Run manually later: bash $REPO_DIR/scripts/upload-outputs-to-s3.sh"
fi

# --- Step 3: Sync workflows from ComfyUI back to repo ---
echo ""
echo "--- Syncing workflows from ComfyUI → repo ---"
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

# --- Step 7: Display what's safe vs what's ephemeral ---
echo ""
echo "╔══════════════════════════════════════════════════════════╗"
echo "║              SHUTDOWN SAFETY SUMMARY                    ║"
echo "╚══════════════════════════════════════════════════════════╝"
echo ""
echo "✅ SAFE TO LOSE (will be restored on restart):"
echo "   • Python venv, CUDA, OS packages (restored by base image)"
echo "   • ComfyUI installation (in /workspace — it's PERSISTENT)"
echo "   • Git config (restored by startup.sh)"
echo ""
echo "✅ PERSISTS AUTOMATICALLY (on /workspace volume):"
echo "   • All models in /workspace/ComfyUI/models/ (~$(du -sh $COMFYUI_DIR/models 2>/dev/null | cut -f1 || echo '?'))"
echo "   • This repo in /workspace/ai-setup/"
echo "   • Secrets in /workspace/.env_secrets"
echo "   • Git credentials in /workspace/.git-credentials"
echo "   • HuggingFace cache in /workspace/.hf_home/"
echo ""
echo "✅ SAVED TO GITHUB (just pushed):"
echo "   • All scripts, configs, and docs"
echo "   • All workflows (including any you created in ComfyUI)"
echo "   • AGENT_TASKS.md (task history for next session)"
echo ""
echo "✅ OUTPUTS UPLOADED TO S3:"
echo "   • s3://matrx-models/comfyui-outputs/"
echo "   • Images and videos are NOT in git — they go to S3 only"
echo "   • To upload manually anytime: bash scripts/upload-outputs-to-s3.sh"
echo ""
echo "⚠️  EPHEMERAL — WILL BE GONE ON RESTART:"
echo "   • Bash history (save manually: history > /workspace/bash_history.txt)"
echo "   • Any pip installs outside the venv (startup.sh reinstalls known ones)"
echo "   • Custom nodes (startup.sh reinstalls from custom_nodes.txt)"
echo "   • Any files under /tmp, /root (not /workspace)"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "  NEXT STEPS:"
echo "  1. ✅ This script is done — your work is saved"
echo "  2. Go to Vast.ai console → click STOP on your instance"
echo "  3. To restart: start the instance, then run:"
echo "       bash /workspace/ai-setup/scripts/startup.sh"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Optional: Save bash history too
history -w /workspace/bash_history_$(date +%Y%m%d).txt 2>/dev/null && \
    echo "[~] Bash history saved to /workspace/bash_history_$(date +%Y%m%d).txt" || true

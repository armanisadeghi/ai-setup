#!/bin/bash
# =============================================================================
# instance-status.sh — Quick status check for the instance
# Run at any time to see what's going on
# =============================================================================

echo "============================================="
echo "  Instance Status — $(date)"
echo "============================================="

echo ""
echo "--- GPU ---"
nvidia-smi --query-gpu=name,memory.total,memory.free,memory.used,temperature.gpu,utilization.gpu --format=csv,noheader 2>/dev/null || echo "nvidia-smi unavailable"

echo ""
echo "--- Disk ---"
df -h / /workspace 2>/dev/null

echo ""
echo "--- Model Storage ---"
du -sh /workspace/ComfyUI/models/*/ 2>/dev/null | sort -h

echo ""
echo "--- HuggingFace Cache ---"
du -sh /workspace/.hf_home/ 2>/dev/null || echo "(empty)"

echo ""
echo "--- Running Services ---"
supervisorctl status 2>/dev/null || ps aux | grep -E "comfyui|jupyter|syncthing" | grep -v grep

echo ""
echo "--- ComfyUI Health ---"
curl -s http://localhost:18188/system_stats 2>/dev/null | python3 -m json.tool 2>/dev/null || echo "ComfyUI not responding on port 18188"

echo ""
echo "--- Access URLs ---"
EXTERNAL_IP=$(cat /etc/forward_host 2>/dev/null || echo "$PUBLIC_IPADDR")
echo "ComfyUI:        http://$EXTERNAL_IP:8188"
echo "Jupyter:        http://$EXTERNAL_IP:8080"
echo "Instance Portal: http://$EXTERNAL_IP:1111"
echo ""

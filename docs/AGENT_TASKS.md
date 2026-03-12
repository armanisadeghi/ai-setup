# Arman's Task Board

**How this works:**
- Active tasks are at the top, organized by priority block
- Tasks needing Arman's input are marked 🔑
- Tasks running in the background are marked ⏳
- Completed tasks are summarized at the bottom
- Agent updates this file as work progresses

---

# 🔑 ARMAN — ACTION NEEDED NOW

These are blocking other work. Please handle these ASAP:

### 1. Provide API Keys (HIGH PRIORITY)
The following keys are needed for downloading gated models (Flux, LoRAs from CivitAI):

**HuggingFace Token**
- Go to: https://huggingface.co/settings/tokens
- Create a token with "Read" access
- Needed for: Flux models (gated), faster downloads

**CivitAI API Key**
- Go to: https://civitai.com/user/account → API Keys section
- Needed for: LoRA downloads, any CivitAI models

Once you have them, tell the agent and it will store them securely at `/workspace/.env_secrets` (persistent, never committed to git).

---

### 2. Test ComfyUI (ONCE DOWNLOADS FINISH — ~30-60 min)
Downloads are currently running in the background. Once done, the agent will notify you to test.
You'll open ComfyUI in your browser and run a quick test workflow.

---

# ⏳ IN PROGRESS (Agent Working / Background)

### WAN 2.2 Video Models — Downloading Now
Started: March 12, 2026
```
✅ umt5_xxl_fp8_e4m3fn_scaled.safetensors  (text encoder, ~10GB)
✅ wan_2.1_vae.safetensors                  (VAE for 14B models)
✅ wan2.2_vae.safetensors                   (VAE for 5B model)
✅ wan2.2_ti2v_5B_fp16.safetensors          (5B T2V+I2V model, ~10GB)
✅ wan2.2_i2v_high_noise_14B_fp8_scaled     (14B I2V part 1, ~13GB)
⏳ wan2.2_i2v_low_noise_14B_fp8_scaled     (14B I2V part 2, ~13GB)
⏳ wan2.2_t2v_high_noise_14B_fp8_scaled    (14B T2V part 1, ~13GB)
⏳ wan2.2_t2v_low_noise_14B_fp8_scaled     (14B T2V part 2, ~13GB)
⏳ clip_vision_h.safetensors               (CLIP vision for I2V)
```
Monitor: `tail -f /workspace/download_wan22.log`

### Official Workflows Downloaded ✅
Saved to `/workspace/ai-setup/comfyui/workflows/`:
- `wan22_t2v_5B.json` — WAN 2.2 Text-to-Video (5B model)
- `wan22_i2v_5B.json` — WAN 2.2 Image-to-Video (5B model)
- `wan22_t2v_14B.json` — WAN 2.2 Text-to-Video (14B, best quality)
- `wan22_i2v_14B.json` — WAN 2.2 Image-to-Video (14B, best quality)
- `wan21_t2v.json` — WAN 2.1 T2V (fallback)
- `wan21_i2v.json` — WAN 2.1 I2V (fallback)

---

# 📋 UPCOMING — NEXT AGENT TASKS

### Block A: Video Setup Completion (after downloads finish)
1. Copy workflows to ComfyUI user folder and verify they load
2. Create LoRA-ready variants of I2V workflows (easy LoRA slot pre-wired)
3. Configure ComfyUI output path to persist to `/workspace/ComfyUI/output/`
4. Test WAN 2.2 workflows end-to-end and document recommended settings

### Block B: API Keys & Secrets Management (needs Arman's keys first)
1. Create `/workspace/.env_secrets` with HF_TOKEN and CIVITAI_API_KEY
2. Update startup script to export these env vars on each boot
3. Test authenticated HuggingFace downloads (enables gated models like Flux)

### Block C: Flux Setup (needs HF token)
1. Download Flux.1-dev fp8 model (~17GB) — best quality Flux available
2. Download Flux.1-schnell (~17GB) — faster version for quick iterations
3. Set up Flux T2I workflow in ComfyUI
4. Download top image LoRAs for fashion/beauty from CivitAI (needs CIVITAI key)

### Block D: LoRA Library for Client Work
Focus: women's fashion, lingerie, bikini photography aesthetic
Requires CivitAI API key to download. Agent will research and identify top LoRAs.
Will create a curated list first for Arman to approve before downloading.

### Block E: ComfyUI API Setup
1. Verify ComfyUI API is accessible externally on port 8188
2. Document API endpoints and authentication for AI Matrix Admin UI integration
3. Create example API call scripts for text-to-video and image-to-video
4. Add CORS/auth notes for connecting from matrxserver.com

### Block F: VSCode Settings Backup
1. Save `.vscode/settings.json` and extensions list to git repo
2. Create a script to restore VSCode settings on new instances
3. Note: Chat conversation history isn't storable (Copilot limitation) —
   but AGENT_TASKS.md + repo notes serve as the persistent context replacement

---

# ✅ COMPLETED

### Server & Git Setup (March 12, 2026)
- Vast.ai H200 instance documented (see README.md)
- Storage explained: `/workspace` = 2TB persistent, `/` = 200GB ephemeral
- Git repo initialized at `https://github.com/armanisadeghi/ai-setup`
- Git credentials stored at `/workspace/.git-credentials` (persistent)
- Git identity: Arman Isadeghi `arman@armansadeghi.com`
- Startup script (`scripts/startup.sh`) restores git config on each boot
- Full documentation created: storage-guide, comfyui-setup, wan-video-setup, models-inventory

### WAN 2.2 Research (March 12, 2026)
- Identified official model files from `Comfy-Org/Wan_2.2_ComfyUI_Repackaged` on HuggingFace
- Strategy: 5B model (fast, both T2V+I2V in one file) + 14B fp8 (best quality, needs 2 files each)
- Official workflow JSONs downloaded from comfyanonymous.github.io/ComfyUI_examples/wan22/
- Downloads kicked off in background
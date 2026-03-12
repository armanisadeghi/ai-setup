#!/bin/bash
# =============================================================================
# install-packages.sh — Install additional pip packages not in the base image
#
# These are re-installed on every startup since /venv/main is ephemeral.
# Keep this list minimal — only add what you actually need.
# =============================================================================

source /venv/main/bin/activate

PACKAGES=(
    # Add packages here
    # "package-name"
    # "package-name==1.2.3"
)

if [ ${#PACKAGES[@]} -eq 0 ]; then
    echo "[packages] No additional packages to install."
    exit 0
fi

echo "[packages] Installing ${#PACKAGES[@]} packages..."
pip install --quiet --no-cache-dir "${PACKAGES[@]}"
echo "[packages] Done."

#!/bin/env bash
# ========================================
# OneShot DEB Package Build Script
# Updated for resurrected21/OneShot fork
# Last Updated: October 2025
# ========================================

set -e  # Exit on error

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}OneShot DEB Package Builder${NC}"
echo -e "${GREEN}========================================${NC}"

# Check if running on GitHub Actions
if [ -z "$GITHUB_WORKSPACE" ]; then
	echo -e "${RED}Error: This script should only run on GitHub Actions!${NC}" >&2
	echo -e "${YELLOW}For local builds, use: ./scripts/build_local.sh${NC}" >&2
	exit 1
fi

# Make sure we're in the right directory
cd "$GITHUB_WORKSPACE"
echo -e "${GREEN}✓ Working directory: $GITHUB_WORKSPACE${NC}"

# Define variables
out="$GITHUB_WORKSPACE/out"
termux_prefix="/data/data/com.termux/files/usr"
version="$(cat version 2>/dev/null || echo "1.0.0")"
version_code="$(git rev-list HEAD --count)"
short_hash="$(git rev-parse --short HEAD)"
release_code="$version_code-$short_hash-release"
deb_name="oneshot_${version}_${version_code}_all.deb"
maintainer="resurrected21"
repo_url="https://github.com/resurrected21/OneShot"

echo -e "${GREEN}Version: $version${NC}"
echo -e "${GREEN}Version Code: $version_code${NC}"
echo -e "${GREEN}Release Code: $release_code${NC}"
echo -e "${GREEN}Package Name: $deb_name${NC}"

# Create output directory structure
echo -e "${YELLOW}Creating directory structure...${NC}"
mkdir -v "$out"
mkdir -v "$out/deb"
mkdir -pv "$out/deb$termux_prefix"
mkdir -pv "$out/deb$termux_prefix/share/oneshot"
mkdir -pv "$out/deb$termux_prefix/share/doc/oneshot"
mkdir -pv "$out/deb$termux_prefix/bin"

# Copy main script
echo -e "${YELLOW}Copying OneShot script...${NC}"
if [ -f "src/oneshot" ]; then
    cp -v src/oneshot "$out/deb$termux_prefix/bin/oneshot"
elif [ -f "oneshot.py" ]; then
    cp -v oneshot.p

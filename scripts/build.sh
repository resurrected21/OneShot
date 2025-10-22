#!/bin/env bash
# ========================================
# OneShot DEB Package Build Script
# Updated for resurrected21/OneShot fork
# Last Updated: October 2025
# ========================================

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}OneShot DEB Package Builder${NC}"
echo -e "${GREEN}========================================${NC}"

if [ -z "$GITHUB_WORKSPACE" ]; then
	echo -e "${RED}Error: This script should only run on GitHub Actions!${NC}" >&2
	exit 1
fi

cd "$GITHUB_WORKSPACE"
echo -e "${GREEN}✓ Working directory: $GITHUB_WORKSPACE${NC}"

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
echo -e "${GREEN}Package Name: $deb_name${NC}"

echo -e "${YELLOW}Creating directory structure...${NC}"
mkdir -v "$out"
mkdir -v "$out/deb"
mkdir -pv "$out/deb$termux_prefix/share/oneshot"
mkdir -pv "$out/deb$termux_prefix/share/doc/oneshot"
mkdir -pv "$out/deb$termux_prefix/bin"
mkdir -pv "$out/deb/DEBIAN"

echo -e "${YELLOW}Copying OneShot script...${NC}"
if [ -f "src/oneshot" ]; then
    cp -v src/oneshot "$out/deb$termux_prefix/bin/oneshot"
elif [ -f "oneshot.py" ]; then
    cp -v oneshot.py "$out/deb$termux_prefix/bin/oneshot"
elif [ -f "oneshot" ]; then
    cp -v oneshot "$out/deb$termux_prefix/bin/oneshot"
else
    echo -e "${RED}Error: OneShot main script not found!${NC}" >&2
    exit 1
fi

echo -e "${YELLOW}Copying additional files...${NC}"
[ -f "vulnwsc.txt" ] && cp -v vulnwsc.txt "$out/deb$termux_prefix/share/oneshot/" || echo "vulnwsc.txt not found, skipping"
[ -f "wpspin.py" ] && cp -v wpspin.py "$out/deb$termux_prefix/share/oneshot/" || echo "wpspin.py not found, skipping"
[ -f "README.md" ] && cp -v README.md "$out/deb$termux_prefix/share/doc/oneshot/" || echo "README.md not found, skipping"
[ -f "LICENSE" ] && cp -v LICENSE "$out/deb$termux_prefix/share/doc/oneshot/" || echo "LICENSE not found, skipping"

echo -e "${YELLOW}Creating DEBIAN control file...${NC}"
cat > "$out/deb/DEBIAN/control" <<'CONTROL_EOF'
Package: oneshot
Version: VERSION_PLACEHOLDER
Section: net
Priority: optional
Architecture: all
Depends: python, root-repo, openssl, wireless-tools
Maintainer: resurrected21 <resurrected21@users.noreply.github.com>
Homepage: https://github.com/resurrected21/OneShot
Description: WPS PIN attack tool (Pixie Dust and bruteforce) for Termux
 OneShot is a WiFi pentesting tool that allows WPS PIN attacks
 without monitor mode using wpa_supplicant. Features include:
 - Pixie Dust attack
 - Integrated 3WiFi offline WPS PIN generator
 - Online WPS bruteforce
 - Wi-Fi scanner with iw integration
 - Updated 2025 router vulnerability database (340+ devices)
CONTROL_EOF

sed -i "s/VERSION_PLACEHOLDER/$version.$version_code/" "$out/deb/DEBIAN/control"

echo -e "${YELLOW}Creating postinst script...${NC}"
cat > "$out/deb/DEBIAN/postinst" <<'POSTINST_EOF'
#!/data/data/com.termux/files/usr/bin/sh
set -e
echo "Setting up OneShot..."
chmod +x /data/data/com.termux/files/usr/bin/oneshot
if [ ! -L /data/data/com.termux/files/usr/bin/oneshot-wps ]; then
    ln -sf /data/data/com.termux/files/usr/bin/oneshot /data/data/com.termux/files/usr/bin/oneshot-wps
fi
echo "OneShot installation complete!"
echo ""
echo "Usage:"
echo "  sudo oneshot -i wlan0 -K"
echo "  sudo oneshot -i wlan0 -b MAC -K"
echo ""
echo "For help: oneshot --help"
exit 0
POSTINST_EOF

echo -e "${YELLOW}Creating prerm script...${NC}"
cat > "$out/deb/DEBIAN/prerm" <<'PRERM_EOF'
#!/data/data/com.termux/files/usr/bin/sh
set -e
echo "Removing OneShot..."
if [ -L /data/data/com.termux/files/usr/bin/oneshot-wps ]; then
    rm -f /data/data/com.termux/files/usr/bin/oneshot-wps
fi
exit 0
PRERM_EOF

echo -e "${YELLOW}Setting permissions...${NC}"
chmod -Rv 755 "$out/deb/DEBIAN"
chmod -Rv 755 "$out/deb$termux_prefix/bin"
chmod -v 755 "$out/deb/DEBIAN/postinst" "$out/deb/DEBIAN/prerm"

installed_size=$(du -sk "$out/deb" | cut -f1)
echo "Installed-Size: $installed_size" >> "$out/deb/DEBIAN/control"

echo -e "${YELLOW}Building DEB package...${NC}"
cd "$out/deb"
dpkg-deb --build . "$GITHUB_WORKSPACE/$deb_name"

echo -e "${YELLOW}Verifying package...${NC}"
dpkg-deb --info "$GITHUB_WORKSPACE/$deb_name"

echo -e "${YELLOW}Generating checksums...${NC}"
cd "$GITHUB_WORKSPACE"
sha256sum "$deb_name" > "${deb_name}.sha256"
md5sum "$deb_name" > "${deb_name}.md5"

echo "deb_out=$GITHUB_WORKSPACE/$deb_name" >> $GITHUB_OUTPUT
echo "deb_name=$deb_name" >> $GITHUB_OUTPUT
echo "version=$version.$version_code" >> $GITHUB_OUTPUT

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}✓ Build completed successfully!${NC}"
echo -e "${GREEN}Package: $deb_name${NC}"
echo -e "${GREEN}Size: $(du -h $deb_name | cut -f1)${NC}"
echo -e "${GREEN}========================================${NC}"

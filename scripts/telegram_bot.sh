#!/bin/env bash
# ========================================
# OneShot Build Telegram Notification
# Updated for resurrected21/OneShot fork
# Last Updated: October 2025
# ========================================

set -e

# Check required environment variables
if [ -z "$BOT_TOKEN" ] || [ -z "$CHAT_ID" ]; then
    echo "Error: BOT_TOKEN and CHAT_ID environment variables required!" >&2
    echo "Set them in GitHub Secrets:" >&2
    echo "  - TELEGRAM_BOT_TOKEN" >&2
    echo "  - TELEGRAM_CHAT_ID" >&2
    exit 1
fi

# File to upload
file="$1"

if [ -z "$file" ] || [ ! -f "$file" ]; then
    echo "Error: File not found: $file" >&2
    exit 1
fi

# Get file info
file_size=$(du -h "$file" | cut -f1)
file_name=$(basename "$file")

# Prepare message
msg="*OneShot Build Complete*

*Version:* $VERSION
*Build:* #ci_$VERSION
*File:* $file_name
*Size:* $file_size

*Commit Message:*
\`\`\`
$COMMIT_MESSAGE
\`\`\`

*Links:*
[View Commit]($COMMIT_URL)
[Workflow Run]($RUN_URL)
[Download Release](https://github.com/resurrected21/OneShot/releases)

*Installation:*
\`\`\`bash
wget $DOWNLOAD_URL
apt install ./$file_name
\`\`\`

Ready to use!
"

# Send to Telegram
echo "Sending notification to Telegram..."
echo "Chat ID: $CHAT_ID"
echo "File: $file"

response=$(curl -s -F document=@"$file" \
    "https://api.telegram.org/bot$BOT_TOKEN/sendDocument" \
    -F chat_id="$CHAT_ID" \
    -F "disable_web_page_preview=true" \
    -F "parse_mode=markdownv2" \
    -F caption="$msg")

# Check if successful
if echo "$response" | grep -q '"ok":true'; then
    echo "✓ Notification sent successfully!"
    echo "Response: $response"
    exit 0
else
    echo "✗ Failed to send notification!" >&2
    echo "Response: $response" >&2
    exit 1
fi

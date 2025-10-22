#!/bin/env bash
# ========================================
# OneShot Build Telegram Notification
# Updated for resurrected21/OneShot fork
# Last Updated: October 2025
# ========================================

set -e

if [ -z "$BOT_TOKEN" ] || [ -z "$CHAT_ID" ]; then
    echo "Error: BOT_TOKEN and CHAT_ID environment variables required!" >&2
    exit 1
fi

file="$1"

if [ -z "$file" ] || [ ! -f "$file" ]; then
    echo "Error: File not found: $file" >&2
    exit 1
fi

file_size=$(du -h "$file" | cut -f1)
file_name=$(basename "$file")

# Escape special characters for MarkdownV2
escape_markdown() {
    echo "$1" | sed 's/[_*[\]()~`>#+=|{}.!-]/\\&/g'
}

VERSION_ESC=$(escape_markdown "$VERSION")
FILE_NAME_ESC=$(escape_markdown "$file_name")
FILE_SIZE_ESC=$(escape_markdown "$file_size")
COMMIT_MSG_ESC=$(escape_markdown "$COMMIT_MESSAGE")

# Create message with proper escaping
msg="*OneShot Build Complete* 🚀

*Version:* \`${VERSION_ESC}\`
*File:* \`${FILE_NAME_ESC}\`
*Size:* \`${FILE_SIZE_ESC}\`

*Commit:*
\`\`\`
${COMMIT_MSG_ESC}
\`\`\`

*Links:*
[View Commit](${COMMIT_URL})
[Workflow Run](${RUN_URL})
[Download Release](${DOWNLOAD_URL})

*Installation:*
\`\`\`bash
wget ${DOWNLOAD_URL}
apt install \./oneshot\*.deb
\`\`\`

✅ Ready to use\!"

echo "Sending notification to Telegram..."
echo "Chat ID: $CHAT_ID"
echo "File: $file"

response=$(curl -s -F document=@"$file" \
    "https://api.telegram.org/bot$BOT_TOKEN/sendDocument" \
    -F chat_id="$CHAT_ID" \
    -F "disable_web_page_preview=true" \
    -F "parse_mode=markdownv2" \
    -F caption="$msg")

if echo "$response" | grep -q '"ok":true'; then
    echo "✓ Notification sent successfully!"
    exit 0
else
    echo "✗ Failed to send notification!" >&2
    echo "Response: $response" >&2
    exit 1
fi

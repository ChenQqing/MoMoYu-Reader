#!/bin/bash

echo "=========================="
echo "  摸摸鱼阅读 安装程序"
echo "=========================="
echo ""

APP_NAME="摸摸鱼.app"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SOURCE="$SCRIPT_DIR/$APP_NAME"
DEST="/Applications/$APP_NAME"

if [ ! -d "$SOURCE" ]; then
    echo "❌ 找不到 $APP_NAME，请确保安装脚本和 app 在同一目录"
    read -p "按回车退出..."
    exit 1
fi

echo "📦 正在安装到 /Applications..."
rm -rf "$DEST"
cp -R "$SOURCE" "$DEST"

echo "🔓 正在解除系统限制..."
sudo xattr -r -d com.apple.quarantine "$DEST" 2>/dev/null

echo ""
echo "✅ 安装完成！"
echo "   请在「应用程序」或 Launchpad 中打开「摸摸鱼」"
echo ""
read -p "按回车退出..."

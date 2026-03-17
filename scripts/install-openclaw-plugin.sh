#!/bin/bash
# OpenClaw Harmony Security Plugin 一键安装脚本

set -e

echo "🦞 OpenClaw Harmony Security Plugin 安装脚本"
echo "=============================================="
echo ""

# 颜色定义
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# 获取脚本所在目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

echo "📂 项目目录: $PROJECT_DIR"
echo ""

# 检查 OpenClaw CLI 是否安装
echo "🔍 检查 OpenClaw CLI..."
if ! command -v openclaw &> /dev/null; then
    echo -e "${RED}❌ OpenClaw CLI 未安装${NC}"
    echo "请先安装: npm install -g @openclaw/cli"
    exit 1
fi
echo -e "${GREEN}✓ OpenClaw CLI 已安装${NC}"
OPENCLAW_VERSION=$(openclaw --version 2>&1 | head -1)
echo "   版本: $OPENCLAW_VERSION"
echo ""

# 构建项目
echo "🔨 构建项目..."
cd "$PROJECT_DIR"
npm run build
echo -e "${GREEN}✓ 项目构建完成${NC}"
echo ""

# 检查插件目录
PLUGIN_DIR="$PROJECT_DIR/plugins/openclaw-harmony-security"
if [ ! -d "$PLUGIN_DIR" ]; then
    echo -e "${RED}❌ 插件目录不存在: $PLUGIN_DIR${NC}"
    exit 1
fi
echo "📦 插件目录: $PLUGIN_DIR"

# 检查必需文件
if [ ! -f "$PLUGIN_DIR/index.js" ]; then
    echo -e "${RED}❌ 插件入口文件缺失: index.js${NC}"
    exit 1
fi
if [ ! -f "$PLUGIN_DIR/openclaw.plugin.json" ]; then
    echo -e "${RED}❌ 插件清单文件缺失: openclaw.plugin.json${NC}"
    exit 1
fi
echo -e "${GREEN}✓ 插件文件检查通过${NC}"
echo ""

# 停止现有 Gateway
echo "🛑 停止现有 Gateway (如果正在运行)..."
openclaw gateway stop 2>/dev/null || true
sleep 2
echo ""

# 安装插件
echo "🔌 安装插件..."
openclaw plugins install "$PLUGIN_DIR"
echo ""

# 启用插件
echo "⚡ 启用插件..."
openclaw plugins enable harmony-security
echo ""

# 删除旧的插件目录（如果存在）
OLD_PLUGIN_DIR="$HOME/.openclaw/extensions/openclaw-harmony-security"
if [ -d "$OLD_PLUGIN_DIR" ]; then
    echo "🧹 清理旧的插件目录..."
    rm -rf "$OLD_PLUGIN_DIR"
    echo -e "${GREEN}✓ 已清理${NC}"
fi
echo ""

# 重启 Gateway
echo "🚀 重启 Gateway..."
openclaw gateway > /tmp/openclaw-gateway.log 2>&1 &
sleep 5
echo ""

# 验证安装
echo "🔍 验证插件安装..."
if openclaw plugins list 2>&1 | grep -q "harmony-security.*loaded"; then
    echo -e "${GREEN}✅ 插件安装成功！${NC}"
    echo ""
    echo "插件状态:"
    openclaw plugins list 2>&1 | grep -A 2 "harmony-security" | head -3
    echo ""
    echo "📖 使用说明:"
    echo "  1. 访问 http://localhost:18789 查看 Gateway Control UI"
    echo "  2. 在对话中提及 '任务ID: XXXX' 即可触发上下文注入"
    echo "  3. 查看日志: tail -f /tmp/openclaw-gateway.log"
else
    echo -e "${YELLOW}⚠️  插件可能未正确加载${NC}"
    echo "请检查日志: cat /tmp/openclaw-gateway.log"
    echo ""
    echo "手动验证命令:"
    echo "  openclaw plugins list"
fi
echo ""

echo "=============================================="
echo "安装完成！"

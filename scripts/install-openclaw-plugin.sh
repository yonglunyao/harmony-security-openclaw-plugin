#!/bin/bash
# OpenClaw Harmony Security Plugin Installation Script
# Prefers Python for cross-platform consistency

set -e

# 颜色定义
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo ""
echo "==============================================="
echo "  OpenClaw Harmony Security Plugin 安装脚本"
echo "        (含 MCP Adapter 集成)"
echo "==============================================="
echo ""

# 检查 Python 是否可用
if command -v python3 &> /dev/null; then
    PYTHON_CMD="python3"
elif command -v python &> /dev/null; then
    PYTHON_CMD="python"
else
    echo -e "${YELLOW}⚠️  Python 未找到，使用 bash 安装方式${NC}"
    PYTHON_CMD=""
fi

# 如果 Python 可用，使用 Python 脚本
if [ -n "$PYTHON_CMD" ]; then
    echo -e "${BLUE}[INFO]${NC} 使用 Python 安装脚本: $PYTHON_CMD"
    $PYTHON_CMD --version
    echo ""

    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    $PYTHON_CMD "$SCRIPT_DIR/install.py"
    exit $?
fi

# ===== 以下是 Bash 原生安装方式（备用） =====

echo -e "${BLUE}使用 Bash 原生安装方式...${NC}"
echo ""

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

# 创建数据目录
echo "📁 创建数据目录..."
mkdir -p "$PROJECT_DIR/data/samples"
mkdir -p "$PROJECT_DIR/data/knowledge"
mkdir -p "$PROJECT_DIR/data/reports"
echo -e "${GREEN}✓ 数据目录创建完成${NC}"
echo ""

# 检查/克隆 MCP Adapter
echo "🔌 检查 MCP Adapter..."
MCP_ADAPTER_DIR="$PROJECT_DIR/../openclaw-mcp-adapter"
if [ ! -d "$MCP_ADAPTER_DIR" ]; then
    echo -e "${YELLOW}⚠️  MCP Adapter 未找到，正在克隆...${NC}"
    cd "$PROJECT_DIR/.."
    git clone https://github.com/androidStern-personal/openclaw-mcp-adapter.git
    echo -e "${GREEN}✓ MCP Adapter 克隆完成${NC}"
else
    echo -e "${GREEN}✓ MCP Adapter 已存在${NC}"
fi
echo ""

# 停止现有 Gateway
echo "🛑 停止现有 Gateway (如果正在运行)..."
openclaw gateway stop 2>/dev/null || true
sleep 2
echo ""

# 安装插件
echo "🔌 安装插件..."
PLUGIN_DIR="$PROJECT_DIR/plugins/openclaw-harmony-security"
openclaw plugins install "$PLUGIN_DIR"
openclaw plugins enable harmony-security
echo -e "${GREEN}✓ Harmony Security 插件已启用${NC}"
echo ""

echo "🔌 安装 MCP Adapter 插件..."
openclaw plugins install "$MCP_ADAPTER_DIR"
echo -e "${GREEN}✓ MCP Adapter 插件已安装${NC}"
echo ""

# 配置 MCP Servers
echo "⚙️  配置 MCP Servers..."
if command -v jq &> /dev/null; then
    echo "使用 jq 配置..."
    PROJECT_ESCAPED=$(echo "$PROJECT_DIR" | sed 's/\\/\//g')
    TMP_FILE=$(mktemp)
    jq --arg project "$PROJECT_ESCAPED" '
        .plugins.entries["openclaw-mcp-adapter"].config.servers = [
            {
                name: "sample-store",
                transport: "stdio",
                command: "node",
                args: ["\($project)/dist/mcp/sample-store/index.js"],
                env: {SAMPLE_STORE_PATH: "\($project)/data/samples"}
            },
            {
                name: "knowledge-base",
                transport: "stdio",
                command: "node",
                args: ["\($project)/dist/mcp/knowledge-base/index.js"],
                env: {KNOWLEDGE_BASE_PATH: "\($project)/data/knowledge"}
            },
            {
                name: "report-store",
                transport: "stdio",
                command: "node",
                args: ["\($project)/dist/mcp/report-store/index.js"],
                env: {REPORT_OUTPUT_PATH: "\($project)/data/reports"}
            }
        ]
    ' ~/.openclaw/openclaw.json > "$TMP_FILE"
    mv "$TMP_FILE" ~/.openclaw/openclaw.json
    echo -e "${GREEN}✓ 配置已更新${NC}"
else
    echo -e "${YELLOW}⚠️  jq 未安装，请手动配置 MCP Servers${NC}"
    echo "在 ~/.openclaw/openclaw.json 中添加配置"
fi
echo ""

# 重启 Gateway
echo "🚀 重启 Gateway..."
openclaw gateway > /tmp/openclaw-gateway.log 2>&1 &
sleep 5
echo ""

# 验证安装
echo "🔍 验证插件安装..."
echo ""
echo "插件状态:"
openclaw plugins list 2>&1 | grep -E "HarmonyOS|MCP Adapter" || true
echo ""

echo "=============================================="
echo -e "${GREEN}🎉 安装完成！${NC}"
echo ""

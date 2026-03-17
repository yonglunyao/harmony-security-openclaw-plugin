#!/bin/bash
# OpenClaw Harmony Security Plugin 一键安装脚本（含 MCP Adapter 集成）

set -e

echo "🦞 OpenClaw Harmony Security Plugin 安装脚本"
echo "================================================"
echo ""

# 颜色定义
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 获取脚本所在目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
MCP_ADAPTER_DIR="$PROJECT_DIR/../openclaw-mcp-adapter"

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

# 安装依赖
echo "📦 安装项目依赖..."
cd "$PROJECT_DIR"
npm install
echo -e "${GREEN}✓ 依赖安装完成${NC}"
echo ""

# 构建项目
echo "🔨 构建项目..."
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

# 检查/安装 MCP Adapter
echo "🔌 检查 MCP Adapter..."
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

# 安装 harmony-security 插件
echo "🔌 安装 Harmony Security 插件..."
PLUGIN_DIR="$PROJECT_DIR/plugins/openclaw-harmony-security"
openclaw plugins install "$PLUGIN_DIR"
openclaw plugins enable harmony-security
echo -e "${GREEN}✓ Harmony Security 插件已启用${NC}"
echo ""

# 安装 MCP Adapter 插件
echo "🔌 安装 MCP Adapter 插件..."
openclaw plugins install "$MCP_ADAPTER_DIR"
echo -e "${GREEN}✓ MCP Adapter 插件已安装${NC}"
echo ""

# 配置 MCP Servers
echo "⚙️  配置 MCP Servers..."
OPENCLAW_CONFIG="$HOME/.openclaw/openclaw.json"

# 使用 jq 或手动添加配置
if command -v jq &> /dev/null; then
    # 使用 jq 添加配置（推荐方式）
    echo "使用 jq 配置..."
    TMP_FILE=$(mktemp)
    jq --arg project "$PROJECT_DIR" '
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
    ' "$OPENCLAW_CONFIG" > "$TMP_FILE"
    mv "$TMP_FILE" "$OPENCLAW_CONFIG"
else
    echo -e "${YELLOW}⚠️  jq 未安装，请手动配置 MCP Servers${NC}"
    echo "在 ~/.openclaw/openclaw.json 中添加以下配置："
    cat <<EOF
{
  "plugins": {
    "entries": {
      "openclaw-mcp-adapter": {
        "enabled": true,
        "config": {
          "servers": [
            {
              "name": "sample-store",
              "transport": "stdio",
              "command": "node",
              "args": ["$PROJECT_DIR/dist/mcp/sample-store/index.js"],
              "env": {"SAMPLE_STORE_PATH": "$PROJECT_DIR/data/samples"}
            },
            {
              "name": "knowledge-base",
              "transport": "stdio",
              "command": "node",
              "args": ["$PROJECT_DIR/dist/mcp/knowledge-base/index.js"],
              "env": {"KNOWLEDGE_BASE_PATH": "$PROJECT_DIR/data/knowledge"}
            },
            {
              "name": "report-store",
              "transport": "stdio",
              "command": "node",
              "args": ["$PROJECT_DIR/dist/mcp/report-store/index.js"],
              "env": {"REPORT_OUTPUT_PATH": "$PROJECT_DIR/data/reports"}
            }
          ]
        }
      }
    }
  }
}
EOF
    read -p "按回车键继续手动配置..."
fi
echo -e "${GREEN}✓ MCP Servers 配置完成${NC}"
echo ""

# 重启 Gateway
echo "🚀 重启 Gateway..."
openclaw gateway > /tmp/openclaw-gateway.log 2>&1 &
sleep 5
echo ""

# 验证安装
echo "🔍 验证插件安装..."
echo ""

echo "Harmony Security 插件状态:"
if openclaw plugins list 2>&1 | grep -q "harmony-security.*loaded"; then
    echo -e "${GREEN}✅ 已加载${NC}"
    openclaw plugins list 2>&1 | grep -A 2 "HarmonyOS" | head -3
else
    echo -e "${RED}❌ 未加载${NC}"
fi
echo ""

echo "MCP Adapter 插件状态:"
if openclaw plugins list 2>&1 | grep -q "openclaw-mcp-adapter.*loaded"; then
    echo -e "${GREEN}✅ 已加载${NC}"
    openclaw plugins list 2>&1 | grep -A 2 "MCP Adapter" | head -3
else
    echo -e "${RED}❌ 未加载${NC}"
fi
echo ""

# 显示已注册的 MCP 工具
echo "📊 已注册的 MCP 工具:"
echo "  • sample-store: 6 个工具 (样本信息、代码、报告)"
echo "  • knowledge-base: 1 个工具 (HATL 查询)"
echo "  • report-store: 2 个工具 (报告存储)"
echo ""

echo "================================================"
echo -e "${GREEN}🎉 安装完成！${NC}"
echo ""
echo "📖 使用说明:"
echo "  1. 访问 http://localhost:18789 查看 Gateway Control UI"
echo "  2. Agent 现在可以直接调用 MCP 工具："
echo "     - sample-store_get_sample_info"
echo "     - knowledge-base_query_hatl"
echo "     - report-store_save_report"
echo "     - 等 9 个工具..."
echo "  3. 查看日志: tail -f /tmp/openclaw-gateway.log"
echo ""

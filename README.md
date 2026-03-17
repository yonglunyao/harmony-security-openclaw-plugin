# 鸿蒙应用安全分析 Agent 系统

基于 Agent + 大模型的鸿蒙应用安全分析辅助系统，实现从传统人工分析向 **Agent助理+人工分析** 模式的转变。

## 核心特性

- **🤖 Agent 先行分析** - 自动完成重复性分析动作（机检报告解读、代码分析、流量查询）
- **📊 多维度检测** - 恶意行为识别、权限滥用检测、第三方组件分析
- **🧠 HATL 知识库** - 基于鸿蒙攻击技术知识库进行智能匹配
- **💡 存疑点标记** - Agent 无法确定的问题输出存疑清单，由人工深入分析
- **🔌 多工作台支持** - 支持 OpenClaw Gateway、Telegram、飞书等渠道
- **🔗 MCP Adapter 集成** - 自动管理 MCP Servers，无需手动启动

## 系统架构

```
┌─────────────────────────────────────────────────────────────────────────┐
│                          用户交互层                                      │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐                   │
│  │  Telegram    │  │    飞书      │  │   Dashboard  │                   │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘                   │
└─────────┼─────────────────┼─────────────────┼───────────────────────────┘
          │                 │                 │
          └─────────────────┼─────────────────┘
                            ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                     OpenClaw Gateway (Agent 编排)                        │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │              MCP Adapter Plugin (工具桥接)                       │   │
│  │  ┌───────────┐  ┌───────────┐  ┌───────────┐                    │   │
│  │  │ MCP Client│  │ MCP Client│  │ MCP Client│                    │   │
│  │  └─────┬─────┘  └─────┬─────┘  └─────┬─────┘                    │   │
│  └────────┼─────────────┼─────────────┼────────────────────────────┘   │
│           │             │             │                                 │
│  ┌────────┼─────────────┼─────────────┼────────────────────────────┐   │
│  │     HarmonyOS Security Analysis Plugin                          │   │
│  │     (上下文注入、任务编排)                                        │   │
│  └──────────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────────┘
          │             │             │
          ▼             ▼             ▼
    ┌──────────┐  ┌──────────┐  ┌──────────┐
    │   MCP    │  │   MCP    │  │   MCP    │
    │  Server  │  │  Server  │  │  Server  │
    │ (样本)   │  │ (知识库) │  │ (报告)   │
    └──────────┘  └──────────┘  └──────────┘
```

## 项目结构

```
harmony-analyse-system/
├── src/
│   └── mcp/                      # MCP Servers
│       ├── sample-store/          # 样本数据服务 (6个工具)
│       │   ├── server.ts          # 服务器实现
│       │   ├── types.ts           # 数据类型定义
│       │   └── data/
│       │       └── mock-data.ts   # 模拟数据
│       ├── knowledge-base/        # HATL 知识库 (1个工具)
│       │   └── server.ts
│       └── report-store/          # 报告存储 (2个工具)
│           └── server.ts
├── skills/                         # 分析技能 (8个)
│   ├── harmony-sample-fetcher.skill
│   ├── harmony-report-reader.skill
│   ├── harmony-code-analyzer.skill
│   ├── harmony-malware-detector.skill
│   ├── harmony-permission-analyzer.skill
│   ├── harmony-sdk-analyzer.skill
│   └── harmony-report-generator.skill
├── plugins/                        # OpenClaw 插件
│   └── openclaw-harmony-security/
│       ├── index.js                # 插件实现
│       └── package.json
├── scripts/                        # 工具脚本
│   ├── install-openclaw-plugin.sh  # 一键安装脚本
│   └── install-openclaw-plugin.bat
├── tests/                          # 测试文件
│   └── integration/
│       └── analysis-flow.test.ts
├── data/                           # 数据目录
│   ├── samples/                    # 样本存储
│   ├── knowledge/                  # 知识库
│   └── reports/                    # 报告输出
├── docs/                           # 文档
│   └── plans/                      # 设计文档
├── dist/                           # 编译输出
└── CLAUDE.md                       # Claude Code 指南
```

## 快速开始

### 前置要求

- Node.js >= 18.0.0
- npm 或 yarn
- OpenClaw CLI: `npm install -g @openclaw/cli`
- jq (可选，用于自动配置): Linux/macOS: `sudo apt install jq` 或 `brew install jq`

### 安装

```bash
# 克隆项目
git clone <repository-url>
cd harmony-analyse-system

# 安装依赖
npm install

# 构建项目
npm run build
```

### 一键安装（推荐）

使用 Python 统一安装脚本，自动完成所有配置：

**Windows:**
```bash
# 双击运行，或命令行执行
scripts\install-openclaw-plugin.bat
```

**Linux/macOS:**
```bash
# 直接运行（会自动使用 Python 或 bash）
chmod +x scripts/install-openclaw-plugin.sh
./scripts/install-openclaw-plugin.sh

# 或直接使用 Python
python3 scripts/install.py
```

**安装脚本会自动：**
1. ✓ 检查并安装依赖
2. ✓ 构建项目
3. ✓ 克隆 openclaw-mcp-adapter
4. ✓ 安装两个插件
5. ✓ 配置 MCP Servers（支持 Python 或 jq）
6. ✓ 启动 Gateway
7. ✓ 验证安装

**系统要求：**
- Python 3.6+ （推荐）
- Node.js >= 18.0.0
- OpenClaw CLI: `npm install -g @openclaw/cli`

### 手动安装

如果自动安装脚本不适用，可以手动安装：

```bash
# 1. 安装 Harmony Security 插件
openclaw plugins install ./plugins/openclaw-harmony-security
openclaw plugins enable harmony-security

# 2. 克隆并安装 MCP Adapter
cd ..
git clone https://github.com/androidStern-personal/openclaw-mcp-adapter.git
openclaw plugins install ./openclaw-mcp-adapter

# 3. 配置 MCP Servers（添加到 ~/.openclaw/openclaw.json）
```

**MCP Servers 配置示例:**
```json
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
              "args": ["D:/workspace/harmony-analyse-system/dist/mcp/sample-store/index.js"],
              "env": {"SAMPLE_STORE_PATH": "D:/workspace/harmony-analyse-system/data/samples"}
            },
            {
              "name": "knowledge-base",
              "transport": "stdio",
              "command": "node",
              "args": ["D:/workspace/harmony-analyse-system/dist/mcp/knowledge-base/index.js"],
              "env": {"KNOWLEDGE_BASE_PATH": "D:/workspace/harmony-analyse-system/data/knowledge"}
            },
            {
              "name": "report-store",
              "transport": "stdio",
              "command": "node",
              "args": ["D:/workspace/harmony-analyse-system/dist/mcp/report-store/index.js"],
              "env": {"REPORT_OUTPUT_PATH": "D:/workspace/harmony-analyse-system/data/reports"}
            }
          ]
        }
      }
    }
  }
}
```

```bash
# 4. 重启 Gateway
openclaw gateway stop
openclaw gateway
```

### 验证安装

```bash
# 检查插件状态
openclaw plugins list

# 应该看到：
# │ HarmonyOS Security Analysis │ harmony-security │ loaded │ ... │
# │ MCP Adapter                │ openclaw-mcp-adapter │ loaded │ ... │
```

## MCP 工具列表

安装成功后，Agent 可以直接调用以下工具：

### sample-store (6个工具)

| 工具名 | 说明 | 参数 |
|--------|------|------|
| `sample-store_get_sample_info` | 获取样本基本信息 | `task_id` |
| `sample-store_get_code_tree` | 获取代码目录树 | `task_id` |
| `sample-store_get_code_file` | 读取代码文件内容 | `task_id`, `file_path` |
| `sample-store_get_static_report` | 获取静态扫描报告 | `task_id` |
| `sample-store_get_dynamic_report` | 获取动态沙箱报告 | `task_id` |
| `sample-store_get_traffic_report` | 获取流量分析报告 | `task_id` |

### knowledge-base (1个工具)

| 工具名 | 说明 | 参数 |
|--------|------|------|
| `knowledge-base_query_hatl` | 查询 HATL 攻击技术知识库 | `query`, `category`(可选) |

### report-store (2个工具)

| 工具名 | 说明 | 参数 |
|--------|------|------|
| `report-store_save_report` | 保存分析报告 | `task_id`, `report_content` |
| `report-store_get_report` | 获取历史报告 | `task_id` |

## Skills 列表

| Skill | 说明 |
|-------|------|
| `harmony-sample-fetcher` | 根据任务ID获取样本全部信息 |
| `harmony-report-reader` | 解读机检报告（静态/动态/流量） |
| `harmony-code-analyzer` | 分析代码识别风险模式 |
| `harmony-malware-detector` | 恶意行为识别（基于HATL） |
| `harmony-permission-analyzer` | 权限滥用检测 |
| `harmony-sdk-analyzer` | 第三方SDK风险分析 |
| `harmony-report-generator` | 生成安全分析报告 |

## 使用方式

### 通过 OpenClaw Gateway

```bash
# 1. 确保 Gateway 正在运行
openclaw health

# 2. 通过连接的渠道发送消息
# Telegram: 发送消息给配置的 Bot
# 飞书: 在配置的群组中 @机器人
# Dashboard: 访问 http://localhost:18789

# 3. 示例对话
# 用户: "分析任务 TASK-2026-001"
# Agent: [自动调用 MCP 工具] 获取样本信息 → 读取报告 → 分析代码 → 生成报告
```

### 通过 Claude Code CLI

```bash
# 1. 确保 Gateway 正在运行且 MCP Adapter 已配置
# 2. 在 Claude Code 中对话
# "分析任务 TASK-001"
# Agent 将自动调用 MCP 工具获取样本信息并进行分析
```

## 开发指南

```bash
# 开发模式（监听文件变化）
npm run dev

# 运行测试
npm test

# 运行单个测试
npm test -- tests/mcp/sample-store.test.ts

# 重新构建（修改代码后）
npm run build
```

## 分析流程

```
用户提供任务ID
    ↓
Phase 1: 信息收集
    ├─ 调用 sample-store_get_sample_info
    ├─ 调用 sample-store_get_code_tree
    └─ 调用 sample-store_get_static_report
    ↓
Phase 2: 报告解读
    ├─ 静态报告分析
    ├─ 动态报告分析
    └─ 流量报告分析
    ↓
Phase 3: 代码分析
    ├─ 调用 sample-store_get_code_file
    └─ 识别风险模式和可疑代码
    ↓
Phase 4: 风险判定
    ├─ 调用 knowledge-base_query_hatl
    ├─ 恶意行为检测
    ├─ 权限滥用分析
    └─ SDK 风险评估
    ↓
Phase 5: 报告生成
    ├─ 汇总分析结果
    ├─ 调用 report-store_save_report
    └─ 输出存疑点清单
    ↓
Phase 6: 人工审核
    └─ 专家确认/修正结论
```

## 报告模板

```markdown
# 鸿蒙应用安全分析报告

## 基本信息
| 字段 | 值 |
|------|-----|
| 任务ID | {task_id} |
| 包名 | {package_name} |

## 恶意结论
**判定结果**: {malicious | suspicious | benign}
**置信度**: {high | medium | low}

## 风险摘要
| 风险类别 | 风险等级 | 简述 |
|----------|----------|------|
| 恶意行为 | {level} | {summary} |

## 存疑点清单
| 序号 | 存疑点描述 | 建议人工分析方向 |
|------|-----------|-----------------|
```

## 故障排除

### 插件未加载

```bash
# 检查插件状态
openclaw plugins list

# 检查 Gateway 日志
# Linux/macOS:
tail -f /tmp/openclaw-gateway.log
# Windows:
type %TEMP%\openclaw-gateway.log
```

### MCP 工具不可用

1. 确认项目已构建：`npm run build`
2. 确认路径配置正确（使用正斜杠 `/`）
3. 重启 Gateway：`openclaw gateway stop && openclaw gateway`

### MCP Adapter 连接失败

```bash
# 手动测试 MCP Server
node dist/mcp/knowledge-base/index.js

# 应该输出：Knowledge Base MCP Server running on stdio
# 然后等待输入（Ctrl+C 退出）
```

## 文档

- [设计方案](./docs/plans/2026-03-17-harmony-security-analysis-system-design.md)
- [实现计划](./docs/plans/2026-03-17-harmony-security-analysis-implementation.md)
- [CLAUDE.md](./CLAUDE.md) - Claude Code 开发指南
- [MCP Adapter](https://github.com/androidStern-personal/openclaw-mcp-adapter) - MCP 工具桥接插件

## 许可证

MIT License - 详见 [LICENSE](./LICENSE)

## 作者

Yonglun Yao <yonglunyao@gmail.com>

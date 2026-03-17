# 鸿蒙应用安全分析 Agent 系统

基于 Agent + 大模型的鸿蒙应用安全分析辅助系统，实现从传统人工分析向 **Agent助理+人工分析** 模式的转变。

## 核心特性

- **🤖 Agent 先行分析** - 自动完成重复性分析动作（机检报告解读、代码分析、流量查询）
- **📊 多维度检测** - 恶意行为识别、权限滥用检测、第三方组件分析
- **🧠 HATL 知识库** - 基于鸿蒙攻击技术知识库进行智能匹配
- **💡 存疑点标记** - Agent 无法确定的问题输出存疑清单，由人工深入分析
- **🔌 多工作台支持** - 支持 OpenClaw Dashboard、Claude Code CLI、Web 界面

## 系统架构

```
┌─────────────────────────────────────────────────────────────────────────┐
│                          人工工作台层                                    │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐                   │
│  │ OpenClaw     │  │ Claude Code  │  │ 自建 Web     │                   │
│  │ Dashboard    │  │ CLI          │  │ Interface    │                   │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘                   │
└─────────┼─────────────────┼─────────────────┼───────────────────────────┘
          │                 │                 │
          └─────────────────┼─────────────────┘
                            ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                     OpenClaw Gateway (Agent 编排)                        │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │              HarmonyOS Security Analysis Plugin                  │   │
│  └─────────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────────┘
                            │
          ┌─────────────────┼─────────────────┐
          ▼                 ▼                 ▼
┌──────────────────┐ ┌──────────────────┐ ┌──────────────────┐
│   Skills 层      │ │   MCP Tools      │ │   知识库层       │
│  (分析逻辑编排)   │ │   (数据访问)      │ │  (HATL/案例)     │
└──────────────────┘ └──────────────────┘ └──────────────────┘
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
│   ├── start-mcp-servers.sh        # 启动所有 MCP 服务
│   └── stop-mcp-servers.sh         # 停止所有 MCP 服务
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
├── CLAUDE.md                       # Claude Code 指南
└── openclaw.config.json            # OpenClaw 配置
```

## 快速开始

### 前置要求

- Node.js >= 18.0.0
- npm 或 yarn

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

### 配置

```bash
# 复制环境变量模板
cp .env.example .env

# 编辑 .env 文件，配置实际参数
# vim .env
```

### 启动 MCP Servers

```bash
# 批量启动所有 MCP Servers
./scripts/start-mcp-servers.sh

# 或单独启动
node dist/mcp/sample-store/index.js
node dist/mcp/knowledge-base/index.js
node dist/mcp/report-store/index.js
```

### 停止 MCP Servers

```bash
./scripts/stop-mcp-servers.sh
```

## MCP 工具列表

### sample-store (6个工具)

| 工具名 | 说明 |
|--------|------|
| `get_sample_info` | 获取样本基本信息（包名、版本、签名等） |
| `get_code_tree` | 获取逆向代码目录树结构 |
| `get_code_file` | 读取指定代码文件内容 |
| `get_static_report` | 获取静态扫描报告 |
| `get_dynamic_report` | 获取动态沙箱报告 |
| `get_traffic_report` | 获取流量分析报告 |

### knowledge-base (1个工具)

| 工具名 | 说明 |
|--------|------|
| `query_hatl` | 查询 HATL 攻击技术知识库 |

### report-store (2个工具)

| 工具名 | 说明 |
|--------|------|
| `save_report` | 保存分析报告 |
| `get_report` | 获取历史报告 |

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

## 使用示例

### Claude Code CLI

```bash
# 1. 启动 MCP Servers
./scripts/start-mcp-servers.sh

# 2. 在 Claude Code 中对话
# "分析任务 TASK-001"
# Agent 将自动调用 MCP 工具获取样本信息并进行分析
```

### OpenClaw Gateway

```bash
# 1. 配置 openclaw.config.json 到你的 Gateway

# 2. 启动 Gateway

# 3. 发送消息分析任务
# "分析任务 TASK-001"
```

## 开发指南

```bash
# 开发模式（监听文件变化）
npm run dev

# 运行测试
npm test

# 运行单个测试
npm test -- tests/mcp/sample-store.test.ts
```

## 分析流程

```
用户提供任务ID
    ↓
Phase 1: 信息收集
    ├─ 获取样本元数据
    ├─ 获取代码目录树
    └─ 获取机检报告
    ↓
Phase 2: 报告解读
    ├─ 静态报告分析
    ├─ 动态报告分析
    └─ 流量报告分析
    ↓
Phase 3: 代码分析
    └─ 识别风险模式和可疑代码
    ↓
Phase 4: 风险判定
    ├─ 恶意行为检测
    ├─ 权限滥用分析
    └─ SDK 风险评估
    ↓
Phase 5: 报告生成
    ├─ 汇总分析结果
    ├─ 生成风险摘要
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

## 文档

- [设计方案](./docs/plans/2026-03-17-harmony-security-analysis-system-design.md)
- [实现计划](./docs/plans/2026-03-17-harmony-security-analysis-implementation.md)
- [CLAUDE.md](./CLAUDE.md) - Claude Code 开发指南

## 许可证

MIT License - 详见 [LICENSE](./LICENSE)

## 作者

Yonglun Yao <yonglunyao@gmail.com>

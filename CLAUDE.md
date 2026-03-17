# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

鸿蒙应用安全分析 Agent 系统 - 基于 Agent + 大模型的鸿蒙应用安全分析辅助系统，辅助人工专家分析恶意应用和安全风险。

## Common Commands

```bash
# 构建
npm run build

# 开发模式（监听文件变化）
npm run dev

# 运行测试
npm test

# 运行单个测试文件
npm test -- tests/mcp/sample-store.test.ts

# 启动 MCP Servers（用于开发调试）
node dist/mcp/sample-store/index.js
node dist/mcp/knowledge-base/index.js
node dist/mcp/report-store/index.js

# 批量启动所有 MCP Servers
./scripts/start-mcp-servers.sh

# 停止所有 MCP Servers
./scripts/stop-mcp-servers.sh
```

## Architecture

### 三层架构

```
┌─────────────────────────────────────────────────────────────┐
│                    Skills 层 (8个)                         │
│  分析逻辑编排：样本获取、报告解读、代码分析、恶意检测等     │
└─────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────┐
│                   MCP Servers 层 (3个)                      │
│  数据访问：sample-store, knowledge-base, report-store       │
└─────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────┐
│                  OpenClaw Plugin 层                         │
│  Gateway 集成：任务调度、上下文注入、会话管理               │
└─────────────────────────────────────────────────────────────┘
```

### MCP Servers

**sample-store** (`src/mcp/sample-store/`)
- 提供样本数据的统一访问接口
- 工具：`get_sample_info`, `get_code_tree`, `get_code_file`, `get_static_report`, `get_dynamic_report`, `get_traffic_report`
- 数据模型：`types.ts` 定义所有接口类型

**knowledge-base** (`src/mcp/knowledge-base/`)
- HATL 攻击技术知识库查询
- 工具：`query_hatl` - 支持按关键词或分类搜索攻击技术

**report-store** (`src/mcp/report-store/`)
- 分析报告的存储和检索
- 工具：`save_report`, `get_report`

### Skills

位于 `skills/` 目录，每个 `.skill` 文件定义一个分析技能：
- `harmony-sample-fetcher` - 样本信息获取
- `harmony-report-reader` - 报告解读
- `harmony-code-analyzer` - 代码分析
- `harmony-malware-detector` - 恶意行为检测
- `harmony-permission-analyzer` - 权限分析
- `harmony-sdk-analyzer` - SDK 分析
- `harmony-report-generator` - 报告生成

### OpenClaw Plugin

`plugins/openclaw-harmony-security/index.js`
- 监听 OpenClaw Gateway 事件
- `beforeAgentStart`: 提取任务ID，注入上下文
- `toolResultPersist`: 记录分析结果
- `agentEnd`: 汇总会话数据

## TypeScript Configuration

- 目标：ES2022
- 模块系统：ESNext (ESM)
- 严格模式：`strict: true`
- 输出：`dist/` 目录
- 启用 sourceMap 和 declaration

## MCP Server 实现模式

所有 MCP Server 遵循统一模式：

```typescript
import { Server } from '@modelcontextprotocol/sdk/server/index.js';
import { StdioServerTransport } from '@modelcontextprotocol/sdk/server/stdio.js';
import { CallToolRequestSchema, ListToolsRequestSchema } from '@modelcontextprotocol/sdk/types.js';

export class XxxServer {
  private server: Server;

  constructor() {
    this.server = new Server({ name: 'xxx', version: '0.1.0' }, {
      capabilities: { tools: {} }
    });
    this.setupHandlers();
  }

  private setupHandlers() {
    // 注册工具列表
    this.server.setRequestHandler(ListToolsRequestSchema, async () => ({ tools: [...] }));

    // 处理工具调用
    this.server.setRequestHandler(CallToolRequestSchema, async (request) => {
      // 实现工具逻辑，返回 { content: [{ type: 'text', text: '...' }] }
    });
  }

  async start() {
    const transport = new StdioServerTransport();
    await this.server.connect(transport);
  }
}
```

## 环境变量

参考 `.env.example`：
- `SAMPLE_STORE_BASE_URL` - 样本存储服务地址
- `REPORT_OUTPUT_PATH` - 报告输出目录
- `OPENCLAW_GATEWAY_URL` - OpenClaw Gateway 地址

## 相关文档

- [设计方案](./docs/plans/2026-03-17-harmony-security-analysis-system-design.md)
- [实现计划](./docs/plans/2026-03-17-harmony-security-analysis-implementation.md)

# 鸿蒙应用安全分析 Agent 系统实现计划

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** 构建一个基于 Agent + 大模型的鸿蒙应用安全分析辅助系统，实现从传统人工分析向 Agent助理+人工分析模式的转变。

**Architecture:**
- 基于 OpenClaw Gateway 作为 Agent 编排中心
- Plugin 封装鸿蒙安全分析专用逻辑
- Skills 负责分析逻辑，MCP 负责数据访问
- 多工作台通过 Gateway 统一接入

**Tech Stack:**
- OpenClaw Gateway (Agent 编排)
- MCP (Model Context Protocol) - 数据服务
- Skills - 分析逻辑
- TypeScript/Node.js - 主要开发语言
- Markdown - 报告格式

---

## Phase 1: 基础设施

### Task 1.1: 创建项目结构

**Files:**
- Create: `package.json`
- Create: `tsconfig.json`
- Create: `.env.example`
- Create: `README.md`

**Step 1: 创建 package.json**

```json
{
  "name": "harmony-security-analysis",
  "version": "0.1.0",
  "description": "鸿蒙应用安全分析 Agent 系统",
  "type": "module",
  "scripts": {
    "dev": "tsc --watch",
    "build": "tsc",
    "test": "vitest",
    "mcp:sample-store": "node dist/mcp/sample-store/index.js"
  },
  "dependencies": {
    "@modelcontextprotocol/sdk": "^1.0.4"
  },
  "devDependencies": {
    "@types/node": "^20.0.0",
    "typescript": "^5.0.0",
    "vitest": "^1.0.0"
  }
}
```

**Step 2: 创建 tsconfig.json**

```json
{
  "compilerOptions": {
    "target": "ES2022",
    "module": "ESNext",
    "moduleResolution": "node",
    "outDir": "./dist",
    "rootDir": "./src",
    "strict": true,
    "esModuleInterop": true,
    "skipLibCheck": true,
    "forceConsistentCasingInFileNames": true,
    "resolveJsonModule": true
  },
  "include": ["src/**/*"],
  "exclude": ["node_modules", "dist"]
}
```

**Step 3: 创建 .env.example**

```env
# Sample Store MCP
SAMPLE_STORE_BASE_URL=http://localhost:3001
SAMPLE_STORE_API_KEY=your_api_key

# Knowledge Base MCP
KNOWLEDGE_BASE_PATH=./data/knowledge
HATL_DB_PATH=./data/hatl/db.json

# Report Store
REPORT_OUTPUT_PATH=./data/reports

# OpenClaw Gateway
OPENCLAW_GATEWAY_URL=http://localhost:8080
```

**Step 4: 创建 README.md**

```markdown
# 鸿蒙应用安全分析 Agent 系统

基于 Agent + 大模型的鸿蒙应用安全分析辅助系统。

## 项目结构

```
harmony-analyse-system/
├── src/
│   ├── mcp/              # MCP Servers
│   │   ├── sample-store/ # 样本存储服务
│   │   ├── knowledge-base/# 知识库服务
│   │   └── report-store/ # 报告存储服务
│   └── skills/           # Skills
├── data/                 # 数据目录
├── docs/                 # 文档
└── dist/                 # 编译输出
```

## 快速开始

```bash
# 安装依赖
npm install

# 构建
npm run build

# 启动 MCP Server
npm run mcp:sample-store
```

## 文档

- [设计方案](./docs/plans/2026-03-17-harmony-security-analysis-system-design.md)
- [实现计划](./docs/plans/2026-03-17-harmony-security-analysis-implementation.md)
```

**Step 5: Commit**

```bash
git add package.json tsconfig.json .env.example README.md
git commit -m "chore: initialize project structure"
```

---

### Task 1.2: 创建 sample-store MCP Server 框架

**Files:**
- Create: `src/mcp/sample-store/index.ts`
- Create: `src/mcp/sample-store/server.ts`
- Create: `src/mcp/sample-store/tools.ts`

**Step 1: 创建 server.ts - MCP Server 基础框架**

```typescript
import { Server } from '@modelcontextprotocol/sdk/server/index.js';
import { StdioServerTransport } from '@modelcontextprotocol/sdk/server/stdio.js';
import {
  CallToolRequestSchema,
  ListToolsRequestSchema,
} from '@modelcontextprotocol/sdk/types.js';

export class SampleStoreServer {
  private server: Server;

  constructor() {
    this.server = new Server(
      {
        name: 'sample-store',
        version: '0.1.0',
      },
      {
        capabilities: {
          tools: {},
        },
      }
    );

    this.setupHandlers();
  }

  private setupHandlers() {
    // List tools
    this.server.setRequestHandler(
      ListToolsRequestSchema,
      async () => {
        return {
          tools: [
            {
              name: 'get_sample_info',
              description: '根据任务ID获取样本基本信息（包名、版本、签名等）',
              inputSchema: {
                type: 'object',
                properties: {
                  task_id: {
                    type: 'string',
                    description: '任务ID',
                  },
                },
                required: ['task_id'],
              },
            },
            {
              name: 'get_code_tree',
              description: '获取逆向JS代码的目录树结构',
              inputSchema: {
                type: 'object',
                properties: {
                  task_id: {
                    type: 'string',
                    description: '任务ID',
                  },
                },
                required: ['task_id'],
              },
            },
            {
              name: 'get_code_file',
              description: '读取指定代码文件内容',
              inputSchema: {
                type: 'object',
                properties: {
                  task_id: {
                    type: 'string',
                    description: '任务ID',
                  },
                  file_path: {
                    type: 'string',
                    description: '文件相对路径',
                  },
                },
                required: ['task_id', 'file_path'],
              },
            },
          ],
        };
      }
    );

    // Call tools
    this.server.setRequestHandler(
      CallToolRequestSchema,
      async (request) => {
        const { name, arguments: args } = request.params;

        switch (name) {
          case 'get_sample_info':
            return await this.getSampleInfo(args.task_id as string);
          case 'get_code_tree':
            return await this.getCodeTree(args.task_id as string);
          case 'get_code_file':
            return await this.getCodeFile(
              args.task_id as string,
              args.file_path as string
            );
          default:
            throw new Error(`Unknown tool: ${name}`);
        }
      }
    );
  }

  async getSampleInfo(taskId: string) {
    // TODO: 实现获取样本信息
    return {
      content: [
        {
          type: 'text',
          text: `Sample info for ${taskId}: Not implemented yet`,
        },
      ],
    };
  }

  async getCodeTree(taskId: string) {
    // TODO: 实现获取代码树
    return {
      content: [
        {
          type: 'text',
          text: `Code tree for ${taskId}: Not implemented yet`,
        },
      ],
    };
  }

  async getCodeFile(taskId: string, filePath: string) {
    // TODO: 实现获取代码文件
    return {
      content: [
        {
          type: 'text',
          text: `Code file ${filePath} for ${taskId}: Not implemented yet`,
        },
      ],
    };
  }

  async start() {
    const transport = new StdioServerTransport();
    await this.server.connect(transport);
    console.error('Sample Store MCP Server running on stdio');
  }
}
```

**Step 2: 创建 index.ts - 入口文件**

```typescript
import { SampleStoreServer } from './server.js';

const server = new SampleStoreServer();
server.start().catch(console.error);
```

**Step 3: 创建 tools.ts - 工具实现（占位）**

```typescript
// 工具实现将在这里添加
export * from './server.js';
```

**Step 4: 创建测试文件**

```typescript
// tests/mcp/sample-store.test.ts
import { describe, it, expect } from 'vitest';

describe('SampleStoreServer', () => {
  it('should create server instance', () => {
    // 测试将在实现后添加
    expect(true).toBe(true);
  });
});
```

**Step 5: Commit**

```bash
git add src/mcp/sample-store/
git commit -m "feat: create sample-store MCP server framework"
```

---

### Task 1.3: 实现 sample-store 数据模型

**Files:**
- Create: `src/mcp/sample-store/types.ts`
- Create: `src/mcp/sample-store/data/mock-data.ts`

**Step 1: 创建类型定义**

```typescript
// src/mcp/sample-store/types.ts

export interface SampleInfo {
  task_id: string;
  package_name: string;
  version: string;
  signature: {
    issuer: string;
    subject: string;
    valid_from: string;
    valid_to: string;
  };
  file_size: number;
  created_at: string;
}

export interface CodeTreeNode {
  name: string;
  path: string;
  type: 'file' | 'directory';
  children?: CodeTreeNode[];
}

export interface StaticReport {
  permissions: string[];
  apis: string[];
  components: string[];
  risks: RiskItem[];
}

export interface DynamicReport {
  behaviors: BehaviorItem[];
  file_operations: FileOperation[];
  network_requests: NetworkRequest[];
}

export interface TrafficReport {
  domains: string[];
  endpoints: string[];
  protocols: string[];
  suspicious_activity: string[];
}

export interface RiskItem {
  id: string;
  level: 'high' | 'medium' | 'low';
  category: string;
  description: string;
  evidence?: string;
}

export interface BehaviorItem {
  timestamp: string;
  action: string;
  details: string;
}

export interface FileOperation {
  timestamp: string;
  path: string;
  operation: 'read' | 'write' | 'delete';
}

export interface NetworkRequest {
  timestamp: string;
  url: string;
  method: string;
  headers?: Record<string, string>;
}
```

**Step 2: 创建 Mock 数据**

```typescript
// src/mcp/sample-store/data/mock-data.ts

import type { SampleInfo, CodeTreeNode, StaticReport, DynamicReport, TrafficReport } from '../types.js';

export const mockSampleInfo: SampleInfo = {
  task_id: 'TASK-001',
  package_name: 'com.example.malicious.app',
  version: '1.0.0',
  signature: {
    issuer: 'CN=Example CA',
    subject: 'CN=Example Developer',
    valid_from: '2024-01-01T00:00:00Z',
    valid_to: '2025-01-01T00:00:00Z',
  },
  file_size: 5242880,
  created_at: '2024-03-15T10:30:00Z',
};

export const mockCodeTree: CodeTreeNode = {
  name: 'src',
  path: 'src',
  type: 'directory',
  children: [
    {
      name: 'ets',
      path: 'src/ets',
      type: 'directory',
      children: [
        {
          name: 'entryability',
          path: 'src/ets/entryability',
          type: 'directory',
          children: [
            { name: 'EntryAbility.ets', path: 'src/ets/entryability/EntryAbility.ets', type: 'file' },
          ],
        },
        {
          name: 'pages',
          path: 'src/ets/pages',
          type: 'directory',
          children: [
            { name: 'Index.ets', path: 'src/ets/pages/Index.ets', type: 'file' },
          ],
        },
        {
          name: 'utils',
          path: 'src/ets/utils',
          type: 'directory',
          children: [
            { name: 'CryptoUtil.ets', path: 'src/ets/utils/CryptoUtil.ets', type: 'file' },
            { name: 'NetworkUtil.ets', path: 'src/ets/utils/NetworkUtil.ets', type: 'file' },
          ],
        },
      ],
    },
  ],
};

export const mockStaticReport: StaticReport = {
  permissions: [
    'ohos.permission.INTERNET',
    'ohos.permission.READ_CONTACTS',
    'ohos.permission.WRITE_CONTACTS',
    'ohos.permission.READ_SMS',
    'ohos.permission.WRITE_SMS',
  ],
  apis: [
    '@ohos.telephony.sms',
    '@ohos.contacts',
    '@ohos.net.http',
  ],
  components: [
    'EntryAbility',
    'MainPage',
  ],
  risks: [
    {
      id: 'R001',
      level: 'high',
      category: '权限滥用',
      description: '申请了敏感的短信和联系人权限',
      evidence: 'module.json5 中声明了 ohos.permission.READ_SMS',
    },
  ],
};

export const mockDynamicReport: DynamicReport = {
  behaviors: [
    { timestamp: '2024-03-15T10:31:00Z', action: 'send_sms', details: '发送短信到 13800138000' },
    { timestamp: '2024-03-15T10:31:05Z', action: 'read_contacts', details: '读取联系人列表' },
  ],
  file_operations: [
    { timestamp: '2024-03-15T10:30:30Z', path: '/data/storage/el2/database', operation: 'read' },
  ],
  network_requests: [
    { timestamp: '2024-03-15T10:32:00Z', url: 'https://suspicious-domain.com/api/collect', method: 'POST' },
  ],
};

export const mockTrafficReport: TrafficReport = {
  domains: ['suspicious-domain.com', 'tracker.example.com'],
  endpoints: ['/api/collect', '/api/report'],
  protocols: ['https', 'http'],
  suspicious_activity: [
    '向未知域名发送数据',
    '使用非标准端口通信',
  ],
};
```

**Step 3: 运行测试验证**

```bash
npm run build
```

**Step 4: Commit**

```bash
git add src/mcp/sample-store/
git commit -m "feat: add sample-store data models and mock data"
```

---

### Task 1.4: 实现 sample-store 工具逻辑

**Files:**
- Modify: `src/mcp/sample-store/server.ts`

**Step 1: 更新 server.ts 实现工具逻辑**

```typescript
import { Server } from '@modelcontextprotocol/sdk/server/index.js';
import { StdioServerTransport } from '@modelcontextprotocol/sdk/server/stdio.js';
import {
  CallToolRequestSchema,
  ListToolsRequestSchema,
} from '@modelcontextprotocol/sdk/types.js';
import {
  mockSampleInfo,
  mockCodeTree,
  mockStaticReport,
  mockDynamicReport,
  mockTrafficReport,
} from './data/mock-data.js';

export class SampleStoreServer {
  private server: Server;

  constructor() {
    this.server = new Server(
      {
        name: 'sample-store',
        version: '0.1.0',
      },
      {
        capabilities: {
          tools: {},
        },
      }
    );

    this.setupHandlers();
  }

  private setupHandlers() {
    this.server.setRequestHandler(ListToolsRequestSchema, async () => {
      return {
        tools: [
          {
            name: 'get_sample_info',
            description: '根据任务ID获取样本基本信息（包名、版本、签名等）',
            inputSchema: {
              type: 'object',
              properties: {
                task_id: {
                  type: 'string',
                  description: '任务ID',
                },
              },
              required: ['task_id'],
            },
          },
          {
            name: 'get_code_tree',
            description: '获取逆向JS代码的目录树结构',
            inputSchema: {
              type: 'object',
              properties: {
                task_id: {
                  type: 'string',
                  description: '任务ID',
                },
              },
              required: ['task_id'],
            },
          },
          {
            name: 'get_code_file',
            description: '读取指定代码文件内容',
            inputSchema: {
              type: 'object',
              properties: {
                task_id: {
                  type: 'string',
                  description: '任务ID',
                },
                file_path: {
                  type: 'string',
                  description: '文件相对路径',
                },
              },
              required: ['task_id', 'file_path'],
            },
          },
          {
            name: 'get_static_report',
            description: '获取静态扫描报告',
            inputSchema: {
              type: 'object',
              properties: {
                task_id: {
                  type: 'string',
                  description: '任务ID',
                },
              },
              required: ['task_id'],
            },
          },
          {
            name: 'get_dynamic_report',
            description: '获取动态沙箱报告',
            inputSchema: {
              type: 'object',
              properties: {
                task_id: {
                  type: 'string',
                  description: '任务ID',
                },
              },
              required: ['task_id'],
            },
          },
          {
            name: 'get_traffic_report',
            description: '获取流量分析报告',
            inputSchema: {
              type: 'object',
              properties: {
                task_id: {
                  type: 'string',
                  description: '任务ID',
                },
              },
              required: ['task_id'],
            },
          },
        ],
      };
    });

    this.server.setRequestHandler(CallToolRequestSchema, async (request) => {
      const { name, arguments: args } = request.params;

      try {
        switch (name) {
          case 'get_sample_info':
            return await this.getSampleInfo(args.task_id as string);
          case 'get_code_tree':
            return await this.getCodeTree(args.task_id as string);
          case 'get_code_file':
            return await this.getCodeFile(
              args.task_id as string,
              args.file_path as string
            );
          case 'get_static_report':
            return await this.getStaticReport(args.task_id as string);
          case 'get_dynamic_report':
            return await this.getDynamicReport(args.task_id as string);
          case 'get_traffic_report':
            return await this.getTrafficReport(args.task_id as string);
          default:
            throw new Error(`Unknown tool: ${name}`);
        }
      } catch (error) {
        return {
          content: [
            {
              type: 'text',
              text: `Error: ${error instanceof Error ? error.message : String(error)}`,
            },
          ],
          isError: true,
        };
      }
    });
  }

  async getSampleInfo(taskId: string) {
    // TODO: 从实际数据源获取，目前返回 mock 数据
    const info = mockSampleInfo;
    info.task_id = taskId;

    return {
      content: [
        {
          type: 'text',
          text: JSON.stringify(info, null, 2),
        },
      ],
    };
  }

  async getCodeTree(taskId: string) {
    // TODO: 从实际数据源获取
    return {
      content: [
        {
          type: 'text',
          text: JSON.stringify(mockCodeTree, null, 2),
        },
      ],
    };
  }

  async getCodeFile(taskId: string, filePath: string) {
    // TODO: 从实际文件系统读取
    const mockFileContent = `// Mock file content for ${filePath}
// This is a placeholder for actual file content

export function exampleFunction() {
  console.log('Example from ${filePath}');
  return 'result';
}
`;

    return {
      content: [
        {
          type: 'text',
          text: mockFileContent,
        },
      ],
    };
  }

  async getStaticReport(taskId: string) {
    return {
      content: [
        {
          type: 'text',
          text: JSON.stringify(mockStaticReport, null, 2),
        },
      ],
    };
  }

  async getDynamicReport(taskId: string) {
    return {
      content: [
        {
          type: 'text',
          text: JSON.stringify(mockDynamicReport, null, 2),
        },
      ],
    };
  }

  async getTrafficReport(taskId: string) {
    return {
      content: [
        {
          type: 'text',
          text: JSON.stringify(mockTrafficReport, null, 2),
        },
      ],
    };
  }

  async start() {
    const transport = new StdioServerTransport();
    await this.server.connect(transport);
    console.error('Sample Store MCP Server running on stdio');
  }
}
```

**Step 2: 构建**

```bash
npm run build
```

**Step 3: Commit**

```bash
git add src/mcp/sample-store/server.ts
git commit -m "feat: implement sample-store MCP tools"
```

---

### Task 1.5: 创建 harmony-sample-fetcher Skill

**Files:**
- Create: `skills/harmony-sample-fetcher.skill`

**Step 1: 创建 Skill 文件**

```
---
name: harmony-sample-fetcher
description: 根据任务ID获取鸿蒙应用样本的全部信息，包括样本元数据、代码结构、机检报告等
---

# Harmony Sample Fetcher

根据任务ID获取鸿蒙应用样本的全部信息。

## 触发条件

当用户提供任务ID（如 "分析任务 TASK-001"）时使用此技能。

## 使用流程

1. **提取任务ID**: 从用户输入中提取任务ID
2. **获取样本信息**: 调用 sample-store MCP 的 get_sample_info
3. **获取代码结构**: 调用 sample-store MCP 的 get_code_tree
4. **获取静态报告**: 调用 sample-store MCP 的 get_static_report
5. **获取动态报告**: 调用 sample-store MCP 的 get_dynamic_report
6. **获取流量报告**: 调用 sample-store MCP 的 get_traffic_report
7. **汇总信息**: 将所有信息整理成结构化摘要

## MCP 工具依赖

- `sample-store/get_sample_info`
- `sample-store/get_code_tree`
- `sample-store/get_code_file`
- `sample-store/get_static_report`
- `sample-store/get_dynamic_report`
- `sample-store/get_traffic_report`

## 输出格式

```markdown
## 样本信息

**任务ID**: {task_id}
**包名**: {package_name}
**版本**: {version}
**签名**: {signature}

## 代码结构

{code_tree_summary}

## 机检报告摘要

### 静态报告
- 权限: {permissions_count} 项
- 敏感API: {apis_count} 个
- 风险项: {risks_count} 个

### 动态报告
- 行为记录: {behaviors_count} 条
- 文件操作: {file_ops_count} 次
- 网络请求: {network_reqs_count} 次

### 流量报告
- 域名: {domains_count} 个
- 可疑活动: {suspicious_count} 条
```

## 示例

**用户输入**: "分析任务 TASK-001"

**执行流程**:
1. 调用 get_sample_info("TASK-001")
2. 调用 get_code_tree("TASK-001")
3. 调用 get_static_report("TASK-001")
4. 调用 get_dynamic_report("TASK-001")
5. 调用 get_traffic_report("TASK-001")
6. 汇总输出样本信息摘要
```

**Step 2: Commit**

```bash
git add skills/harmony-sample-fetcher.skill
git commit -m "feat: add harmony-sample-fetcher skill"
```

---

## Phase 2: 报告解读

### Task 2.1: 创建 harmony-report-reader Skill

**Files:**
- Create: `skills/harmony-report-reader.skill`

**Step 1: 创建 Skill 文件**

```
---
name: harmony-report-reader
description: 解读鸿蒙应用机检报告（静态、动态、流量），提取关键风险信息
---

# Harmony Report Reader

解读鸿蒙应用机检报告，提取关键风险信息。

## 触发条件

当需要分析静态报告、动态报告或流量报告时使用此技能。

## 分析能力

### 静态报告分析
- 权限申请合理性判断
- 敏感API使用识别
- 组件安全评估
- 签名信息验证

### 动态报告分析
- 恶意行为识别
- 敏感操作检测
- 异常行为发现

### 流量报告分析
- 可疑域名识别
- 异常通信检测
- 数据外泄风险评估

## MCP 工具依赖

- `sample-store/get_static_report`
- `sample-store/get_dynamic_report`
- `sample-store/get_traffic_report`

## 输出格式

```markdown
## 报告解读结果

### 静态报告解读

**权限分析**:
- 高危权限: {high_risk_permissions}
- 中危权限: {medium_risk_permissions}

**API风险**:
- {risk_api_1}: {risk_description}
- {risk_api_2}: {risk_description}

### 动态报告解读

**恶意行为**:
- {behavior_1}: {details}
- {behavior_2}: {details}

### 流量报告解读

**可疑域名**:
- {domain_1}: {reason}
- {domain_2}: {reason}
```
```

**Step 2: Commit**

```bash
git add skills/harmony-report-reader.skill
git commit -m "feat: add harmony-report-reader skill"
```

---

## Phase 3: 代码分析

### Task 3.1: 创建 harmony-code-analyzer Skill

**Files:**
- Create: `skills/harmony-code-analyzer.skill`

**Step 1: 创建 Skill 文件**

```
---
name: harmony-code-analyzer
description: 分析鸿蒙应用逆向后的JS代码，识别风险模式和可疑代码逻辑
---

# Harmony Code Analyzer

分析鸿蒙应用逆向后的JS代码，识别风险模式和可疑代码逻辑。

## 触发条件

当需要分析应用代码时使用此技能。

## 分析能力

### 敏感API调用检测
- @ohos.telephony.sms - 短信相关API
- @ohos.contacts - 联系人API
- @ohos.net.http - 网络请求API
- @ohos.data.fileIo - 文件操作API

### 可疑代码模式
- 动态代码执行
- 反射调用
- 加密/解密操作
- Base64编码内容
- 硬编码密钥/URL

### 数据泄露风险
- 敏感信息日志输出
- 未加密的网络传输
- 明文存储敏感数据

## MCP 工具依赖

- `sample-store/get_code_tree`
- `sample-store/get_code_file`

## 分析流程

1. 获取代码目录树
2. 遍历关键文件（按扩展名 .ets, .ts, .js）
3. 对每个文件进行模式匹配
4. 汇总风险点

## 输出格式

```markdown
## 代码分析结果

### 敏感API调用

| API | 文件 | 行号 | 上下文 |
|-----|------|------|--------|
| @ohos.telephony.sms | EntryAbility.ets | 45 | sendSMS() |
| @ohos.net.http | NetworkUtil.ets | 23 | httpRequest() |

### 可疑代码模式

| 类型 | 文件 | 位置 | 描述 |
|------|------|------|------|
| 硬编码URL | Config.ets | 12 | https://suspicious-domain.com |
| Base64编码 | CryptoUtil.ets | 56 | 可能混淆恶意代码 |

### 风险评估

**高风险**: {high_risk_count} 个
**中风险**: {medium_risk_count} 个
**低风险**: {low_risk_count} 个
```
```

**Step 2: Commit**

```bash
git add skills/harmony-code-analyzer.skill
git commit -m "feat: add harmony-code-analyzer skill"
```

---

## Phase 4: 风险判定

### Task 4.1: 创建 knowledge-base MCP Server 框架

**Files:**
- Create: `src/mcp/knowledge-base/index.ts`
- Create: `src/mcp/knowledge-base/server.ts`
- Create: `src/mcp/knowledge-base/data/hatl-mock.json`

**Step 1: 创建 server.ts**

```typescript
import { Server } from '@modelcontextprotocol/sdk/server/index.js';
import { StdioServerTransport } from '@modelcontextprotocol/sdk/server/stdio.js';
import {
  CallToolRequestSchema,
  ListToolsRequestSchema,
} from '@modelcontextprotocol/sdk/types.js';
import { readFileSync } from 'fs';
import { join } from 'path';

export class KnowledgeBaseServer {
  private server: Server;
  private hatlData: any;

  constructor() {
    this.server = new Server(
      {
        name: 'knowledge-base',
        version: '0.1.0',
      },
      {
        capabilities: {
          tools: {},
        },
      }
    );

    this.loadHATLData();
    this.setupHandlers();
  }

  private loadHATLData() {
    // TODO: 从实际文件加载，目前使用 mock 数据
    this.hatlData = {
      techniques: [
        {
          id: 'T001',
          name: '短信发送',
          category: '信息窃取',
          description: '未经用户同意发送短信',
          indicators: ['@ohos.telephony.sms'],
        },
        {
          id: 'T002',
          name: '联系人窃取',
          category: '信息窃取',
          description: '读取用户联系人信息',
          indicators: ['@ohos.contacts'],
        },
      ],
    };
  }

  private setupHandlers() {
    this.server.setRequestHandler(ListToolsRequestSchema, async () => {
      return {
        tools: [
          {
            name: 'query_hatl',
            description: '查询HATL攻击技术知识库',
            inputSchema: {
              type: 'object',
              properties: {
                query: {
                  type: 'string',
                  description: '搜索关键词',
                },
                category: {
                  type: 'string',
                  description: '技术分类（可选）',
                },
              },
            },
          },
        ],
      };
    });

    this.server.setRequestHandler(CallToolRequestSchema, async (request) => {
      const { name, arguments: args } = request.params;

      if (name === 'query_hatl') {
        return await this.queryHATL(args.query as string, args.category as string);
      }

      throw new Error(`Unknown tool: ${name}`);
    });
  }

  async queryHATL(query: string, category?: string) {
    // TODO: 实现实际查询逻辑
    const results = this.hatlData.techniques.filter((t: any) =>
      t.name.includes(query) || t.description.includes(query)
    );

    return {
      content: [
        {
          type: 'text',
          text: JSON.stringify(results, null, 2),
        },
      ],
    };
  }

  async start() {
    const transport = new StdioServerTransport();
    await this.server.connect(transport);
    console.error('Knowledge Base MCP Server running on stdio');
  }
}
```

**Step 2: 创建 index.ts**

```typescript
import { KnowledgeBaseServer } from './server.js';

const server = new KnowledgeBaseServer();
server.start().catch(console.error);
```

**Step 3: 创建 HATL mock 数据**

```json
{
  "techniques": [
    {
      "id": "T001",
      "name": "短信发送",
      "tactic": "信息窃取",
      "description": "未经用户同意发送短信",
      "indicators": [
        "@ohos.telephony.sms.sendSms",
        "sms.sendSms"
      ],
      "severity": "high"
    },
    {
      "id": "T002",
      "name": "联系人窃取",
      "tactic": "信息窃取",
      "description": "读取用户联系人信息",
      "indicators": [
        "@ohos.contacts.getContact",
        "contact.queryContact"
      ],
      "severity": "high"
    },
    {
      "id": "T003",
      "name": "位置追踪",
      "tactic": " surveillance",
      "description": "持续获取用户位置信息",
      "indicators": [
        "@ohos.geoLocationManager.getLocation",
        "geolocation.getLocation"
      ],
      "severity": "medium"
    }
  ]
}
```

**Step 4: 构建**

```bash
npm run build
```

**Step 5: Commit**

```bash
git add src/mcp/knowledge-base/
git commit -m "feat: add knowledge-base MCP server framework"
```

---

### Task 4.2: 创建 harmony-malware-detector Skill

**Files:**
- Create: `skills/harmony-malware-detector.skill`

**Step 1: 创建 Skill 文件**

```
---
name: harmony-malware-detector
description: 恶意行为识别，基于HATL知识库判定应用是否为恶意软件
---

# Harmony Malware Detector

基于HATL知识库进行恶意行为识别和恶意软件判定。

## 触发条件

当需要判定应用是否为恶意时使用此技能。

## 判定流程

1. 收集代码分析结果
2. 收集报告解读结果
3. 查询 HATL 知识库匹配攻击模式
4. 综合判定恶意结论

## MCP 工具依赖

- `knowledge-base/query_hatl`

## 判定标准

| 结论 | 条件 |
|------|------|
| **恶意 (Malicious)** | 匹配2个以上高危攻击技术 |
| **可疑 (Suspicious)** | 匹配1个高危或2个以上中危攻击技术 |
| **良性 (Benign)** | 无匹配或仅低危技术 |

## 输出格式

```markdown
## 恶意判定结论

**判定结果**: {Malicious | Suspicious | Benign}
**置信度**: {High | Medium | Low}
**判定时间**: {timestamp}

### 匹配的攻击技术

| 技术ID | 名称 | 类别 | 严重度 | 证据 |
|--------|------|------|--------|------|
| T001 | 短信发送 | 信息窃取 | High | EntryAbility.ets:45 |
| T002 | 联系人窃取 | 信息窃取 | High | DataManager.ets:23 |

### 判定依据

{detailed_reasoning}

### 建议

{actionable_recommendations}
```
```

**Step 2: Commit**

```bash
git add skills/harmony-malware-detector.skill
git commit -m "feat: add harmony-malware-detector skill"
```

---

### Task 4.3: 创建 harmony-permission-analyzer Skill

**Files:**
- Create: `skills/harmony-permission-analyzer.skill`

**Step 1: 创建 Skill 文件**

```
---
name: harmony-permission-analyzer
description: 权限滥用检测，分析应用申请的权限是否合理
---

# Harmony Permission Analyzer

分析应用申请的权限是否合理，检测权限滥用行为。

## 触发条件

当需要分析应用权限时使用此技能。

## 分析能力

### 权限分类
- **高危权限**: 短信、联系人、位置、通话记录等
- **中危权限**: 存储、相机、麦克风等
- **低危权限**: 网络、振动等

### 合理性判断
- 功能与权限匹配
- 权限使用场景合理
- 无过度申请

## 输出格式

```markdown
## 权限分析结果

### 权限申请清单

| 权限 | 风险等级 | 使用位置 | 合理性 |
|------|----------|----------|--------|
| ohos.permission.READ_SMS | High | EntryAbility.ets:45 | ❌ 不合理 |
| ohos.permission.INTERNET | Low | NetworkUtil.ets:12 | ✅ 合理 |

### 权限风险评估

**高危权限**: {count} 项
**中危权限**: {count} 项
**低危权限**: {count} 项

**总体评级**: {Risk | Caution | Safe}
```
```

**Step 2: Commit**

```bash
git add skills/harmony-permission-analyzer.skill
git commit -m "feat: add harmony-permission-analyzer skill"
```

---

### Task 4.4: 创建 harmony-sdk-analyzer Skill

**Files:**
- Create: `skills/harmony-sdk-analyzer.skill`

**Step 1: 创建 Skill 文件**

```
---
name: harmony-sdk-analyzer
description: 第三方SDK/组件识别与分析，评估SDK安全风险
---

# Harmony SDK Analyzer

识别应用中的第三方SDK和组件，评估其安全风险。

## 触发条件

当需要分析第三方组件时使用此技能。

## 分析能力

### SDK 识别
- 通过包名识别
- 通过类名识别
- 通过域名识别

### 风险评估
- 已知恶意SDK
- 广告SDK
- 统计SDK
- 热修复SDK

## 常见SDK库

| SDK | 包名/特征 | 风险等级 |
|-----|----------|---------|
| 穿山甲 | com.bytedance | Medium |
| 友盟 | com.umeng | Low |
| 热云 | com.reyun | Low |

## 输出格式

```markdown
## 第三方组件分析

### 识别到的SDK

| SDK名称 | 版本 | 风险等级 | 用途 |
|---------|------|----------|------|
| 穿山甲 | 4.0.0 | Medium | 广告 |
| 友盟 | 9.0.0 | Low | 统计 |

### 风险提示

{risk_warnings}

### 建议

{recommendations}
```
```

**Step 2: Commit**

```bash
git add skills/harmony-sdk-analyzer.skill
git commit -m "feat: add harmony-sdk-analyzer skill"
```

---

## Phase 5: 报告生成

### Task 5.1: 创建 report-store MCP Server

**Files:**
- Create: `src/mcp/report-store/index.ts`
- Create: `src/mcp/report-store/server.ts`

**Step 1: 创建 server.ts**

```typescript
import { Server } from '@modelcontextprotocol/sdk/server/index.js';
import { StdioServerTransport } from '@modelcontextprotocol/sdk/server/stdio.js';
import {
  CallToolRequestSchema,
  ListToolsRequestSchema,
} from '@modelcontextprotocol/sdk/types.js';
import { writeFileSync, mkdirSync } from 'fs';
import { join } from 'path';

export class ReportStoreServer {
  private server: Server;
  private reportPath: string;

  constructor() {
    this.server = new Server(
      {
        name: 'report-store',
        version: '0.1.0',
      },
      {
        capabilities: {
          tools: {},
        },
      }
    );

    this.reportPath = process.env.REPORT_OUTPUT_PATH || './data/reports';
    this.setupHandlers();
  }

  private setupHandlers() {
    this.server.setRequestHandler(ListToolsRequestSchema, async () => {
      return {
        tools: [
          {
            name: 'save_report',
            description: '保存分析报告',
            inputSchema: {
              type: 'object',
              properties: {
                task_id: {
                  type: 'string',
                  description: '任务ID',
                },
                report_content: {
                  type: 'string',
                  description: '报告内容（Markdown格式）',
                },
              },
              required: ['task_id', 'report_content'],
            },
          },
          {
            name: 'get_report',
            description: '获取历史报告',
            inputSchema: {
              type: 'object',
              properties: {
                task_id: {
                  type: 'string',
                  description: '任务ID',
                },
              },
              required: ['task_id'],
            },
          },
        ],
      };
    });

    this.server.setRequestHandler(CallToolRequestSchema, async (request) => {
      const { name, arguments: args } = request.params;

      if (name === 'save_report') {
        return await this.saveReport(args.task_id as string, args.report_content as string);
      }

      if (name === 'get_report') {
        return await this.getReport(args.task_id as string);
      }

      throw new Error(`Unknown tool: ${name}`);
    });
  }

  async saveReport(taskId: string, content: string) {
    try {
      // 确保目录存在
      mkdirSync(this.reportPath, { recursive: true });

      // 写入报告
      const filename = `${taskId}_${Date.now()}.md`;
      const filepath = join(this.reportPath, filename);
      writeFileSync(filepath, content, 'utf-8');

      return {
        content: [
          {
            type: 'text',
            text: `Report saved to: ${filepath}`,
          },
        ],
      };
    } catch (error) {
      return {
        content: [
          {
            type: 'text',
            text: `Error saving report: ${error instanceof Error ? error.message : String(error)}`,
          },
        ],
        isError: true,
      };
    }
  }

  async getReport(taskId: string) {
    // TODO: 实现读取历史报告
    return {
      content: [
        {
          type: 'text',
          text: `Report for ${taskId}: Not implemented yet`,
        },
      ],
    };
  }

  async start() {
    const transport = new StdioServerTransport();
    await this.server.connect(transport);
    console.error('Report Store MCP Server running on stdio');
  }
}
```

**Step 2: 创建 index.ts**

```typescript
import { ReportStoreServer } from './server.js';

const server = new ReportStoreServer();
server.start().catch(console.error);
```

**Step 3: 构建**

```bash
npm run build
```

**Step 4: Commit**

```bash
git add src/mcp/report-store/
git commit -m "feat: add report-store MCP server"
```

---

### Task 5.2: 创建 harmony-report-generator Skill

**Files:**
- Create: `skills/harmony-report-generator.skill`

**Step 1: 创建 Skill 文件**

```
---
name: harmony-report-generator
description: 生成鸿蒙应用安全分析报告，汇总所有分析结果
---

# Harmony Report Generator

生成鸿蒙应用安全分析报告，汇总所有分析结果。

## 触发条件

当所有分析完成后，需要生成最终报告时使用此技能。

## 报告结构

```markdown
# 鸿蒙应用安全分析报告

## 基本信息
| 字段 | 值 |
|------|-----|
| 任务ID | {task_id} |
| 包名 | {package_name} |
| 版本 | {version} |
| 签名信息 | {signature} |
| 分析时间 | {analysis_time} |

## 恶意结论
**判定结果**: {malicious | suspicious | benign}
**置信度**: {high | medium | low}

## 风险摘要
| 风险类别 | 风险等级 | 简述 |
|----------|----------|------|
| 恶意行为 | {level} | {summary} |
| 权限滥用 | {level} | {summary} |
| 第三方SDK | {level} | {summary} |

## 详细发现

### 1. 恶意行为分析
{malware_findings}

### 2. 权限分析
{permission_findings}

### 3. 第三方组件分析
{sdk_findings}

### 4. 代码风险点
{code_findings}

### 5. 网络行为分析
{traffic_findings}

## 存疑点清单
| 序号 | 存疑点描述 | 建议人工分析方向 |
|------|-----------|-----------------|
| 1 | {doubt_1} | {suggestion_1} |
| 2 | {doubt_2} | {suggestion_2} |

## 附录
- 静态报告摘要
- 动态报告摘要
- 流量报告摘要
```

## MCP 工具依赖

- `report-store/save_report`
```

**Step 2: Commit**

```bash
git add skills/harmony-report-generator.skill
git commit -m "feat: add harmony-report-generator skill"
```

---

## Phase 6: OpenClaw Plugin 集成

### Task 6.1: 创建 OpenClaw Plugin

**Files:**
- Create: `plugins/openclaw-harmony-security/index.js`
- Create: `plugins/openclaw-harmony-security/package.json`

**Step 1: 创建 package.json**

```json
{
  "name": "openclaw-harmony-security",
  "version": "0.1.0",
  "description": "鸿蒙应用安全分析 OpenClaw Plugin",
  "main": "index.js",
  "dependencies": {
    "@modelcontextprotocol/sdk": "^1.0.4"
  }
}
```

**Step 2: 创建 plugin/index.js**

```javascript
// plugins/openclaw-harmony-security/index.js
const fs = require('fs');
const path = require('path');

class HarmonySecurityPlugin {
  constructor(config, gateway) {
    this.config = config;
    this.gateway = gateway;
    this.activeSessions = new Map();
  }

  async beforeAgentStart(context) {
    const { userPrompt, sessionId, workspaceDir } = context;

    // 检测是否是分析任务（如用户输入任务ID）
    const taskId = this.extractTaskId(userPrompt);
    if (taskId) {
      // 将样本信息注入到上下文
      const contextContent = `## 当前分析任务\n\n**任务ID**: ${taskId}\n\n你可以使用以下 MCP 工具获取样本信息：\n- sample-store/get_sample_info\n- sample-store/get_code_tree\n- sample-store/get_static_report\n- sample-store/get_dynamic_report\n- sample-store/get_traffic_report\n`;

      const contextPath = path.join(workspaceDir, 'TASK_CONTEXT.md');
      fs.writeFileSync(contextPath, contextContent);

      console.log(`[${this.constructor.name}] Injected task context for ${taskId}`);
    }
  }

  async toolResultPersist(context) {
    const { toolName, result, sessionId } = context;

    // 记录分析工具的调用结果
    if (toolName.startsWith('harmony_') || toolName.includes('sample')) {
      const sessionData = this.activeSessions.get(sessionId) || { findings: [] };
      sessionData.findings.push({ tool: toolName, result, timestamp: Date.now() });
      this.activeSessions.set(sessionId, sessionData);
    }
  }

  async agentEnd(context) {
    const { sessionId, lastMessage } = context;

    // 汇总分析结果
    const sessionData = this.activeSessions.get(sessionId);
    if (sessionData && sessionData.findings.length > 0) {
      console.log(`[${this.constructor.name}] Session ${sessionId} completed with ${sessionData.findings.length} findings`);
    }

    this.activeSessions.delete(sessionId);
  }

  async gatewayStart() {
    console.log(`[${this.constructor.name}] Plugin initialized`);
    console.log(`[${this.constructor.name}] Config:`, JSON.stringify(this.config, null, 2));
  }

  extractTaskId(prompt) {
    const match = prompt.match(/(?:任务ID|task.?id)[:\s]+([A-Z0-9-]+)/i);
    return match ? match[1] : null;
  }
}

module.exports = HarmonySecurityPlugin;
```

**Step 3: Commit**

```bash
git add plugins/openclaw-harmony-security/
git commit -m "feat: add OpenClaw harmony-security plugin"
```

---

### Task 6.2: 创建配置文件和启动脚本

**Files:**
- Create: `openclaw.config.json`
- Create: `scripts/start-mcp-servers.sh`

**Step 1: 创建 OpenClaw 配置**

```json
{
  "gateway": {
    "port": 8080
  },
  "plugins": {
    "harmony-security": {
      "enabled": true,
      "config": {
        "sampleStorePath": "./data/samples",
        "knowledgeBasePath": "./data/knowledge",
        "reportOutputPath": "./data/reports"
      }
    }
  },
  "mcpServers": {
    "sample-store": {
      "command": "node",
      "args": ["dist/mcp/sample-store/index.js"]
    },
    "knowledge-base": {
      "command": "node",
      "args": ["dist/mcp/knowledge-base/index.js"]
    },
    "report-store": {
      "command": "node",
      "args": ["dist/mcp/report-store/index.js"]
    }
  }
}
```

**Step 2: 创建启动脚本**

```bash
#!/bin/bash

# 鸿蒙应用安全分析系统 - MCP Servers 启动脚本

echo "Starting Harmony Security Analysis MCP Servers..."

# 启动 sample-store
echo "Starting sample-store MCP Server..."
npm run mcp:sample-store &
SAMPLE_STORE_PID=$!

# 启动 knowledge-base
echo "Starting knowledge-base MCP Server..."
node dist/mcp/knowledge-base/index.js &
KNOWLEDGE_BASE_PID=$!

# 启动 report-store
echo "Starting report-store MCP Server..."
node dist/mcp/report-store/index.js &
REPORT_STORE_PID=$!

echo "All MCP Servers started!"
echo "PIDs: sample-store=$SAMPLE_STORE_PID, knowledge-base=$KNOWLEDGE_BASE_PID, report-store=$REPORT_STORE_PID"

# 保存 PID
echo $SAMPLE_STORE_PID > .pids/sample-store.pid
echo $KNOWLEDGE_BASE_PID > .pids/knowledge-base.pid
echo $REPORT_STORE_PID > .pids/report-store.pid

echo "Press Ctrl+C to stop all servers"

# 等待信号
wait
```

**Step 3: 创建停止脚本**

```bash
#!/bin/bash

# 停止所有 MCP Servers

echo "Stopping MCP Servers..."

if [ -f .pids/sample-store.pid ]; then
  kill $(cat .pids/sample-store.pid) 2>/dev/null
  rm .pids/sample-store.pid
fi

if [ -f .pids/knowledge-base.pid ]; then
  kill $(cat .pids/knowledge-base.pid) 2>/dev/null
  rm .pids/knowledge-base.pid
fi

if [ -f .pids/report-store.pid ]; then
  kill $(cat .pids/report-store.pid) 2>/dev/null
  rm .pids/report-store.pid
fi

echo "All MCP Servers stopped"
```

**Step 4: 创建 .pids 目录**

```bash
mkdir -p .pids
```

**Step 5: Commit**

```bash
git add openclaw.config.json scripts/ .pids/
git commit -m "feat: add OpenClaw config and MCP server startup scripts"
```

---

### Task 6.3: 创建测试用例

**Files:**
- Create: `tests/integration/analysis-flow.test.ts`

**Step 1: 创建集成测试**

```typescript
// tests/integration/analysis-flow.test.ts
import { describe, it, expect } from 'vitest';

describe('Harmony Security Analysis Flow', () => {
  it('should complete full analysis flow', async () => {
    // 这是一个示例集成测试框架
    // 实际测试需要 MCP Servers 运行

    const taskId = 'TEST-001';

    // 1. 获取样本信息
    const sampleInfo = await getSampleInfo(taskId);
    expect(sampleInfo).toBeDefined();

    // 2. 获取代码树
    const codeTree = await getCodeTree(taskId);
    expect(codeTree).toBeDefined();

    // 3. 获取报告
    const staticReport = await getStaticReport(taskId);
    const dynamicReport = await getDynamicReport(taskId);
    const trafficReport = await getTrafficReport(taskId);

    // 4. 生成分析报告
    const report = await generateReport({
      sampleInfo,
      codeTree,
      staticReport,
      dynamicReport,
      trafficReport,
    });

    expect(report).toContain('# 鸿蒙应用安全分析报告');
  });
});

// 辅助函数（实际实现需要调用 MCP）
async function getSampleInfo(taskId: string) {
  // TODO: 实现 MCP 调用
  return {};
}

async function getCodeTree(taskId: string) {
  // TODO: 实现 MCP 调用
  return {};
}

async function getStaticReport(taskId: string) {
  // TODO: 实现 MCP 调用
  return {};
}

async function getDynamicReport(taskId: string) {
  // TODO: 实现 MCP 调用
  return {};
}

async function getTrafficReport(taskId: string) {
  // TODO: 实现 MCP 调用
  return {};
}

async function generateReport(data: any) {
  // TODO: 实现报告生成
  return '# Test Report';
}
```

**Step 2: Commit**

```bash
git add tests/integration/
git commit -m "test: add integration test framework"
```

---

## 总结

### 构建完成清单

- [x] Phase 1: 基础设施
  - [x] 项目结构
  - [x] sample-store MCP Server
  - [x] harmony-sample-fetcher Skill
- [x] Phase 2: 报告解读
  - [x] harmony-report-reader Skill
- [x] Phase 3: 代码分析
  - [x] harmony-code-analyzer Skill
- [x] Phase 4: 风险判定
  - [x] knowledge-base MCP Server
  - [x] harmony-malware-detector Skill
  - [x] harmony-permission-analyzer Skill
  - [x] harmony-sdk-analyzer Skill
- [x] Phase 5: 报告生成
  - [x] report-store MCP Server
  - [x] harmony-report-generator Skill
- [x] Phase 6: OpenClaw Plugin 集成
  - [x] Plugin 代码
  - [x] 配置文件
  - [x] 启动/停止脚本
  - [x] 集成测试框架

### 下一步

1. **安装依赖**
```bash
npm install
```

2. **构建项目**
```bash
npm run build
```

3. **配置环境变量**
```bash
cp .env.example .env
# 编辑 .env 文件设置实际配置
```

4. **启动 MCP Servers**
```bash
bash scripts/start-mcp-servers.sh
```

5. **注册 Skills**
```bash
# 将 skills/ 目录下的 .skill 文件复制到 Claude Skills 目录
cp skills/*.skill ~/.claude/skills/
```

6. **配置 OpenClaw Gateway**
```bash
# 将 openclaw.config.json 合并到你的 OpenClaw Gateway 配置
```

7. **测试系统**
```bash
npm run test
```

---

**计划完成！所有组件框架已创建，可以开始具体实现了。**

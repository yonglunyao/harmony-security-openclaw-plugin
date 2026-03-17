# 鸿蒙应用安全分析 Agent 系统设计方案

> 创建日期: 2026-03-17
> 状态: 待实现

## 1. 项目概述

### 1.1 目标

构建一个基于 Agent + 大模型的鸿蒙应用安全分析辅助系统，实现从传统人工分析向 **Agent助理+人工分析** 模式的转变。

### 1.2 核心理念

- Agent 先行分析，给出初步报告
- 人工审核确认，针对存疑点深入分析
- 通过对话与 Agent 交流澄清
- Agent 难以分析的部分由人工深入

### 1.3 设计约束

| 约束项 | 描述 |
|--------|------|
| 样本格式 | HAP 安装包文件 |
| 输入数据 | 静态扫描、动态沙箱、流量记录、逆向JS代码(目录树) |
| 分析重点 | 恶意行为识别、权限滥用检测、第三方组件分析 |
| 产出格式 | Markdown 格式的安全分析报告 |
| 效率目标 | 简单样本 <30分钟，复杂样本 <2小时 |

## 2. 系统架构

### 2.1 整体架构

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
│  │  ┌────────────┐ ┌────────────┐ ┌────────────┐ ┌────────────┐   │   │
│  │  │ 任务调度器  │ │ 分析编排器  │ │ 报告生成器  │ │ 记忆管理器  │   │   │
│  │  └────────────┘ └────────────┘ └────────────┘ └────────────┘   │   │
│  └─────────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────────┘
                            │
          ┌─────────────────┼─────────────────┐
          ▼                 ▼                 ▼
┌──────────────────┐ ┌──────────────────┐ ┌──────────────────┐
│    Skills 层     │ │    MCP Tools     │ │    知识库层       │
│ ┌──────────────┐ │ │ ┌──────────────┐ │ │ ┌──────────────┐ │
│ │ HATL Query   │ │ │ │ 样本获取     │ │ │ │ 历史案例库   │ │
│ │ Code Review  │ │ │ │ 报告获取     │ │ │ │ 官方文档     │ │
│ │ 分析技能...   │ │ │ │ 流量分析     │ │ │ │ HATL 知识库  │ │
│ └──────────────┘ │ │ └──────────────┘ │ │ └──────────────┘ │
└──────────────────┘ └──────────────────┘ └──────────────────┘
```

### 2.2 核心设计理念

- **OpenClaw Gateway** 作为 Agent 编排中心
- **Plugin** 封装鸿蒙安全分析专用逻辑
- **Skills/MCP** 按需扩展，用户自定义构建
- **多工作台** 通过 Gateway 统一接入

## 3. Skills 构建清单

| Skill 名称 | 职责 | 输入 | 输出 | 优先级 |
|-----------|------|------|------|--------|
| **harmony-sample-fetcher** | 根据任务ID获取样本全部信息 | task_id | 样本元数据、文件路径 | P0 |
| **harmony-code-analyzer** | 分析逆向后的JS代码，识别风险模式 | 代码目录路径 | 风险点列表 | P0 |
| **harmony-report-reader** | 解读机检报告（静态/动态/流量） | 报告文件路径 | 结构化风险摘要 | P0 |
| **harmony-malware-detector** | 恶意行为识别，基于HATL知识库 | 代码+报告分析结果 | 恶意结论+证据 | P0 |
| **harmony-permission-analyzer** | 权限滥用检测 | 权限列表+代码上下文 | 权限风险评级 | P1 |
| **harmony-sdk-analyzer** | 第三方SDK/组件识别与分析 | 代码目录 | SDK清单+风险评估 | P1 |
| **harmony-report-generator** | 生成最终安全分析报告 | 所有分析结果 | Markdown报告 | P0 |

## 4. MCP Tools 构建清单

### 4.1 sample-store MCP Server

| 工具名称 | 职责 | 优先级 |
|---------|------|--------|
| `get_sample_info` | 根据task_id获取样本基本信息（包名、版本、签名等） | P0 |
| `get_code_tree` | 获取逆向JS代码的目录树结构 | P0 |
| `get_code_file` | 读取指定代码文件内容 | P0 |
| `get_static_report` | 获取静态扫描报告 | P0 |
| `get_dynamic_report` | 获取动态沙箱报告 | P0 |
| `get_traffic_report` | 获取流量分析报告 | P0 |

### 4.2 knowledge-base MCP Server

| 工具名称 | 职责 | 优先级 |
|---------|------|--------|
| `query_hatl` | 查询HATL攻击技术知识库 | P0 |
| `query_history` | 查询历史分析案例 | P1 |
| `search_docs` | 搜索鸿蒙官方文档 | P1 |

### 4.3 report-store MCP Server

| 工具名称 | 职责 | 优先级 |
|---------|------|--------|
| `save_report` | 保存分析报告 | P0 |
| `get_report` | 获取历史报告 | P1 |

## 5. 分析流程

```
Phase 1: 信息收集
├── harmony-sample-fetcher
│   ├── get_sample_info(task_id) → 样本元数据
│   ├── get_code_tree() → 代码目录树
│   ├── get_static_report() → 静态报告
│   ├── get_dynamic_report() → 动态报告
│   └── get_traffic_report() → 流量报告

Phase 2: 报告解读
└── harmony-report-reader
    ├── 解析静态报告 → 权限、API、组件清单
    ├── 解析动态报告 → 行为特征、敏感操作
    └── 解析流量报告 → 网络行为、可疑域名

Phase 3: 代码分析
└── harmony-code-analyzer
    ├── 遍历代码目录，读取关键文件
    ├── 识别敏感API调用模式
    ├── 检测可疑代码逻辑
    └── 输出风险点列表

Phase 4: 风险判定
├── harmony-malware-detector
│   ├── 查询 HATL 知识库匹配攻击模式
│   ├── 综合代码+报告发现
│   └── 输出恶意结论 + 证据链
├── harmony-permission-analyzer
│   └── 分析权限申请合理性
└── harmony-sdk-analyzer
    └── 识别第三方SDK及其风险

Phase 5: 报告生成
└── harmony-report-generator
    ├── 汇总所有分析结果
    ├── 生成风险摘要
    ├── 生成恶意结论
    ├── 整理存疑点清单
    └── 输出 Markdown 报告

Phase 6: 人工审核
└── 人工专家
    ├── 审阅 Agent 报告
    ├── 针对存疑点深入分析
    ├── 与 Agent 对话澄清
    └── 确认/修正最终结论
```

## 6. 报告模板

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

## 7. 构建顺序建议

```
Phase 1: 基础设施 (Week 1)
├── sample-store MCP Server
│   ├── get_sample_info
│   ├── get_code_tree
│   └── get_code_file
└── harmony-sample-fetcher Skill

Phase 2: 报告解读 (Week 2)
├── sample-store MCP Server (续)
│   ├── get_static_report
│   ├── get_dynamic_report
│   └── get_traffic_report
└── harmony-report-reader Skill

Phase 3: 代码分析 (Week 3)
└── harmony-code-analyzer Skill

Phase 4: 风险判定 (Week 4)
├── knowledge-base MCP Server
│   └── query_hatl (复用现有HATL)
├── harmony-malware-detector Skill
├── harmony-permission-analyzer Skill
└── harmony-sdk-analyzer Skill

Phase 5: 报告生成 (Week 5)
├── report-store MCP Server
│   └── save_report
└── harmony-report-generator Skill

Phase 6: 集成与优化 (Week 6)
├── OpenClaw Plugin 集成
├── 端到端测试
└── 人工专家验收
```

## 8. 设计总结

| 组件类型 | 数量 | 关键职责 |
|---------|------|---------|
| **Skills** | 7个 | 分析逻辑编排、代码解读、报告生成 |
| **MCP Servers** | 3个 | 数据获取、知识查询、报告存储 |
| **分析阶段** | 6个 | 收集→解读→分析→判定→生成→审核 |

### 核心设计决策

1. **解耦设计**: Skills 负责分析逻辑，MCP 负责数据访问，可独立演进
2. **按需扩展**: 知识源通过 MCP 接入，不影响核心分析流程
3. **存疑标记**: Agent 无法确定的问题输出到存疑清单，由人工深入
4. **多工作台**: 通过 OpenClaw Gateway 统一接入，支持多种交互方式

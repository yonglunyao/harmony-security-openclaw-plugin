# AI 工具使用规范

本文件为 AI 编码助手（Claude Code、Cursor、Copilot 等）提供项目文件放置指南。

## 📁 文件放置指南

### 各目录用途

| 目录 | 用途 | 示例 |
|------|------|------|
| `src/mcp/` | MCP Server 源码 | 新增 MCP Server |
| `skills/` | Skills 定义 | 新增 Skill |
| `plugins/` | 插件代码 | 已实现的插件 |
| `scripts/` | 工具脚本 | 构建或部署脚本 |
| `tests/` | 测试文件 | 单元测试、集成测试 |
| `docs/` | 项目文档 | 设计文档、API 文档 |
| `temp/` | 临时文件 | 草稿、测试输出（不被 Git 跟踪） |

### 新增文件时

**将文件放在合适的目录**：

- MCP Server → `src/mcp/<server-name>/`
- Skill → `skills/<skill-name>.skill`
- 测试 → `tests/<feature>.test.ts`
- 文档 → `docs/<topic>.md`
- 脚本 → `scripts/<name>.sh`
- 临时文件 → `temp/<filename>`

## 🛠️ 开发指南

### 新增 MCP Server

```
src/mcp/<server-name>/
├── server.ts          # 服务器实现
├── index.ts           # 入口文件
└── types.ts           # 类型定义（可选）
```

### 新增 Skill

```
skills/<skill-name>.skill
```

必须包含：name, description, 触发条件, MCP 依赖

## 📝 配置文件

配置文件修改通常需要谨慎，但在以下情况下可以修改：

- 添加新的 MCP Server 到 `openclaw.config.json`
- 更新依赖版本
- 添加新的脚本命令

## 🎯 核心原则

**合适的位置，合适的用途**

- ✅ 代码文件放在代码目录
- ✅ 文档放在文档目录
- ✅ 临时文件放在 temp/
- ✅ 遵循项目现有的模式和风格

---

**简单**: 把文件放在该放的地方，遵循现有结构。

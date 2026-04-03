# X-Ray — Claude Code 深度代码分析技能

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Claude Code](https://img.shields.io/badge/Claude_Code-Skill-blueviolet?logo=anthropic&logoColor=white)](https://claude.ai/claude-code)
[![Platform](https://img.shields.io/badge/Platform-macOS%20%7C%20Linux-lightgrey)]()

[English](README.md)

**一条命令，将任意代码库转化为结构化架构文档。**

X-Ray 运行专业代码分析工具 + AI 逐层深度阅读，生成完整的项目架构骨架 —— 模块职责、依赖图、业务调用链、类型关系等。

支持**任何语言和框架**。TypeScript/JavaScript 项目通过 madge 和 dependency-cruiser 获得增强分析。

## 功能概览

```
/xray
  → 检测项目结构
  → 运行 scc、madge、dependency-cruiser（自动安装）
  → AI 逐模块深度阅读
  → 每个分析目标生成 5 个结构化文档
  → 更新 CLAUDE.md 架构摘要
  → 支持增量分析（仅重新分析变更模块）
```

### 输出示例

运行 `/xray` 后，你会得到：

```
docs/codebase/
├── frontend/
│   ├── structure.md      # 目录结构 + 代码统计
│   ├── dependencies.md   # 模块依赖图 + 循环依赖
│   ├── modules.md        # 逐模块深度分析
│   ├── call-chains.md    # 关键业务调用链
│   └── types.md          # 核心类型/接口关系
├── backend/
│   └── ...
└── .analysis-meta.json   # 增量分析元数据
```

同时在 `CLAUDE.md` 中注入精简摘要，让 Claude 始终拥有架构上下文。

## 快速开始

### 方式一：一键安装（推荐）

```bash
curl -fsSL https://raw.githubusercontent.com/anthropics/project-xray/main/install.sh | bash
```

安装器支持选择全局安装（`~/.claude/skills/`）、项目级安装（`.claude/skills/`）或两者都安装。

### 方式二：让 Claude 帮你安装

将以下 prompt 粘贴到 Claude Code 中：

> 安装 X-Ray 代码分析技能：执行 **`curl -fsSL https://raw.githubusercontent.com/anthropics/project-xray/main/install.sh | bash`** 并选择全局安装。然后告诉我已准备就绪，我可以使用 `/xray setup` 配置项目，或直接使用 `/xray` 开始分析。

### 方式三：手动安装

```bash
# 全局安装（所有项目可用）
git clone --single-branch --depth 1 https://github.com/anthropics/project-xray.git ~/.claude/skills/xray

# 或安装到当前项目（通过 git 与团队共享）
git clone --single-branch --depth 1 https://github.com/anthropics/project-xray.git /tmp/project-xray && cp -r /tmp/project-xray/skills/xray .claude/skills/xray && rm -rf /tmp/project-xray
```

### 首次使用

```
/xray setup    # 交互式配置 —— 自动检测项目结构
/xray          # 运行分析
```

首次运行时如果没有配置，X-Ray 会自动引导你完成配置。

## 使用方式

| 命令 | 说明 |
|------|------|
| `/xray` | 自动检测增量/全量，分析所有配置目标 |
| `/xray setup` | 交互式配置 —— 设置分析目标、路径、选项 |
| `/xray [target]` | 分析指定目标（如 `/xray frontend`） |
| `/xray --full` | 强制全量分析（忽略缓存结果） |

## 工作原理

### Phase 0: 环境准备
- 读取 `.xray-config.json`（不存在则进入交互式配置）
- 自动安装 `scc`、`madge`、`dependency-cruiser`

### Phase 1: 增量检测
- 对比当前 commit 与上次分析的 commit
- 仅重新分析有变更的模块（配置文件变更触发全量分析）

### Phase 2: 工具分析（并行执行）
- **scc** —— 代码统计（行数、复杂度、语言分布）
- **tree** —— 目录结构可视化
- **madge** —— 依赖图、循环依赖、孤立文件（仅 JS/TS）
- **dependency-cruiser** —— 依赖规则校验（仅 JS/TS）

### Phase 3: AI 深度阅读（并行 Agent）
- 第一轮：模块识别与职责映射
- 第二轮：逐模块深度分析 —— 业务逻辑、调用链、类型关系

### Phase 4: 输出合成
- 每个目标 5 个结构化文档，写入 `docs/codebase/`
- 架构摘要写入 `CLAUDE.md`
- AI 记忆文件用于持久化上下文

## 支持的语言与框架

| 语言 | 框架 | 分析增强 |
|------|------|----------|
| TypeScript/JavaScript | Next.js, NestJS, React, Express, Fastify | scc + madge + depcruise + AI |
| Go | 标准库, Gin, Echo | scc + go mod graph + AI |
| Rust | 标准库, Actix, Axum | scc + cargo tree + AI |
| Python | Django, FastAPI, Flask | scc + pipdeptree + AI |
| Java/Kotlin | Spring Boot, Gradle | scc + dependency tree + AI |
| 其他语言 | — | scc + AI 深度阅读 |

## 配置说明

X-Ray 的配置文件 `.xray-config.json` 位于项目根目录：

```json
{
  "version": 1,
  "targets": [
    {
      "name": "frontend",
      "path": "./frontend",
      "srcDir": "src",
      "language": "typescript",
      "framework": "nextjs",
      "tsconfig": "./frontend/tsconfig.json"
    }
  ],
  "outputDir": "docs/codebase",
  "updateClaudeMd": true,
  "updateMemory": true,
  "excludeDirs": ["node_modules", "dist", "coverage", "build"],
  "sameRepo": true
}
```

随时运行 `/xray setup` 重新配置。

## 系统要求

| 要求 | 版本 | 说明 |
|------|------|------|
| Claude Code | 最新版 | CLI、桌面端或 IDE 扩展 |
| 操作系统 | macOS / Linux | Windows 需通过 WSL |
| Git | 任意版本 | 用于增量分析 |
| scc | 自动安装 | 代码统计 |
| madge | 自动安装 | JS/TS 依赖图（可选） |
| dependency-cruiser | 自动安装 | JS/TS 依赖规则（可选） |

## 贡献

欢迎贡献！请参阅 [CONTRIBUTING.md](CONTRIBUTING.md) 了解指南。

## 许可证

[MIT](LICENSE) —— 可免费用于个人和商业用途。

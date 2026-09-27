# bkit-codex - Vibecoding Kit (OpenAI Codex Edition)

[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)
[![Codex CLI](https://img.shields.io/badge/Codex%20CLI-v0.100.0+-blue.svg)](https://github.com/openai/codex)
[![Version](https://img.shields.io/badge/Version-1.0.1-green.svg)](CHANGELOG.md)
[![Author](https://img.shields.io/badge/Author-DubDubDub%20Corp-orange.svg)](https://ww-w.ai)

> **PDCA methodology + Context Engineering for AI-native development**

bkit-codex is an [OpenAI Codex CLI](https://github.com/openai/codex) extension that transforms how you build software with AI. It provides structured development workflows, automatic documentation, and intelligent code assistance through the PDCA (Plan-Do-Check-Act) methodology and Context Engineering architecture.

---

## What is Context Engineering?

**Context Engineering** is the systematic curation of context tokens for optimal LLM inference -- going beyond simple prompt crafting to build entire systems that consistently guide AI behavior.

```
Traditional Prompt Engineering:
  "The art of writing good prompts"

Context Engineering:
  "The art of designing systems that integrate prompts, tools, and state
   to provide LLMs with optimal context for inference"
```

**bkit is a practical implementation of Context Engineering**, providing a systematic context management system across multiple AI coding platforms.

### bkit-codex's Context Engineering Architecture

bkit-codex implements Context Engineering through three interconnected layers:

| Layer | Components | Count | Purpose |
|-------|-----------|-------|---------|
| **Domain Knowledge** | Skills | 27 | Structured expert knowledge activated on-demand via progressive disclosure |
| **Behavioral Rules** | AGENTS.md | 2 files | Global + Project rules with MUST/ALWAYS/NEVER enforcement |
| **State Management** | MCP Tools + Lib Modules | 16 + 80 fn | PDCA status tracking, intent detection, template management, memory persistence, context recovery |

---

## Architecture

### 3-Tier Context Strategy

```
+------------------------------------------------------------------+
|                    Tier 1: AGENTS.md                              |
|                    (Always Loaded)                                |
|                                                                  |
|  Global AGENTS.md (~3.8 KB)    Project AGENTS.md (~2.0 KB)      |
|  - Session initialization      - Level-specific guidance         |
|  - 3 Core Principles           - Key skills reference            |
|  - PDCA workflow rules          - Response format rules           |
|  - MCP tools reference          - PDCA status location            |
|  - Code quality standards                                        |
|                                                                  |
|  Total: ~5.8 KB / 32 KB limit (18% used, 82% available)         |
+------------------------------------------------------------------+
                              |
                              v
+------------------------------------------------------------------+
|                    Tier 2: SKILL.md                               |
|                    (On-Demand Loading)                            |
|                                                                  |
|  Phase 1: name + description only (metadata scan)                |
|  Phase 2: Full SKILL.md body (when skill is activated)           |
|  Progressive Disclosure minimizes context usage                  |
+------------------------------------------------------------------+
                              |
                              v
+------------------------------------------------------------------+
|                    Tier 3: references/                            |
|                    (Deep Dive on Request)                         |
|                                                                  |
|  ~30 reference files (templates, patterns, checklists)           |
|  Loaded only when AI explicitly requests a reference file        |
+------------------------------------------------------------------+
```

### Architecture Paradigm Shift

```
bkit-claude-code (Hook-Driven, 100% Auto)
  Hook Event --> Script (stdin/stdout) --> decision: allow/block
  = System controls the AI

bkit-codex (Instruction-Driven, ~70% Auto)
  AGENTS.md Rule --> AI reads --> AI calls MCP Tool --> MCP returns guidance
  = AI voluntarily follows rules
```

### Component Map

```
bkit-codex/
|-- .agents/skills/          # 27 Codex Agent Skills
|   |-- bkit-rules/          # Core rules reference
|   |-- pdca/                # PDCA workflow management
|   |-- bkit-templates/      # Template selection
|   |-- starter/             # Beginner guidance
|   |-- dynamic/             # Fullstack guidance
|   |-- enterprise/          # Enterprise guidance
|   |-- development-pipeline/# 9-phase overview
|   |-- phase-1-schema/ ... phase-9-deployment/
|   |-- code-review/         # Code quality analysis
|   |-- zero-script-qa/      # Log-based testing
|   |-- mobile-app/          # React Native, Flutter, Expo
|   |-- desktop-app/         # Electron, Tauri
|   |-- codex-learning/      # Codex CLI guide
|   |-- plan-plus/           # Brainstorming-enhanced planning
|   +-- bkend-*/             # bkend.ai ecosystem (5 skills)
|
|-- packages/mcp-server/     # MCP Server (zero external dependencies)
|   |-- index.js             # STDIO transport (JSON-RPC 2.0)
|   |-- src/server.js        # Request dispatcher
|   |-- src/tools/           # 16 MCP tool implementations
|   +-- src/lib/             # Core library (~80 functions)
|       |-- core/            # config, cache, file, path
|       |-- pdca/            # status, level, phase, automation, template
|       |-- intent/          # language, trigger, ambiguity
|       +-- task/            # classification, creator
|
|-- AGENTS.md                # Project AGENTS.md (sample)
|-- agents.global.md         # Global AGENTS.md (install to ~/.codex/)
|-- bkit.config.json         # Centralized configuration
|-- install.sh               # Unix/Mac installer
|-- install.ps1              # Windows installer
|-- scripts/sync-deploy.sh   # Dev-to-deploy sync utility
|-- docs/                    # Documentation
+-- .github/workflows/       # CI/CD (npm publish)
```

---

## Features

- **PDCA Methodology** -- Structured development with automatic documentation and phase enforcement
- **16 MCP Tools** -- Session management, intent detection, PDCA workflow, template generation, memory persistence
- **27 Agent Skills** -- Domain-specific knowledge with progressive disclosure to save context tokens
- **9-Stage Development Pipeline** -- From schema design to deployment
- **3 Project Levels** -- Starter (static), Dynamic (fullstack), Enterprise (microservices)
- **8-Language Support** -- EN, KO, JA, ZH, ES, FR, DE, IT with auto-detection
- **Zero Dependencies** -- MCP server built with pure Node.js (no `node_modules`)
- **Context Recovery** -- Automatic state reconstruction after context compaction (recovery mode)
- **Task Chain** -- Linked PDCA task progression with automatic phase-to-phase advancement
- **Plan Plus** -- Brainstorming-enhanced planning with intent discovery and YAGNI review
- **Level-Specific Templates** -- Enterprise design template with 11 sections (security, observability, cost analysis)
- **Ambiguity Detection** -- Scores user prompts 0-100 and generates clarifying questions when needed
- **Session Memory** -- Persistent context across sessions via `docs/.bkit-memory.json`
- **Evaluator-Optimizer Pattern** -- Automatic gap analysis and fix cycles (max 5 iterations, 90% threshold)
- **Cross-Platform Install** -- One-line installation for Unix/Mac and Windows

---

## Quick Start

> **Note**: bkit-codex is designed for **OpenAI Codex CLI**. For Claude Code, see [bkit-claude-code](https://github.com/ww-w-ai/bkit-claude-code). For Gemini CLI, see [bkit-gemini](https://github.com/ww-w-ai/bkit-gemini).

### Prerequisites

- [OpenAI Codex CLI](https://github.com/openai/codex) v0.100.0 or later
- [Node.js](https://nodejs.org/) v20+
- [Git](https://git-scm.com/)

### Installation

#### Unix / macOS (Recommended)

```bash
curl -fsSL https://raw.githubusercontent.com/ww-w-ai/bkit-codex/main/install.sh | bash
```

#### Windows (PowerShell)

```powershell
irm https://raw.githubusercontent.com/ww-w-ai/bkit-codex/main/install.ps1 | iex
```

#### Manual Installation

```bash
# 1. Clone into project
git clone --depth 1 https://github.com/ww-w-ai/bkit-codex.git .bkit-codex

# 2. Link skills
mkdir -p .agents/skills
for skill in .bkit-codex/.agents/skills/*/; do
  ln -sf "../../.bkit-codex/.agents/skills/$(basename $skill)" ".agents/skills/$(basename $skill)"
done

# 3. Copy AGENTS.md
cp .bkit-codex/AGENTS.md ./AGENTS.md

# 4. Configure MCP server
mkdir -p .codex
cat > .codex/config.toml << 'EOF'
[mcp_servers.bkit]
command = "node"
args = ["./.bkit-codex/packages/mcp-server/index.js"]
startup_timeout_sec = 10
tool_timeout_sec = 60
required = true
EOF

# 5. Create PDCA directories
mkdir -p docs/01-plan/features docs/02-design/features docs/03-analysis docs/04-report
```

### Verify Installation

```bash
# Check skills are linked
ls .agents/skills/

# Check MCP config
cat .codex/config.toml

# Start Codex and invoke bkit
$pdca status
```

---

## Usage

### PDCA Workflow

```bash
$pdca plan <feature>     # Create plan document
$pdca design <feature>   # Create design document
$pdca do <feature>       # Implementation guide
$pdca analyze <feature>  # Run gap analysis
$pdca iterate <feature>  # Auto-fix with Evaluator-Optimizer pattern
$pdca report <feature>   # Generate completion report
$pdca status             # Check current PDCA status
$pdca next               # Guide to next PDCA step
```

### Project Initialization

```bash
$starter      # Static website (Starter level)
$dynamic      # Fullstack with BaaS (Dynamic level)
$enterprise   # Microservices with K8s (Enterprise level)
```

### Development Pipeline

```bash
$development-pipeline    # 9-phase pipeline overview
$phase-1-schema          # Schema & terminology definition
$phase-2-convention      # Coding conventions
$phase-3-mockup          # UI/UX mockups
$phase-4-api             # API design
$phase-5-design-system   # Design system
$phase-6-ui-integration  # UI integration
$phase-7-seo-security    # SEO & security
$phase-8-review          # Code review
$phase-9-deployment      # Deployment
```

### Quality & Learning

```bash
$code-review             # Code quality analysis
$zero-script-qa          # Log-based testing (Zero Script QA)
$codex-learning          # Codex CLI configuration guide
```

---

## PDCA Workflow

The core development cycle that bkit enforces:

```
Plan ──> Design ──> Do ──> Check ──> Act ──> Report
  │                          │         │
  │    (design required)     │    (if < 90%)
  │                          │         │
  X──── skip to Do ────X     +─────────+
                              iteration loop
                              (max 5 cycles)
```

| Phase | Action | Deliverable |
|-------|--------|-------------|
| **Plan** | Define goals, scope, success criteria | `docs/01-plan/features/{feature}.plan.md` |
| **Design** | Architecture, data model, API spec | `docs/02-design/features/{feature}.design.md` |
| **Do** | Implementation with pre/post-write checks | Source code matching design |
| **Check** | Gap analysis (design vs. implementation) | `docs/03-analysis/{feature}.analysis.md` |
| **Act** | Auto-fix gaps until match rate >= 90% | Updated source code |
| **Report** | Completion report with metrics | `docs/04-report/{feature}.report.md` |

### Key Rules

- **Design is mandatory**: You cannot skip from Plan directly to Do
- **Pre-write check**: MCP tool validates design document existence before code changes
- **Post-write guidance**: MCP tool suggests gap analysis after significant changes (>10 new lines or >20 modified lines)
- **Iteration loop**: Check and Act repeat until match rate reaches 90% (max 5 iterations)
- **Context recovery**: After context compaction, call `bkit_get_status` with `mode: "recovery"` to reconstruct state
- **Task chain**: Each feature creates a linked Plan->Design->Do->Check->Report task chain with automatic advancement

---

## Project Levels

Automatic detection based on project directory structure:

| Level | Description | Stack | Auto-Detection | Pipeline Phases |
|-------|-------------|-------|----------------|:---------------:|
| **Starter** | Static websites, portfolios | HTML, CSS, JS | Default (no special files) | 1 → 2 → 3 → 6 → 9 |
| **Dynamic** | Fullstack applications | Next.js, BaaS | `docker-compose.yml`, `.mcp.json`, `api/` | 1 → 2 → 3 → 4 → 5 → 6 → 7 → 9 |
| **Enterprise** | Microservices architecture | K8s, Terraform, MSA | `kubernetes/`, `terraform/` directories | All 9 phases |

---

## MCP Tools (16)

The MCP server provides 16 tools via JSON-RPC 2.0 over STDIO with **zero external dependencies**:

| Tool | Category | Purpose |
|------|----------|---------|
| `bkit_init` | Session | Initialize session, detect level, load PDCA status, compact summary |
| `bkit_analyze_prompt` | Intent | Detect language, match triggers, score ambiguity (8 languages) |
| `bkit_get_status` | PDCA | Retrieve current PDCA status with recommendations (supports recovery mode) |
| `bkit_pre_write_check` | PDCA | Pre-write compliance check (design document existence) |
| `bkit_post_write` | PDCA | Post-write guidance (gap analysis suggestions) |
| `bkit_complete_phase` | PDCA | Mark phase complete, validate transition, advance task chain |
| `bkit_pdca_plan` | Template | Generate plan document template with level-specific sections and task chain |
| `bkit_pdca_design` | Template | Generate design template (Starter/Dynamic/Enterprise variants) |
| `bkit_pdca_analyze` | Template | Generate gap analysis template |
| `bkit_pdca_next` | PDCA | Recommend next PDCA action based on current state |
| `bkit_classify_task` | Utility | Classify task size (quick_fix / minor_change / feature / major_feature) |
| `bkit_detect_level` | Utility | Detect project level from directory structure |
| `bkit_select_template` | Utility | Select template by phase and level |
| `bkit_check_deliverables` | Utility | Verify phase deliverables exist |
| `bkit_memory_read` | Memory | Read session memory |
| `bkit_memory_write` | Memory | Write session memory |

---

## Skills (27)

| Skill | Category | Trigger Examples |
|-------|----------|-----------------|
| **pdca** | Core | `$pdca plan`, `$pdca design`, `$pdca analyze` |
| **plan-plus** | Core | "brainstorming plan", "deep planning", "intent discovery" |
| **bkit-rules** | Core | Core rules (auto-applied via AGENTS.md) |
| **bkit-templates** | Core | "plan template", "design template" |
| **starter** | Level | "static site", "portfolio", "beginner" |
| **dynamic** | Level | "login", "fullstack", "authentication" |
| **enterprise** | Level | "microservices", "k8s", "terraform" |
| **development-pipeline** | Pipeline | "where to start", "development order" |
| **phase-1-schema** | Pipeline | "schema", "data model", "terminology" |
| **phase-2-convention** | Pipeline | "coding rules", "conventions" |
| **phase-3-mockup** | Pipeline | "mockup", "wireframe", "prototype" |
| **phase-4-api** | Pipeline | "API design", "REST endpoints" |
| **phase-5-design-system** | Pipeline | "design system", "component library" |
| **phase-6-ui-integration** | Pipeline | "frontend integration", "API client" |
| **phase-7-seo-security** | Pipeline | "SEO", "security hardening" |
| **phase-8-review** | Pipeline | "architecture review", "gap analysis" |
| **phase-9-deployment** | Pipeline | "CI/CD", "production deployment" |
| **code-review** | Quality | "review code", "check quality" |
| **zero-script-qa** | Quality | "test logs", "QA without scripts" |
| **mobile-app** | Platform | "React Native", "Flutter", "iOS app" |
| **desktop-app** | Platform | "Electron", "Tauri", "desktop app" |
| **codex-learning** | Learning | "learn Codex", "Codex CLI setup" |
| **bkend-quickstart** | bkend.ai | "bkend setup", "first project" |
| **bkend-data** | bkend.ai | "table", "CRUD", "schema", "filter" |
| **bkend-auth** | bkend.ai | "signup", "login", "JWT", "session" |
| **bkend-storage** | bkend.ai | "file upload", "presigned URL", "CDN" |
| **bkend-cookbook** | bkend.ai | "tutorial", "example project", "todo app" |

Skills use progressive disclosure -- only metadata is loaded initially, with full instructions injected when activated.

---

## Language Support

bkit automatically detects your language from trigger keywords in 8 languages:

| Language | Trigger Keywords |
|----------|-----------------|
| English | static website, beginner, API design, verify, analyze |
| Korean | 정적 웹, 초보자, API 설계, 검증, 분석 |
| Japanese | 静的サイト, 初心者, API設計, 確認, 分析 |
| Chinese | 静态网站, 初学者, API设计, 验证, 分析 |
| Spanish | sitio web estatico, principiante, verificar |
| French | site web statique, debutant, verifier |
| German | statische Website, Anfanger, prufen |
| Italian | sito web statico, principiante, verificare |

---

## Configuration

### MCP Server (`.codex/config.toml`)

```toml
[mcp_servers.bkit]
command = "node"
args = ["./.bkit-codex/packages/mcp-server/index.js"]
startup_timeout_sec = 10
tool_timeout_sec = 60
required = true
```

### bkit Config (`bkit.config.json`)

```json
{
  "pdca": {
    "matchRateThreshold": 90,
    "maxIterations": 5,
    "statusFile": "docs/.pdca-status.json",
    "memoryFile": "docs/.bkit-memory.json"
  },
  "taskClassification": {
    "thresholds": { "quickFix": 10, "minorChange": 50, "feature": 200 }
  },
  "conventions": {
    "naming": {
      "components": "PascalCase",
      "functions": "camelCase",
      "constants": "UPPER_SNAKE_CASE",
      "files": "kebab-case"
    }
  },
  "supportedLanguages": ["en", "ko", "ja", "zh", "es", "fr", "de", "it"]
}
```

---

## Relationship to bkit-claude-code

bkit-codex is a port of [bkit-claude-code](https://github.com/ww-w-ai/bkit-claude-code), adapted for OpenAI Codex CLI compatibility. Key differences:

| Aspect | bkit-claude-code | bkit-codex |
|--------|-----------------|------------|
| Platform | Claude Code | OpenAI Codex CLI |
| Automation | Hook-Driven (100% auto) | Instruction-Driven (~70% auto) |
| Context file | CLAUDE.md | AGENTS.md |
| Skills format | YAML frontmatter | SKILL.md + openai.yaml |
| Agent system | 16 dedicated agents | SKILL.md descriptions |
| State management | Hook scripts | MCP tools |
| Hooks | 10 hook events (45 scripts) | N/A (rules in AGENTS.md) |
| Team orchestration | CTO-Led Agent Teams | N/A |
| Functions | 241 (5 lib modules) | 80 (4 lib modules) |
| Commands | Slash commands (`/pdca`) | Skill invocation (`$pdca`) |
| Dependencies | Node.js modules | Zero external dependencies |

### What's Preserved

- 3 Core Principles (Automation First, No Guessing, Docs = Code)
- PDCA workflow with phase transition validation
- 3-Level system (Starter / Dynamic / Enterprise)
- 9-Phase development pipeline
- 8-language trigger support
- PDCA document templates
- State file format (`docs/.pdca-status.json`)

### What's Different

- No hook system -- enforcement relies on AGENTS.md rules + MCP tool guidance
- No team orchestration -- Codex CLI doesn't support agent spawning
- Reduced function set (80 of 241) -- excluded hook I/O, team management, Claude Code-specific modules
- Skills use Codex-native `SKILL.md` format with `openai.yaml` manifest
- Context recovery mode for state reconstruction after compaction
- Task chain with automatic phase-to-phase advancement

---

## Documentation

- [Installation Guide](docs/installation.md) -- Detailed setup instructions
- [Architecture](docs/architecture.md) -- System design and context strategy
- [Migration Guide](docs/migration-guide.md) -- Migrating from bkit-claude-code
- [Skills API](docs/api/skills-api.md) -- All 26 skills reference
- [MCP API](docs/api/mcp-api.md) -- All 16 MCP tools reference
- [Changelog](CHANGELOG.md) -- Version history

---

## Contributing

We welcome contributions! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

### Quick Contribution Guide

1. Fork the repository
2. Create a feature branch from `main`
3. Make changes following [code style guidelines](CONTRIBUTING.md#code-style)
4. Run tests: `node --test packages/mcp-server/tests/`
5. Submit a pull request

### Key Rules

- **Zero dependencies**: MCP server must use pure Node.js only
- **Consistent patterns**: All tools follow `{ handler, definition }` pattern
- **8-language triggers**: Include triggers in all 8 supported languages
- **JSDoc comments**: Required for all public functions in `lib/`

### Branch Protection

- Only `admin` team members can merge to `main`
- All changes require pull request review
- Version releases are managed through Git tags

---

## License

Copyright 2024-2026 DubDubDub Corp.

Licensed under the Apache License, Version 2.0. See [LICENSE](LICENSE) for details.

---

## Support

- **Issues**: [GitHub Issues](https://github.com/ww-w-ai/bkit-codex/issues)
- **Email**: biz@ww-w.ai

---

Made with AI by [DubDubDub Corp.](https://ww-w.ai)

# Installation Guide

## Prerequisites

- **OpenAI Codex CLI** v0.100.0 or later
- **Node.js** 20 or later
- **Git** for cloning the repository

## Installation Scenarios

### 1. Project-Level Installation (Recommended)

Install bkit-codex into a specific project. Best for teams working on a single project.

**Unix/Mac**:
```bash
cd your-project
curl -fsSL https://raw.githubusercontent.com/ww-w-ai/bkit-codex/main/install.sh | bash
```

**Windows**:
```powershell
cd your-project
irm https://raw.githubusercontent.com/ww-w-ai/bkit-codex/main/install.ps1 | iex
```

**What the installer does**:
1. Clones `bkit-codex` into `.bkit-codex/` directory
2. Creates symlinks from `.agents/skills/` to bkit-codex skills
3. Creates `AGENTS.md` with bkit project configuration
4. Configures MCP server in `.codex/config.toml`
5. Initializes PDCA document directories (`docs/01-plan/`, `docs/02-design/`, etc.)
6. Adds `.bkit-codex/` to `.gitignore`

**After installation**:
```
your-project/
├── .agents/skills/       # Symlinks to bkit-codex skills (26 skills)
├── .bkit-codex/          # bkit-codex repository (gitignored)
├── .codex/config.toml    # MCP server configuration
├── AGENTS.md             # Project-level bkit rules
└── docs/
    ├── 01-plan/features/
    ├── 02-design/features/
    ├── 03-analysis/
    └── 04-report/
```

### 2. Global Installation

Install bkit-codex globally so it applies to all projects. Best for individual developers.

```bash
# Clone to home directory
git clone --depth 1 https://github.com/ww-w-ai/bkit-codex.git ~/.bkit-codex

# Link skills globally
mkdir -p ~/.agents/skills
for skill_dir in ~/.bkit-codex/.agents/skills/*/; do
  skill_name=$(basename "$skill_dir")
  ln -sf "$skill_dir" "$HOME/.agents/skills/$skill_name"
done

# Install Global AGENTS.md
mkdir -p ~/.codex
cp ~/.bkit-codex/agents.global.md ~/.codex/AGENTS.md

# Configure MCP globally
cat >> ~/.codex/config.toml << EOF

[mcp_servers.bkit]
command = "node"
args = ["$HOME/.bkit-codex/packages/mcp-server/index.js"]
startup_timeout_sec = 10
tool_timeout_sec = 30
EOF
```

### 3. Skill Installer (Future)

When Codex supports the `$skill-installer` pattern:

```
$skill-installer bkit-codex
```

## Verifying Installation

Start Codex in your project directory and verify:

1. **Skills are loaded**: Run `/skills` to see all 26 bkit skills
2. **MCP is connected**: The `bkit_init` tool should be called automatically
3. **PDCA is ready**: Type `$pdca status` to check PDCA state

## Manual Configuration

### Custom MCP Server Settings

Edit `.codex/config.toml`:

```toml
[mcp_servers.bkit]
command = "node"
args = ["./.bkit-codex/packages/mcp-server/index.js"]
startup_timeout_sec = 10    # Increase if slow startup
tool_timeout_sec = 30       # Increase for large projects
required = true             # Set to false to make optional
```

### Using npm Instead of Local Clone

After the MCP server is published to npm:

```toml
[mcp_servers.bkit]
command = "npx"
args = ["-y", "@popup-studio/bkit-codex-mcp"]
startup_timeout_sec = 15
tool_timeout_sec = 30
```

### Custom bkit Configuration

Edit `bkit.config.json` in the project root or `.bkit-codex/`:

```json
{
  "pdca": {
    "matchRateThreshold": 85,
    "maxIterations": 10
  },
  "taskClassification": {
    "thresholds": { "quickFix": 5, "minorChange": 30, "feature": 150 }
  }
}
```

## Updating

**Project-level**:
```bash
cd .bkit-codex && git pull
```

**Global**:
```bash
cd ~/.bkit-codex && git pull
```

## Uninstalling

**Project-level**:
```bash
# Remove bkit-codex clone
rm -rf .bkit-codex

# Remove skill symlinks
for link in .agents/skills/*; do
  [ -L "$link" ] && readlink "$link" | grep -q ".bkit-codex" && rm "$link"
done

# Remove MCP config from .codex/config.toml (manual edit)
# Remove AGENTS.md if no longer needed
```

**Global**:
```bash
rm -rf ~/.bkit-codex
rm -rf ~/.agents/skills/bkit-* ~/.agents/skills/pdca ~/.agents/skills/starter
rm -rf ~/.agents/skills/dynamic ~/.agents/skills/enterprise
rm -rf ~/.agents/skills/development-pipeline ~/.agents/skills/phase-*
rm -rf ~/.agents/skills/code-review ~/.agents/skills/zero-script-qa
rm -rf ~/.agents/skills/mobile-app ~/.agents/skills/desktop-app
rm -rf ~/.agents/skills/codex-learning ~/.agents/skills/bkend-*
# Edit ~/.codex/config.toml to remove [mcp_servers.bkit] section
# Edit ~/.codex/AGENTS.md to remove bkit rules
```

## Troubleshooting

### MCP Server Not Starting

1. Check Node.js version: `node --version` (must be 20+)
2. Verify the path in config.toml points to a valid `index.js`
3. Test manually: `node .bkit-codex/packages/mcp-server/index.js`
4. Check stderr output for error messages

### Skills Not Loading

1. Verify symlinks: `ls -la .agents/skills/`
2. Check SKILL.md has valid YAML frontmatter
3. Ensure directory name matches `name` in frontmatter

### PDCA Status Not Persisting

1. Check `docs/.pdca-status.json` exists and is writable
2. Verify the MCP server has file system access to the project directory

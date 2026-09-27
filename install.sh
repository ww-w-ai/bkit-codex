#!/bin/bash
# install.sh - bkit-codex project installer
# Installs bkit-codex into the current project directory or globally.
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/ww-w-ai/bkit-codex/main/install.sh | bash
#   ./install.sh [--global] [--uninstall] [--version] [--help]

set -euo pipefail

REPO="ww-w-ai/bkit-codex"
BKIT_VERSION="1.0.1"

# ── Color helpers ──────────────────────────────────────────────────────────────

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

info()  { echo -e "${BLUE}[INFO]${NC} $1"; }
ok()    { echo -e "${GREEN}[OK]${NC}   $1"; }
warn()  { echo -e "${YELLOW}[WARN]${NC} $1"; }
fail()  { echo -e "${RED}[FAIL]${NC} $1"; }

# ── Argument parsing ──────────────────────────────────────────────────────────

MODE="project"
FORCE=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --global)    MODE="global"; shift ;;
    --uninstall) MODE="uninstall"; shift ;;
    --version)   MODE="version"; shift ;;
    --force)     FORCE=true; shift ;;
    --help|-h)   MODE="help"; shift ;;
    *) fail "Unknown option: $1"; exit 1 ;;
  esac
done

# ── Path resolution ───────────────────────────────────────────────────────────

if [ "$MODE" = "global" ] || [ "$MODE" = "uninstall" ] && [ ! -d ".bkit-codex" ] && [ -d "$HOME/.bkit-codex" ]; then
  SKILLS_DIR="$HOME/.agents/skills"
  CONFIG_DIR="$HOME/.codex"
  CONFIG_FILE="$HOME/.codex/config.toml"
  INSTALL_DIR="$HOME/.bkit-codex"
  INSTALL_MODE="global"
elif [ "$MODE" = "global" ]; then
  SKILLS_DIR="$HOME/.agents/skills"
  CONFIG_DIR="$HOME/.codex"
  CONFIG_FILE="$HOME/.codex/config.toml"
  INSTALL_DIR="$HOME/.bkit-codex"
  INSTALL_MODE="global"
else
  SKILLS_DIR=".agents/skills"
  CONFIG_DIR=".codex"
  CONFIG_FILE=".codex/config.toml"
  INSTALL_DIR=".bkit-codex"
  INSTALL_MODE="project"
fi

# ── Help ──────────────────────────────────────────────────────────────────────

show_help() {
  cat << 'HELP'
bkit-codex installer

Usage:
  install.sh [options]

Options:
  --global      Install to ~/.agents/skills/ and ~/.codex/ (user-level)
  --uninstall   Remove bkit-codex installation
  --version     Show installed version
  --force       Overwrite AGENTS.md even if modified
  --help, -h    Show this help message

Examples:
  # Project-level install (default)
  curl -fsSL https://raw.githubusercontent.com/ww-w-ai/bkit-codex/main/install.sh | bash

  # Global install
  ./install.sh --global

  # Uninstall
  ./install.sh --uninstall
HELP
}

# ── Version ───────────────────────────────────────────────────────────────────

show_version() {
  if [ -f "$INSTALL_DIR/.installed-version" ]; then
    echo "bkit-codex v$(cat "$INSTALL_DIR/.installed-version")"
  elif [ -f "$INSTALL_DIR/packages/mcp-server/package.json" ]; then
    local ver
    ver=$(node -e "console.log(require('./$INSTALL_DIR/packages/mcp-server/package.json').version)" 2>/dev/null || echo "unknown")
    echo "bkit-codex v$ver"
  else
    echo "bkit-codex: not installed"
  fi
}

# ── Hash helper (cross-platform: md5sum on Linux, md5 on macOS) ───────────────

file_hash() {
  if command -v md5sum >/dev/null 2>&1; then
    md5sum "$1" 2>/dev/null | cut -d' ' -f1
  elif command -v md5 >/dev/null 2>&1; then
    md5 -q "$1" 2>/dev/null
  else
    echo "nohash"
  fi
}

# ── Validate installation ────────────────────────────────────────────────────

validate_install() {
  local errors=0

  info "Validating installation..."

  # Check symlinks resolve
  for skill_dir in "$SKILLS_DIR"/*/; do
    [ -d "$skill_dir" ] || continue
    local skill_name skill_path
    skill_name=$(basename "$skill_dir")
    skill_path="${skill_dir%/}"
    if [ -L "$skill_path" ] && [ ! -e "$skill_path" ]; then
      fail "Broken symlink: $skill_name"
      errors=$((errors + 1))
    elif [ ! -f "${skill_dir}SKILL.md" ]; then
      fail "Missing SKILL.md in: $skill_name"
      errors=$((errors + 1))
    fi
  done

  # Count skills
  local skill_count
  skill_count=$(find "$SKILLS_DIR" -maxdepth 1 -mindepth 1 -type d -o -type l 2>/dev/null | wc -l | tr -d ' ')
  if [ "$skill_count" -ge 20 ]; then
    ok "$skill_count skills linked"
  else
    warn "Only $skill_count skills found (expected 27)"
  fi

  # Check MCP server responds
  local mcp_path="$INSTALL_DIR/packages/mcp-server/index.js"
  if [ -f "$mcp_path" ] && command -v node >/dev/null 2>&1; then
    local response
    response=$(echo '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2024-11-05","clientInfo":{"name":"test","version":"1.0.0"}}}' | \
      timeout 5 node "$mcp_path" 2>/dev/null | head -1 || echo "")
    if echo "$response" | grep -q "protocolVersion" 2>/dev/null; then
      ok "MCP server responds correctly"
    else
      warn "MCP server did not respond (requires node >= 18)"
    fi
  elif ! command -v node >/dev/null 2>&1; then
    warn "Node.js not found - MCP server requires node >= 18"
  fi

  # Check config.toml
  if grep -q "mcp_servers.bkit" "$CONFIG_FILE" 2>/dev/null; then
    ok "MCP configuration present"
  else
    fail "MCP configuration missing from $CONFIG_FILE"
    errors=$((errors + 1))
  fi

  # Check AGENTS.md
  if [ "$INSTALL_MODE" = "project" ] && [ -f "AGENTS.md" ]; then
    ok "AGENTS.md present"
  elif [ "$INSTALL_MODE" = "global" ]; then
    ok "Global install (AGENTS.md is project-specific)"
  fi

  if [ "$errors" -eq 0 ]; then
    ok "All validations passed"
  else
    fail "$errors validation error(s) found"
  fi

  return "$errors"
}

# ── Uninstall ─────────────────────────────────────────────────────────────────

do_uninstall() {
  info "Uninstalling bkit-codex ($INSTALL_MODE mode)..."

  # Remove skill symlinks (only bkit-codex ones)
  if [ -d "$SKILLS_DIR" ]; then
    local removed=0
    for skill_dir in "$SKILLS_DIR"/*/; do
      # Strip trailing slash so -L test works on symlinks
      local skill_path="${skill_dir%/}"
      [ -e "$skill_path" ] || [ -L "$skill_path" ] || continue
      if [ -L "$skill_path" ]; then
        local target
        target=$(readlink "$skill_path" 2>/dev/null || echo "")
        if echo "$target" | grep -q "bkit-codex"; then
          rm -f "$skill_path"
          removed=$((removed + 1))
        fi
      fi
    done
    ok "Removed $removed skill symlinks"
    # Clean up empty directories
    rmdir "$SKILLS_DIR" 2>/dev/null || true
    if [ "$INSTALL_MODE" = "project" ]; then
      rmdir ".agents" 2>/dev/null || true
    fi
  fi

  # Remove MCP config entry
  if [ -f "$CONFIG_FILE" ]; then
    local tmp_file
    tmp_file=$(mktemp)
    awk '
      /^\[mcp_servers\.bkit\]/ { skip=1; next }
      /^\[/ { skip=0 }
      !skip { print }
    ' "$CONFIG_FILE" > "$tmp_file"
    # Remove trailing blank lines
    sed -e :a -e '/^\n*$/{$d;N;ba}' "$tmp_file" > "${tmp_file}.clean" 2>/dev/null && mv "${tmp_file}.clean" "$tmp_file" || true
    mv "$tmp_file" "$CONFIG_FILE"
    ok "Removed MCP config from $CONFIG_FILE"

    # Remove config.toml if empty (only whitespace)
    if [ ! -s "$CONFIG_FILE" ] || ! grep -q '[^[:space:]]' "$CONFIG_FILE" 2>/dev/null; then
      rm -f "$CONFIG_FILE"
      rmdir "$CONFIG_DIR" 2>/dev/null || true
      ok "Removed empty $CONFIG_DIR/"
    fi
  else
    warn "No config file found at $CONFIG_FILE"
  fi

  # Remove clone directory
  if [ -d "$INSTALL_DIR" ]; then
    rm -rf "$INSTALL_DIR"
    ok "Removed: $INSTALL_DIR"
  else
    warn "Install directory not found: $INSTALL_DIR"
  fi

  echo ""
  warn "AGENTS.md, docs/, .gitignore left intact (may contain user data)"
  info "Uninstall complete"
}

# ── Install ───────────────────────────────────────────────────────────────────

do_install() {
  echo ""
  info "Installing bkit-codex ($INSTALL_MODE mode)..."
  echo ""

  # ── Step 1: Clone or update repository ──────────────────────────────────

  if [ -d "$INSTALL_DIR" ]; then
    info "Updating existing installation..."
    git -C "$INSTALL_DIR" pull --ff-only 2>/dev/null && ok "Repository updated" || warn "git pull failed (offline?)"
  else
    info "Cloning repository..."
    git clone --depth 1 "https://github.com/$REPO.git" "$INSTALL_DIR"
    ok "Cloned to $INSTALL_DIR"
  fi

  # Save installed version
  local version
  version=$(node -e "console.log(require('./$INSTALL_DIR/packages/mcp-server/package.json').version)" 2>/dev/null || echo "unknown")
  echo "$version" > "$INSTALL_DIR/.installed-version"

  # ── Step 2: Create skill symlinks ───────────────────────────────────────

  mkdir -p "$SKILLS_DIR"
  local linked=0
  local skipped=0
  for skill_src in "$INSTALL_DIR/.agents/skills"/*/; do
    [ -d "$skill_src" ] || continue
    local skill_name
    skill_name=$(basename "$skill_src")
    local skill_dest="$SKILLS_DIR/$skill_name"

    if [ -L "$skill_dest" ] || [ -d "$skill_dest" ]; then
      skipped=$((skipped + 1))
    else
      # Calculate relative path from skills dir to source
      if [ "$INSTALL_MODE" = "global" ]; then
        ln -sf "$INSTALL_DIR/.agents/skills/$skill_name" "$skill_dest"
      else
        ln -sf "../../$INSTALL_DIR/.agents/skills/$skill_name" "$skill_dest"
      fi
      linked=$((linked + 1))
    fi
  done
  ok "Skills: $linked linked, $skipped already present"

  # ── Step 3: AGENTS.md (project-level only) ──────────────────────────────

  if [ "$INSTALL_MODE" = "project" ]; then
    if [ ! -f "AGENTS.md" ]; then
      cp "$INSTALL_DIR/AGENTS.md" "AGENTS.md"
      ok "Created: AGENTS.md"
    elif [ "$FORCE" = true ]; then
      cp "$INSTALL_DIR/AGENTS.md" "AGENTS.md"
      ok "Overwritten: AGENTS.md (--force)"
    else
      local current_hash source_hash
      current_hash=$(file_hash "AGENTS.md")
      source_hash=$(file_hash "$INSTALL_DIR/AGENTS.md")

      if [ "$current_hash" = "$source_hash" ]; then
        ok "AGENTS.md is up to date"
      else
        warn "AGENTS.md differs from source (use --force to overwrite)"
      fi
    fi
  fi

  # ── Step 4: Configure MCP server ────────────────────────────────────────

  mkdir -p "$CONFIG_DIR"

  # Determine MCP server path based on install mode
  # Global mode must use absolute paths so codex can find the MCP server
  # regardless of the working directory
  local mcp_args
  if [ "$INSTALL_MODE" = "global" ]; then
    local abs_install_dir
    abs_install_dir="$(cd "$INSTALL_DIR" && pwd)"
    mcp_args="[\"$abs_install_dir/packages/mcp-server/index.js\"]"
  else
    mcp_args='["./.bkit-codex/packages/mcp-server/index.js"]'
  fi

  local mcp_config
  mcp_config=$(cat << MCPEOF

# bkit-codex MCP server (PDCA methodology automation)
[mcp_servers.bkit]
command = "node"
args = $mcp_args
startup_timeout_sec = 10
tool_timeout_sec = 60
required = true
MCPEOF
)

  if [ ! -f "$CONFIG_FILE" ]; then
    # Remove leading blank line for new file
    echo "${mcp_config#$'\n'}" > "$CONFIG_FILE"
    ok "Created: $CONFIG_FILE"
  elif ! grep -q "mcp_servers.bkit" "$CONFIG_FILE" 2>/dev/null; then
    echo "$mcp_config" >> "$CONFIG_FILE"
    ok "Updated: $CONFIG_FILE (added bkit MCP)"
  else
    # Check if timeout needs update (30 -> 60)
    if grep -q "tool_timeout_sec = 30" "$CONFIG_FILE" 2>/dev/null; then
      sed -i.bak 's/tool_timeout_sec = 30/tool_timeout_sec = 60/' "$CONFIG_FILE" && rm -f "${CONFIG_FILE}.bak"
      ok "Updated: $CONFIG_FILE (tool_timeout_sec 30 -> 60)"
    else
      ok "MCP config already present"
    fi
  fi

  # ── Step 5: Initialize PDCA directories (project-level only) ────────────

  if [ "$INSTALL_MODE" = "project" ]; then
    mkdir -p docs/01-plan/features
    mkdir -p docs/02-design/features
    mkdir -p docs/03-analysis
    mkdir -p docs/04-report
    ok "PDCA directories ready"
  fi

  # ── Step 6: Update .gitignore (project-level only) ──────────────────────

  if [ "$INSTALL_MODE" = "project" ]; then
    if [ -f ".gitignore" ]; then
      if ! grep -q ".bkit-codex/" ".gitignore" 2>/dev/null; then
        printf "\n# bkit-codex\n.bkit-codex/\n" >> ".gitignore"
        ok "Updated: .gitignore"
      else
        ok ".gitignore already configured"
      fi
    else
      printf "# bkit-codex\n.bkit-codex/\n" > ".gitignore"
      ok "Created: .gitignore"
    fi
  fi

  # ── Step 7: Post-install validation ─────────────────────────────────────

  echo ""
  validate_install || true

  # ── Summary ─────────────────────────────────────────────────────────────

  echo ""
  info "bkit-codex v$version installed successfully! ($INSTALL_MODE mode)"
  local total_skills
  total_skills=$(find "$SKILLS_DIR" -maxdepth 1 -mindepth 1 \( -type d -o -type l \) 2>/dev/null | wc -l | tr -d ' ')
  echo "  Skills:     $total_skills linked"
  echo "  MCP Server: configured in $CONFIG_FILE"
  if [ "$INSTALL_MODE" = "project" ]; then
    echo "  PDCA Docs:  docs/ directory ready"
  fi
  echo ""
  echo 'Start Codex and type $pdca to begin!'
}

# ── Main dispatch ─────────────────────────────────────────────────────────────

case "$MODE" in
  help)
    show_help
    ;;
  version)
    show_version
    ;;
  uninstall)
    do_uninstall
    ;;
  project|global)
    do_install
    ;;
  *)
    fail "Unknown mode: $MODE"
    exit 1
    ;;
esac

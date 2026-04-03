#!/usr/bin/env bash
set -euo pipefail

# X-Ray — Claude Code Skill Installer
# Usage: curl -fsSL https://raw.githubusercontent.com/anthropics/project-xray/main/install.sh | bash

REPO_URL="https://github.com/anthropics/project-xray.git"
SKILL_NAME="xray"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

info()  { echo -e "${BLUE}[info]${NC} $*"; }
ok()    { echo -e "${GREEN}[ok]${NC} $*"; }
warn()  { echo -e "${YELLOW}[warn]${NC} $*"; }
error() { echo -e "${RED}[error]${NC} $*" >&2; }

# Determine install location
GLOBAL_SKILL_DIR="$HOME/.claude/skills/${SKILL_NAME}"
LOCAL_SKILL_DIR=".claude/skills/${SKILL_NAME}"

echo ""
echo "  X-Ray — Deep Codebase Analysis for Claude Code"
echo "  ================================================"
echo ""

# Check if we're in a project directory (has .git)
IN_PROJECT=false
if [ -d ".git" ] || [ -f ".git" ]; then
  IN_PROJECT=true
fi

# Ask install mode
if [ "$IN_PROJECT" = true ]; then
  echo "Detected project directory: $(basename "$(pwd)")"
  echo ""
  echo "Install options:"
  echo "  1) Global install   — available in all projects (~/.claude/skills/)"
  echo "  2) Project install  — shared with teammates via git (.claude/skills/)"
  echo "  3) Both"
  echo ""
  read -rp "Choose [1/2/3] (default: 1): " INSTALL_MODE
  INSTALL_MODE="${INSTALL_MODE:-1}"
else
  INSTALL_MODE="1"
  info "Not in a project directory — installing globally."
fi

install_skill() {
  local dest="$1"
  local label="$2"

  if [ -d "$dest" ]; then
    warn "$label already exists at $dest"
    read -rp "Overwrite? [y/N]: " OVERWRITE
    if [[ ! "$OVERWRITE" =~ ^[Yy] ]]; then
      info "Skipping $label install."
      return
    fi
    rm -rf "$dest"
  fi

  info "Installing $label to $dest ..."

  # Clone to temp dir, copy skill only
  TMPDIR_CLONE="$(mktemp -d)"
  trap "rm -rf '$TMPDIR_CLONE'" EXIT

  git clone --single-branch --depth 1 "$REPO_URL" "$TMPDIR_CLONE" 2>/dev/null

  mkdir -p "$(dirname "$dest")"
  cp -r "$TMPDIR_CLONE/skills/${SKILL_NAME}" "$dest"

  rm -rf "$TMPDIR_CLONE"
  trap - EXIT

  ok "$label installed at $dest"
}

case "$INSTALL_MODE" in
  1)
    install_skill "$GLOBAL_SKILL_DIR" "Global skill"
    ;;
  2)
    install_skill "$LOCAL_SKILL_DIR" "Project skill"
    ;;
  3)
    install_skill "$GLOBAL_SKILL_DIR" "Global skill"
    install_skill "$LOCAL_SKILL_DIR" "Project skill"
    ;;
  *)
    error "Invalid choice. Exiting."
    exit 1
    ;;
esac

echo ""
ok "X-Ray installed successfully!"
echo ""
echo "  Usage in Claude Code:"
echo "    /xray setup    — Configure targets for your project"
echo "    /xray          — Run deep codebase analysis"
echo "    /xray --full   — Force full re-analysis"
echo ""
echo "  First time? Just run /xray — it will guide you through setup."
echo ""

#!/usr/bin/env bash
#
# Dotfiles installer — run automatically by `coder dotfiles`.
# Coder clones this repo to ~/.dotfiles and executes this script.
# Safe to re-run: it installs missing tools and (re)creates symlinks.
#
set -euo pipefail

# Directory this script lives in = the dotfiles checkout root.
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

log() { printf '\033[1;34m[dotfiles]\033[0m %s\n' "$*"; }

# ---------------------------------------------------------------------------
# 1. Install dependencies the dotfiles assume (best-effort, never fatal)
# ---------------------------------------------------------------------------
have() { command -v "$1" >/dev/null 2>&1; }

install_deps() {
  if have brew; then
    log "Installing deps via Homebrew"
    brew install starship fzf tmux neovim || true
    return
  fi

  if have apt-get; then
    log "Installing deps via apt"
    local SUDO=""; [ "$(id -u)" -ne 0 ] && have sudo && SUDO="sudo"
    $SUDO apt-get update -y || true
    $SUDO apt-get install -y tmux neovim fzf curl git || true
  elif have dnf; then
    log "Installing deps via dnf"
    local SUDO=""; [ "$(id -u)" -ne 0 ] && have sudo && SUDO="sudo"
    $SUDO dnf install -y tmux neovim fzf curl git || true
  elif have apk; then
    log "Installing deps via apk"
    local SUDO=""; [ "$(id -u)" -ne 0 ] && have sudo && SUDO="sudo"
    $SUDO apk add --no-cache tmux neovim fzf curl git || true
  else
    log "No known package manager found; skipping system deps"
  fi

  # starship isn't in most base repos — use the official installer.
  if ! have starship; then
    log "Installing starship prompt"
    curl -sS https://starship.rs/install.sh | sh -s -- --yes --bin-dir "$HOME/.local/bin" || \
      log "starship install failed (prompt will fall back gracefully)"
  fi
}

install_deps

# ---------------------------------------------------------------------------
# 2. Symlink dotfiles into $HOME
# ---------------------------------------------------------------------------
link() {
  local src="$DOTFILES_DIR/$1" dest="$HOME/$1"
  [ -e "$src" ] || { log "skip $1 (not in repo)"; return; }
  mkdir -p "$(dirname "$dest")"
  # Back up a pre-existing real file (not our symlink) once.
  if [ -e "$dest" ] && [ ! -L "$dest" ]; then
    mv "$dest" "$dest.bak.$$"
    log "backed up existing $1 -> $1.bak.$$"
  fi
  ln -sfn "$src" "$dest"
  log "linked $1"
}

link .bashrc
link .bash_profile
link .profile
link .tmux.conf
link .config/starship.toml
link .config/nvim

log "Done. Open a new shell to pick up the changes."

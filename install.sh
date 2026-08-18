#!/usr/bin/env bash
#
# Dotfiles installer — run automatically by `coder dotfiles`.
# Coder clones this repo to ~/.dotfiles and executes this script.
# Safe to re-run: it installs missing tools and (re)creates symlinks.
#
# Usage: install.sh [--dry-run] [--no-gui]
#   --dry-run   print what would happen without changing anything
#   --no-gui    skip the large macOS GUI apps in Brewfile.gui
#
# One command reproduces the full environment:
#   1. symlink configs into $HOME (including the mise tool manifest)
#   2. system packages: brew bundle on macOS (+ Brewfile.gui unless --no-gui),
#      apt/dnf/apk on Linux
#   3. mise installs the pinned CLI tools (same exact versions everywhere)
#
# SECURITY NOTE: Homebrew, rustup, herdr, claude-code, and cursor-agent are
# installed by piping their official installers (fetched over TLS from the
# vendors' own domains) into a shell, unverified — the vendors' documented
# method, but it trusts those domains. mise itself is version-pinned below
# and its installer checksum-verifies the binary; the tools mise installs
# are checksum-verified by its aqua backend.
#
set -euo pipefail

# Directory this script lives in = the dotfiles checkout root.
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

DRY_RUN=0
NO_GUI=0
for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY_RUN=1 ;;
    --no-gui)  NO_GUI=1 ;;
    *) echo "usage: install.sh [--dry-run] [--no-gui]" >&2; exit 2 ;;
  esac
done

log()  { printf '\033[1;34m[dotfiles]\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m[dotfiles]\033[0m %s\n' "$*"; }
have() { command -v "$1" >/dev/null 2>&1; }

# Essential failures are collected and reported at the end (nonzero exit).
FAILURES=()
fail() { warn "FAILED: $1"; FAILURES+=("$1"); }

# ---------------------------------------------------------------------------
# 1. Symlink dotfiles into $HOME (first: mise reads its config from here)
# ---------------------------------------------------------------------------
link() {
  local src="$DOTFILES_DIR/$1" dest="$HOME/$1"
  [ -e "$src" ] || { log "skip $1 (not in repo)"; return; }
  # Bare-repo layout (work tree = $HOME): src and dest are the same file.
  # Linking would move the real file away and point it at itself — skip.
  if [ "$src" -ef "$dest" ]; then
    log "skip $1 (already in place)"
    return
  fi
  if [ "$DRY_RUN" = 1 ]; then log "would link $1"; return; fi
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
link .inputrc
link .tmux.conf
link .config/starship.toml
link .config/nvim
link .config/git/ignore
link .config/htop/htoprc
link .config/hunk/config.toml
link .config/mise/config.toml

# ---------------------------------------------------------------------------
# 2. System packages (best-effort for extras; essentials are tracked)
#    Only what mise can't manage: tmux/mosh/zip need system integration,
#    GUI apps are Mac-only. Everything else comes from mise, pinned.
# ---------------------------------------------------------------------------
install_mac() {
  if ! have brew; then
    if [ "$DRY_RUN" = 1 ]; then log "would install Homebrew"; return; fi
    log "Installing Homebrew"
    NONINTERACTIVE=1 /bin/bash -c \
      "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" || {
      fail "Homebrew install"
      return
    }
    eval "$(/opt/homebrew/bin/brew shellenv 2>/dev/null)" 2>/dev/null || \
      eval "$(/usr/local/bin/brew shellenv 2>/dev/null)" 2>/dev/null || true
  fi
  if [ "$DRY_RUN" = 1 ]; then
    log "would run: brew bundle --file=$DOTFILES_DIR/Brewfile"
    [ "$NO_GUI" = 0 ] && log "would run: brew bundle --file=$DOTFILES_DIR/Brewfile.gui"
    return
  fi
  log "Installing Brewfile (system tools + fonts)"
  brew bundle --file="$DOTFILES_DIR/Brewfile" || fail "brew bundle (Brewfile)"
  if [ "$NO_GUI" = 0 ] && [ -f "$DOTFILES_DIR/Brewfile.gui" ]; then
    log "Installing Brewfile.gui (GUI apps; skip with --no-gui)"
    brew bundle --file="$DOTFILES_DIR/Brewfile.gui" || warn "brew bundle (Brewfile.gui) had failures"
  fi
}

install_linux() {
  # Coder workspaces are headless Linux — CLI tools only, no GUI apps.
  local SUDO=""; [ "$(id -u)" -ne 0 ] && have sudo && SUDO="sudo"
  local pkgs="curl ca-certificates git tmux mosh zip unzip"

  if [ "$DRY_RUN" = 1 ]; then
    log "would install system deps: $pkgs"
    have rustup || log "would install rustup"
    have herdr  || log "would install herdr"
    have claude || log "would install claude-code"
    return
  fi

  if have apt-get; then
    log "Installing system deps via apt"
    $SUDO apt-get update -y || true
    # shellcheck disable=SC2086
    $SUDO apt-get install -y $pkgs || warn "apt install had failures"
  elif have dnf; then
    log "Installing system deps via dnf"
    # shellcheck disable=SC2086
    $SUDO dnf install -y $pkgs || warn "dnf install had failures"
  elif have apk; then
    log "Installing system deps via apk"
    # shellcheck disable=SC2086
    $SUDO apk add --no-cache $pkgs || warn "apk install had failures"
  else
    warn "No known package manager found; skipping system deps"
  fi

  # rustup — official installer; --no-modify-path since .bashrc adds ~/.cargo/bin.
  if ! have rustup; then
    log "Installing rustup"
    curl -fsSL https://sh.rustup.rs | sh -s -- -y --no-modify-path || \
      warn "rustup install failed"
  fi

  # herdr — not in mise's registry; official installer, skipped if present.
  if ! have herdr; then
    log "Installing herdr"
    curl -fsSL https://herdr.dev/install.sh | bash || warn "herdr install failed"
  fi

  # claude-code — brew cask on macOS; official installer here.
  if ! have claude; then
    log "Installing claude-code"
    curl -fsSL https://claude.ai/install.sh | bash || warn "claude-code install failed"
  fi
}

[ "$DRY_RUN" = 1 ] || mkdir -p "$HOME/.local/bin"

if [ "$(uname -s)" = "Darwin" ]; then
  install_mac
else
  install_linux
fi

# cursor-agent has no brew/apt/mise package — vendor installer on every OS.
if ! have cursor-agent; then
  if [ "$DRY_RUN" = 1 ]; then log "would install cursor-agent"; else
    log "Installing cursor-agent"
    curl -fsS https://cursor.com/install | bash || warn "cursor-agent install failed"
  fi
fi

# ---------------------------------------------------------------------------
# 3. mise — installs the pinned CLI tools from .config/mise/config.toml
#    (jq, kubectl/kubectx/k9s/helm/stern, starship, bat, fzf, neovim, coder,
#    hunk, btop-on-linux). Exact same versions on every machine. ESSENTIAL.
# ---------------------------------------------------------------------------
MISE_PIN="v2026.8.8"  # bump deliberately; the installer checksum-verifies
if ! have mise && [ ! -x "$HOME/.local/bin/mise" ]; then
  if [ "$DRY_RUN" = 1 ]; then log "would install mise $MISE_PIN"; else
    log "Installing mise $MISE_PIN"
    curl -fsSL https://mise.run | MISE_VERSION="$MISE_PIN" sh || fail "mise install"
  fi
fi

MISE_BIN="$(command -v mise || echo "$HOME/.local/bin/mise")"
if [ "$DRY_RUN" = 1 ]; then
  log "would run: mise install (pinned tools from .config/mise/config.toml)"
elif [ -x "$MISE_BIN" ]; then
  log "Installing pinned tools via mise"
  "$MISE_BIN" install --yes || fail "mise tool install"
  # Make the tools visible to the rest of this script.
  export PATH="$HOME/.local/share/mise/shims:$PATH"
else
  fail "mise unavailable; pinned tools not installed"
fi

# ---------------------------------------------------------------------------
# 4. Editor extensions — via whichever editor CLI exists (cursor preferred).
#    Kept out of the Brewfile: a fresh machine has no editor CLI at
#    brew-bundle time, and `vscode` entries only target VS Code anyway.
# ---------------------------------------------------------------------------
EXTENSIONS="akamud.vscode-theme-onedark anysphere.remote-containers anysphere.remote-ssh coder.coder-remote modular-mojotools.vscode-mojo-nightly"
install_extensions() {
  local editor ext
  for editor in cursor code; do
    have "$editor" || continue
    if [ "$DRY_RUN" = 1 ]; then log "would install $editor extensions: $EXTENSIONS"; return; fi
    log "Installing $editor extensions"
    for ext in $EXTENSIONS; do
      "$editor" --install-extension "$ext" >/dev/null 2>&1 || warn "extension $ext failed"
    done
    return
  done
  log "No cursor/code CLI on PATH; skipping editor extensions"
}
install_extensions

# ---------------------------------------------------------------------------
# 5. NVIDIA Nsight profilers (nsys / ncu) for GPU workspaces — best-effort.
#    Usually shipped with the CUDA toolkit; try the apt packages if missing.
#    .bashrc picks them up from /usr/local/cuda and /opt/nvidia.
# ---------------------------------------------------------------------------
install_nsight() {
  if have nsys && have ncu; then
    log "Nsight tools already present (nsys, ncu)"
    return
  fi
  have apt-get || return 0
  if [ "$DRY_RUN" = 1 ]; then log "would try installing Nsight (nsys, ncu) via apt"; return; fi
  local SUDO=""; [ "$(id -u)" -ne 0 ] && have sudo && SUDO="sudo"
  local pkg
  for pkg in nsight-systems-cli nsight-systems nsight-compute; do
    $SUDO apt-get install -y "$pkg" >/dev/null 2>&1 && log "installed $pkg" || true
  done
  have nsys || log "nsys still missing — needs the NVIDIA CUDA apt repo or a manual Nsight Systems install"
  have ncu  || log "ncu still missing — needs the NVIDIA CUDA apt repo or a manual Nsight Compute install"
}
install_nsight

# ---------------------------------------------------------------------------
# 6. Pre-download neovim plugins so the first `nvim` isn't a plugin storm.
#    lazy.nvim bootstraps itself; `Lazy! restore` pins to lazy-lock.json.
# ---------------------------------------------------------------------------
if [ "$DRY_RUN" = 1 ]; then
  log "would pre-sync neovim plugins"
elif have nvim; then
  log "Pre-syncing neovim plugins"
  nvim --headless "+Lazy! restore" +qa >/dev/null 2>&1 || \
    log "nvim plugin pre-sync failed (plugins will install on first launch)"
fi

# ---------------------------------------------------------------------------
# Result
# ---------------------------------------------------------------------------
if [ "${#FAILURES[@]}" -gt 0 ]; then
  warn "Completed with ${#FAILURES[@]} essential failure(s):"
  for f in "${FAILURES[@]}"; do warn "  - $f"; done
  exit 1
fi
log "Done. Open a new shell to pick up the changes."

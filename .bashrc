# ---------------------------------------------------------------------------
# PATH — runs for every shell (interactive or not). Coder opens non-login
# shells that skip .bash_profile, so all tool paths live here, duplicate-safe.
# ---------------------------------------------------------------------------
add_path() {
  [ -d "$1" ] || return 0
  case ":$PATH:" in
    *":$1:"*) ;;
    *) export PATH="$1:$PATH" ;;
  esac
}

add_path "$HOME/.local/bin"              # vendor installers (claude, herdr, ...)
add_path "$HOME/.local/share/mise/shims" # pinned CLI tools (see .config/mise)
add_path "$HOME/.cargo/bin"              # rustup toolchains

# NVIDIA CUDA + Nsight profilers (nsys, ncu) — only where they exist
add_path /usr/local/cuda/bin
for _nv in /opt/nvidia/nsight-systems/*/bin /opt/nvidia/nsight-compute/*; do
  add_path "$_nv"
done
unset _nv

# ---------------------------------------------------------------------------
# Interactive-only setup: prompt, keybindings, aliases
# ---------------------------------------------------------------------------
case $- in
  *i*) ;;
  *) return 0 2>/dev/null || exit 0 ;;
esac

# mise: version switching hooked into the prompt (shims above cover scripts)
command -v mise >/dev/null 2>&1 && eval "$(mise activate bash)"

# fzf keybindings: git-install location first, then Debian/Ubuntu apt location
if [ -f ~/.fzf.bash ]; then
  source ~/.fzf.bash
elif [ -f /usr/share/doc/fzf/examples/key-bindings.bash ]; then
  source /usr/share/doc/fzf/examples/key-bindings.bash
fi

# dotfiles alias works for both layouts: bare repo (this Mac) and the
# normal clone `coder dotfiles` leaves at ~/.dotfiles (Coder workspaces).
if [ -d "$HOME/.dotfiles/.git" ]; then
  alias dotfiles='git -C $HOME/.dotfiles'
else
  alias dotfiles='git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME'
fi
alias cla='claude'
command -v starship >/dev/null 2>&1 && eval "$(starship init bash)"

# cd into modular folder
alias mod='cd ~/modular'

# rename the current herdr workspace: hrename "new name"
hrename() {
  if [ -z "$HERDR_WORKSPACE_ID" ]; then
    echo "hrename: not inside a herdr workspace" >&2
    return 1
  fi
  if [ -z "$1" ]; then
    echo "usage: hrename <new name>" >&2
    return 1
  fi
  herdr workspace rename "$HERDR_WORKSPACE_ID" "$*"
}

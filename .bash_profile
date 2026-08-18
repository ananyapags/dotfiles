# Source local env (rustup/uv) if present
[ -f "$HOME/.local/bin/env" ] && . "$HOME/.local/bin/env"

if [ -f ~/.bashrc ]; then
  . ~/.bashrc
fi

# macOS Homebrew rustup — only where it exists
[ -d "/opt/homebrew/opt/rustup/bin" ] && export PATH="/opt/homebrew/opt/rustup/bin:$PATH"
# macOS user-level pip installs — only where it exists
[ -d "$HOME/Library/Python/3.9/bin" ] && export PATH="$HOME/Library/Python/3.9/bin:$PATH"

# All shared PATH entries (~/.local/bin, mise shims, cargo, CUDA/Nsight) live
# in .bashrc so Coder's non-login shells get them too.

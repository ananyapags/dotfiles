# Source local env (rustup/uv) if present
[ -f "$HOME/.local/bin/env" ] && . "$HOME/.local/bin/env"
export PATH="$HOME/.local/bin:$PATH"

if [ -f ~/.bashrc ]; then
  . ~/.bashrc
fi

# macOS Homebrew rustup — only where it exists
[ -d "/opt/homebrew/opt/rustup/bin" ] && export PATH="/opt/homebrew/opt/rustup/bin:$PATH"

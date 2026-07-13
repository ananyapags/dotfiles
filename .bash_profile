. "$HOME/.local/bin/env"
export PATH="$HOME/.local/bin:$PATH"

if [ -f ~/.bashrc ]; then
  . ~/.bashrc
fi

eval "$(starship init bash)"
export PATH="/opt/homebrew/opt/rustup/bin:$PATH"

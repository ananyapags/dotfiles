# Source local env (rustup/uv) if present
[ -f "$HOME/.local/bin/env" ] && . "$HOME/.local/bin/env"
export PATH="$HOME/.local/bin:$PATH"

if [ -f ~/.bashrc ]; then
  . ~/.bashrc
fi

# macOS Homebrew rustup — only where it exists
[ -d "/opt/homebrew/opt/rustup/bin" ] && export PATH="/opt/homebrew/opt/rustup/bin:$PATH"
export PATH="$HOME/Library/Python/3.9/bin:$PATH"
export PATH="$HOME/.cargo/bin:$PATH"

# NVIDIA CUDA + Nsight profilers (nsys, ncu) — only where they exist
[ -d "/usr/local/cuda/bin" ] && export PATH="/usr/local/cuda/bin:$PATH"
for _nv in /opt/nvidia/nsight-systems/*/bin /opt/nvidia/nsight-compute/*; do
  [ -d "$_nv" ] && export PATH="$_nv:$PATH"
done
unset _nv

[ -f ~/.fzf.bash ] && source ~/.fzf.bash
alias dotfiles='git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME'
command -v starship >/dev/null 2>&1 && eval "$(starship init bash)"

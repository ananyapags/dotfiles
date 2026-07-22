[ -f ~/.fzf.bash ] && source ~/.fzf.bash
alias dotfiles='git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME'
alias cla='claude'
command -v starship >/dev/null 2>&1 && eval "$(starship init bash)"

# cd into modular folder
alias mod='cd ~/modular'

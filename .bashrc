[ -f ~/.fzf.bash ] && source ~/.fzf.bash
alias dotfiles='git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME'
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

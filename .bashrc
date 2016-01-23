echo Loading ~/.bashrc

# Environment Variables
export CLICOLOR=1
export LSCOLORS=ExFxBxDxCxegedabagacad

# Local variables (used in this script only)
platform="unknown"

# Aliases
alias glga="git log --graph --abbrev-commit --date=short --pretty=format:\
'%C(yellow)%h%Creset %C(bold blue)(%an)%Creset%C(yellow)%d%Creset %s %Cgreen<%cr, %ar>%Creset'"
alias myprocs="ps aux | grep \"^dpopes\" | grep -v grep | grep -v \"^ps aux\"" 
alias irclogs="cd ~/Library/Application\ Support/Adium\ 2.0/Users/Default/Logs/IRC.$USER"



alias ls="ls -GFh"

# Shell Customizations
export PS1="\[\033[36m\]\u\[\033[m\]@\[\033[32m\]\h:\[\033[33;1m\]\w\[\033[m\]\r\n$ "
#PS1="\\u@\\h:\\w\\r\\n$ "

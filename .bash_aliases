# Only echo the text if it is an interactive shell (e.g. a real human logging in)
# Otherwise, some automated tasks may fail when they receive the unexpected text
# e.g. rsync, sshfs type things, etc...
cprint() {
    if [[ $- == *i* ]]; then
        echo $*
    fi
}

cprint "Loading ~/.bash_aliases"
shopt -s expand_aliases 

alias glga="git log --graph --abbrev-commit --date=short --pretty=format:\
'%C(yellow)%h%Creset %C(bold blue)(%an)%Creset%C(yellow)%d%Creset %s %Cgreen<%cr, %ar>%Creset'"
alias git-root='pushd . && cd $(git rev-parse --show-cdup)'
alias grep="grep --color=auto"
alias myprocs="ps aux | grep -v grep | grep -v \"ps aux\" | grep -P \"^$(whoami)\s+\d+\""
alias ..="cd .."
alias :q="echo 'This is not git, dummy!'"
alias tmux="tmux2"
alias agenttmux="agenttmux2"

# Hack to allow aliases to be honored when using sudo
# http://askubuntu.com/questions/22037/aliases-not-available-when-using-sudo
alias sudo="sudo "

platform=$(uname)
mac=false
linux=false
unknown=false

if [ $platform = 'Darwin' ]; then
    platform='osx'
    mac=true
elif [ $platform = 'Linux' ]; then
    platform='linux'
    linux=true
else
    platform='unknown'
    unknown=true
fi

if [ $mac = true ]; then
    # On mac, the ls alias to make the colors look pretty is different than on linux
    alias ls="ls -GFh"

    # On mac, this is where the Adium irc logs go.  It's an annoying path to remember otherwise.
    alias irclogs="cd ~/Library/Application\ Support/Adium\ 2.0/Users/Default/Logs/IRC.$USER"
fi

if [ $linux = true ]; then
    # On linux, the ls alias to make the colors look pretty is different than on mac
    alias ls='ls --color=tty -Fh'

    # Ignore disabled test suites if we're using testify.  Ain't nobody got time for dat!
    alias testify='testify -x disabled'

    # Trick to interop with MAC clipboard while on work linux environment
    alias pbcopy="ssh -A 10.255.55.243 pbcopy > /dev/null 2>&1"
fi


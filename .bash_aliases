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

# Give a nice tree structure of the git log
alias glga="git log --graph --abbrev-commit --date=short --pretty=format:\
'%C(yellow)%h%Creset %C(bold blue)(%an)%Creset%C(yellow)%d%Creset %s %Cgreen<%cr, %ar>%Creset'"

# Shortcut to get to the root of the repository you're currently in
alias git-root='pushd . > /dev/null && cd $(git rev-parse --show-cdup)'

# Automatically add match highlighting to grep
alias grep="grep --color=auto"

# Shortcut to see the procs you're running
alias myprocs="ps aux | grep -v grep | grep -v \"ps aux\" | grep -P \"^$(whoami)\s+\d+\""

# Shortcut for laziness
alias ..="cd .."

# Make yourself laugh at yourself for being dumb
alias :q="echo 'This is not vim, dummy!'"

# Prevent a typo that occurs far too often
alias gt=git

# Puppet-bundle exec rake spec
alias pbers="puppet-bundle exec rake spec"

# Check if we have two separate copies of tmux (1.x and 2.x) and if so, alias tmux to the tmux2 version
which tmux2 > /dev/null
if [ $? = 0 ]; then
    alias tmux="tmux2"
    alias agenttmux="agenttmux2"
fi

# Check for availability of vim8
which vim8 > /dev/null
if [ $? = 0 ]; then
    alias vi="vim"
    alias vim="vim8"
fi

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
fi


#!/bin/bash

# Only echo the text if it is an interactive shell (e.g. a real human logging in)
# Otherwise, some automated tasks may fail when they receive the unexpected text
# e.g. rsync, sshfs type things, etc...
cprint() {
    if [ ! -z "$PS1" ]; then
        echo $*
    fi
}

cprint "Loading ~/.bashrc"

# Figure out what kind of machine we're running on,
# since some customizations are different on mac vs linux
platform=$(uname)
mac=false
linux=false
unknown=false

if [ $platform = 'Darwin' ]; then
    cprint "uname==>$platform so we must be running on a mac"
    platform='osx'
    mac=true
elif [ $platform = 'Linux' ]; then
    cprint "uname==>$platform so we must be running on a linux machine"
    platform='linux'
    linux=true
else
    cprint "uname==>$platform so we don't know what state we're in!"
    platform='unknown'
    unknown=true
fi

# Colors

# Reset
Color_Off='\e[0m'       # Text Reset

# Regular Colors
Black='\e[0;30m'        # Black
Red='\e[0;31m'          # Red
Green='\e[0;32m'        # Green
Yellow='\e[0;33m'       # Yellow
Blue='\e[0;34m'         # Blue
Purple='\e[0;35m'       # Purple
Cyan='\e[0;36m'         # Cyan
White='\e[0;37m'        # White
LightBlue='\e[0;39m'    # Light Blue

# Bold
BBlack='\e[1;30m'       # Black
BRed='\e[1;31m'         # Red
BGreen='\e[1;32m'       # Green
BYellow='\e[1;33m'      # Yellow
BBlue='\e[1;34m'        # Blue
BPurple='\e[1;35m'      # Purple
BCyan='\e[1;36m'        # Cyan
BWhite='\e[1;37m'       # White
BLightBlue='\e[1;39m'   # Light Blue

# Underline
UBlack='\e[4;30m'       # Black
URed='\e[4;31m'         # Red
UGreen='\e[4;32m'       # Green
UYellow='\e[4;33m'      # Yellow
UBlue='\e[4;34m'        # Blue
UPurple='\e[4;35m'      # Purple
UCyan='\e[4;36m'        # Cyan
UWhite='\e[4;37m'       # White
ULightBlue='\e[4;39m'   # Light Blue

# Background
On_Black='\e[40m'       # Black
On_Red='\e[41m'         # Red
On_Green='\e[42m'       # Green
On_Yellow='\e[43m'      # Yellow
On_Blue='\e[44m'        # Blue
On_Purple='\e[45m'      # Purple
On_Cyan='\e[46m'        # Cyan
On_White='\e[47m'       # White
On_LightBlue='\e[49m' # Light Blue

FancyX='\342\234\227'
Checkmark='\342\234\223'

# Environment Variables
export CLICOLOR=1
export LSCOLORS=ExFxBxDxCxegedabagacad
export PATH="/usr/local/sbin:$PATH"

# Aliases
alias glga="git log --graph --abbrev-commit --date=short --pretty=format:\
'%C(yellow)%h%Creset %C(bold blue)(%an)%Creset%C(yellow)%d%Creset %s %Cgreen<%cr, %ar>%Creset'"
alias grep="grep --color=auto"
alias myprocs="ps aux | grep -v grep | grep -v \"ps aux\" | grep -P \"^$(whoami)\s+\d+\""
alias ..="cd .."

if [ $mac = true ]; then
    # On mac, the ls alias to make the colors look pretty is different than on linux
    alias ls="ls -GFh"

    # On mac, this is where the Adium irc logs go.  It's an annoying path to remember otherwise.
    alias irclogs="cd ~/Library/Application\ Support/Adium\ 2.0/Users/Default/Logs/IRC.$USER"

    # Shell Customizations should basically only need to happen on the mac.
    # The linux boxes i typically use already have them set up
    export PS1="\[$BBlue\]\u@\[$BGreen\]\h:\[$BYellow\]\w\[$BCyan\]\$(__git_ps1)\r\n\[$Color_Off\]\\$ "
fi

if [ $linux = true ]; then
    # On linux, the ls alias to make the colors look pretty is different than on mac
    alias ls='ls --color=tty -Fh'

    # Ignore disabled test suites if we're using testify.  Ain't nobody got time for dat!
    alias testify='testify -x disabled'

    # The linux boxes i typically use already has a PS1 setup.  However, i prefer the additional newline
    #export PS1="\[$BBlue\]\u@\[$BGreen\]\h:\[$BYellow\]\w\[$BCyan\]\$(__git_ps1)\r\n\[$Color_Off\]\\$ "
    export PS1="$PS1\n\\$ "
fi

# Check if brew is installed
which brew > /dev/null
if [ $? = 0 ]; then
    # Since brew is installed, check for a few things that we like to use
    # such as bash completion and git prompt completion

    brew_path=$(brew --prefix)
    git_prompt=$brew_path/etc/bash_completion.d/git-prompt.sh
    if [ ! -f $git_prompt ]; then
        cprint "Couldn't find bash-git-prompt script at $git_prompt --> Installing it now..."
        brew install bash-git-prompt
    else
        cprint "Found bash-git-prompt script at $git_prompt --> Sourcing it now..."
        . $git_prompt
    fi

    bash_completion=$brew_path/etc/bash_completion
    if [ ! -f $bash_completion ]; then
        cprint "Couldn't find bash_completion script --> Installing it now..."
        brew install bash-completion
    else
        cprint "Found bash-completion script at $bash_completion --> Sourcing it now..."
      . $bash_completion
    fi
fi

# If the environment doesn't already have the __git_ps1 alias set up, then explicitly set it
if [ ! type __git_ps1 &> /dev/null ]; then
  alias __git_ps1="git branch 2>/dev/null | grep '*' | sed 's/* \(.*\)/(\1)/'"
fi

# Try to re-mount the dev35-devc dpopes home directory (may fail if already mounted, but doesn't hurt)
# This is too specific to my work dev laptop.  Consider removing it or addressing it some other way
sshfs -o reconnect dpopes@dev35-devc:/nail/home/dpopes/ ~/dev/dev35-devc 2>/dev/null
# Keeping the 'unmount' command here for reference:
# diskutil unmountDisk force /Volumes/DISK_NAME

# Add convenience script for printing out "where you are"
whereami() {
  directory="/nail/etc/"
  counter=1
  for f in runtimeenv ecosystem superregion region habitat; do
    echo $f:
    for (( c=0; c<$counter; c++ )); do
      printf ">"
    done
    ((counter++))
    head -1 $directory/$f
    if [ $f != 'habitat' ]; then
      echo
    fi
  done
  echo hostname:
  for (( c=0; c<$counter; c++ )); do
    printf ">"
  done
  hostname
}

echo -ne "\033]0;${USER}@${HOSTNAME}: ${PWD}\007"

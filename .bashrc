#!/bin/bash

# Only echo the text if it is an interactive shell (e.g. a real human logging in)
# Otherwise, some automated tasks may fail when they receive the unexpected text
# e.g. rsync, sshfs type things, etc...
cprint() {
    if [[ $- == *i* ]]; then
        echo $*
    fi
}

# Also only download tools and such if it is an interactive shell (e.g. a real human logging in)
# Otherwise, some automated tasks may end up taking longer than they should
# e.g. rsync, sshfs type things, etc...
ccurl() {
    if [[ $- == *i* ]]; then
        curl $*
    fi
}

# Also only download tools and such if it is an interactive shell (e.g. a real human logging in)
# Otherwise, some automated tasks may end up taking longer than they should
# e.g. rsync, sshfs type things, etc...
cgit() {
    if [[ $- == *i* ]]; then
        git $*
    fi
}

# Enable XON/XOFF on to make Ctrl+s work to search forward in history
if [[ $- == *i* ]]; then
    stty -ixon
fi

color_prompt=yes
cprint "Loading ~/.bashrc"

# Set up auto-completion in python interactive shell
export PYTHONSTARTUP=~/.pythonrc

# Disable creation of .pyc files
export PYTHONDONTWRITEBYTECODE=1

# Set vi emulation mode in bash prompts
set -o vi

# Set vi as the default editor
export EDITOR=vi

# Figure out what kind of machine we're running on,
# since some customizations are different on mac vs linux
platform=$(uname)
mac=false
linux=false
unknown=false

if [[ $platform = 'Darwin' ]]; then
    #cprint "uname==>$platform so we must be running on a mac"
    platform='osx'
    mac=true
elif [[ $platform = 'Linux' ]]; then
    #cprint "uname==>$platform so we must be running on a linux machine"
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
export GOPATH=$(echo ~/go)
export GOBIN=${GOPATH}/bin
export PATH=${PATH}:${GOBIN}
export PAGER=less

mkdir -p ${GOPATH}

# Bash history customizations

# Avoid duplicates
export HISTCONTROL=ignoredups:erasedups

# unlimited history (default is 10000, negative means disable)
export HISTSIZE=1000000

# unlimited history (default is 10000, negative means disable)
export HISTFILESIZE=1000000

# Configure history in "append" mode
shopt -s histappend

# Force commands to flush to bash history file after each command
export PROMPT_COMMAND="history -a"
export PROMPT_COMMAND='if [ -x /usr/bin/aactivator ]; then  eval "$(/usr/bin/aactivator)"; fi'"; $PROMPT_COMMAND"

# Aliases
# You may want to put all your additions into a separate file like
# ~/.bash_aliases, instead of adding them here directly.

if [[ -f ~/.bash_aliases ]]; then
    . ~/.bash_aliases
fi

if [[ $mac = true ]]; then

    # Disable the "zomg you should use zsh" nag message
    export BASH_SILENCE_DEPRECATION_WARNING=1

    export PS1="\[$BBlue\]\u@\[$BGreen\]\h:\[$BYellow\]\w\[$BCyan\] \$(__git_ps1)"

    # On mac, change the default wifi login screen application so that it opens in the regular browser
    CAPTIVE_PORTAL_ACTIVE=$(defaults read /Library/Preferences/SystemConfiguration/com.apple.captive.control Active)

    if [[ $? -ne 0 ]] || [[ $CAPTIVE_PORTAL_ACTIVE -eq 1 ]]; then
        cprint "Disabling com.apple.captive.control so that the default wifi login screen app is a regular browser..."
        sudo defaults write /Library/Preferences/SystemConfiguration/com.apple.captive.control Active -boolean false
    fi

    # On mac, by default, holding down a key brings up the alternate character menu
    # Change it so that it just sends the repeated keystrokes
    PRESS_AND_HOLD_ENABLED=$(defaults read NSGlobalDomain ApplePressAndHoldEnabled)

    if [[ $? -ne 0 ]] || [[ $PRESS_AND_HOLD_ENABLED -eq 1 ]]; then
        defaults write NSGlobalDomain ApplePressAndHoldEnabled -bool false
    fi

    SHOW_ALL_FILES=$(defaults read com.apple.Finder AppleShowAllFiles)
    if [[ $? -ne 0 ]] || [[ $SHOW_ALL_FILES -eq 1 ]]; then
        defaults write com.apple.Finder AppleShowAllFiles -bool true
    fi

    # Better / actually usable key repeat values. These don't really need to be in bashrc and they
    # require a logout + login to take effect, but putting these here for my own reference in the future
    # https://apple.stackexchange.com/a/83923/174038
    defaults write -g InitialKeyRepeat -int 12 # normal minimum is 15 (225 ms)
    defaults write -g KeyRepeat -int 1 # normal minimum is 2 (30 ms)

    # Try to pre-emptively add the ssh key(s) to the trust store
    ssh-add -l -q | grep -q "The agent has no identities"
    if [[ $? -eq 0 ]]; then
        ssh-add -k
    fi
    # Check if brew is installed
    which brew > /dev/null
    if [[ $? = 0 ]]; then
        # Since brew is installed, check for a few things that we like to use
        # such as bash completion

        brew_path=$(brew --prefix)

        bash_completion=$brew_path/etc/bash_completion
        if [[ ! -f $bash_completion ]]; then
            cprint "Couldn't find bash_completion script --> Installing it now..."
            brew install bash-completion
        fi
        cprint "Loading $bash_completion"
      . $bash_completion
    fi

    # Get the git completion
    git_completion=/Library/Developer/CommandLineTools/usr/share/git-core/git-completion.bash
    if [[ ! -f $git_completion ]]; then
        cprint "Couldn't find git_completion script $git_completion"
    fi
    cprint "Loading $git_completion"
  . $git_completion
fi

if [[ $linux = true ]]; then
    # Add puppet role information if it exists
    ROLE=unknown
    if [[ -f /nail/etc/role ]]; then
        ROLE=$(cat /nail/etc/role)
        #PS1+="\$(echo -n \[$Color_Off\] \($(cat /nail/etc/role)\) )"
    fi

    if grep -q git_ps1 <<<$PS1
    then
        export PS1="\[$BBlue\]\u@\[$BGreen\]\h \[$BPurple\]($ROLE)\[$Color_Off\]:\[$BYellow\]\w\[$BCyan\]\$(__git_ps1)"
    else
        export PS1="\[$BBlue\]\u@\[$BGreen\]\h \[$BPurple\]($ROLE)\[$Color_Off\]:\[$BYellow\]\w\[$BCyan\]\$(__git_ps1)"
    fi

    # enable bash completion for various things in interactive shells
    for file in /etc/bash_completion /etc/bash_completion.d/git; do
        if [[ -f $file ]] && ! shopt -oq posix; then
            . $file
        fi
    done
fi

PS1+="\[$BPurple\] [\t]"

PS1+="\$(RET=\$?; if [[ \$RET != 0 ]]; then echo -n \"\[$BRed\] $FancyX \"; else echo -n \"\[$BGreen\] $Checkmark\"; fi)\[$Color_Off\]\r\n\\$ "

# If the environment doesn't already have the __git_ps1 alias set up, then explicitly set it
type __git_ps1 &> /dev/null
if [[ $? != 0  ]]; then
  alias __git_ps1="git branch 2>/dev/null | grep '*' | sed 's/* \(.*\)/(\1)/'"
fi

# Try to set up some handy git aliases

# .gitignore
git config --global --get core.excludesfile >/dev/null
if [[ $? != 0 ]]; then
    git config --global core.excludesfile ~/.gitignore
fi

# `git my` alias
git config --global --get alias.my >/dev/null
if [[ $? != 0 ]]; then
    git config --global alias.my "log --author=$(whoami)"
fi

# use diff3 format for merge conflicts
git config --global --get merge.conflictstyle >/dev/null
if [[ $? != 0 ]]; then
    git config --global merge.conflictstyle diff3
fi

# Set defaults for git author info
git config --global --get user.email > /dev/null
if [[ $? != 0 ]]; then
    git config --global user.email "danielpops@gmail.com"
fi
git config --global --get user.name > /dev/null
if [[ $? != 0 ]]; then
    git config --global user.name "Daniel Popescu"
fi

# Vim related stuff
vundle_vim_folder=~/.vim/bundle/Vundle.vim
if [[ ! -d $vundle_vim_folder ]]; then
    cprint "Vundle not found. Installing it now..."
    mkdir -p $vundle_vim_folder
    cgit clone https://github.com/VundleVim/Vundle.vim.git $vundle_vim_folder > /dev/null 2>&1
else
    cgit -C $vundle_vim_folder pull > /dev/null 2>&1
fi

# If the azure completion file exists, load it
if [[ ! -f ~/.azure.completion.sh ]]; then
    which azure > /dev/null
    if [[ $? = 0 ]]; then
        azure --completion > ~/.azure.completion.sh
        if [[ $? = 0 ]]; then
            source ~/.azure.completion.sh
        fi
        rm -rf ~/.azure.completion.sh
    fi
fi

# If the aws completion file exists, load it
which aws_completer > /dev/null
if [[ $? = 0 ]]; then
    AWS_COMPLETER=$(which aws_completer)
else
    if [[ -f /opt/venvs/aws-cli/bin/aws_completer ]]; then
        AWS_COMPLETER=/opt/venvs/aws-cli/bin/aws_completer
    fi
fi

if [[ ! -z $AWS_COMPLETER ]]; then
    complete -C "$AWS_COMPLETER" aws
fi

# Tmux Plugin Manager
tpm_folder=~/.tmux/plugins/tpm
if [[ ! -d $tpm_folder ]]; then
    cprint "Tmux Plugin Manager not found. Installing it now..."
    mkdir -p $tpm_folder
    cgit clone https://github.com/tmux-plugins/tpm $tpm_folder > /dev/null 2>&1
else
    cgit -C $tpm_folder pull > /dev/null 2>&1
fi

cprint -ne "\033]0;${USER}@${HOSTNAME}: ${PWD}\007"

__expand_tilde_by_ref() {
  printf ''
}

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
export PAGER=less

# Bash history customizations

# Avoid duplicates
export HISTCONTROL=ignoredups:erasedups

# big big history (default is 10000)
export HISTSIZE=100000

# big big history (default is 10000)
export HISTFILESIZE=100000

# Configure history in "append" mode
shopt -s histappend

# Force commands to flush to bash history file after each command
export PROMPT_COMMAND="history -a"

# Aliases
# You may want to put all your additions into a separate file like
# ~/.bash_aliases, instead of adding them here directly.

if [[ -f ~/.bash_aliases ]]; then
    . ~/.bash_aliases
fi

if [[ $mac = true ]]; then
    export PS1="\[$BBlue\]\u@\[$BGreen\]\h:\[$BYellow\]\w\[$BCyan\]\$(__git_ps1)\[$BPurple\] [\t]"

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
fi

if [[ $linux = true ]]; then
    if grep -q git_ps1 <<<$PS1
    then
        export PS1="\[$BBlue\]\u@\[$BGreen\]\h:\[$BYellow\]\w\[$BCyan\]\$(__git_ps1)\[$BPurple\] [\t]"
    else
        export PS1="\[$BBlue\]\u@\[$BGreen\]\h:\[$BYellow\]\w\[$BCyan\]\$(__git_ps1)\[$BPurple\] [\t]"
    fi

    # enable bash completion in interactive shells
    if [[ -f /etc/bash_completion ]] && ! shopt -oq posix; then
        . /etc/bash_completion
    fi
fi

PS1+="\$(RET=\$?; if [[ \$RET != 0 ]]; then echo -n \"\[$BRed\] $FancyX \"; else echo -n \"\[$BGreen\] $Checkmark\"; fi)\[$Color_Off\]\r\n\\$ "

# Check if brew is installed
which brew > /dev/null
if [[ $? = 0 ]]; then
    # Since brew is installed, check for a few things that we like to use
    # such as bash completion and git prompt completion

    brew_path=$(brew --prefix)
    git_prompt=$brew_path/etc/bash_completion.d/git-prompt.sh
    if [[ ! -f $git_prompt ]]; then
        cprint "Couldn't find bash-git-prompt script at $git_prompt --> Installing it now..."
        brew install bash-git-prompt
    fi
    cprint "Loading $git_prompt"
    . $git_prompt

    bash_completion=$brew_path/etc/bash_completion
    if [[ ! -f $bash_completion ]]; then
        cprint "Couldn't find bash_completion script --> Installing it now..."
        brew install bash-completion
    fi
    cprint "Loading $bash_completion"
  . $bash_completion
fi

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
# Set up pathogen and syntastic, if they don't already exist:

pathogen_file=~/.vim/autoload/pathogen.vim
if [[ ! -f $pathogen_file ]]; then
    cprint "Pathogen not found. Installing it now..."
    mkdir -p ~/.vim/autoload ~/.vim/bundle && \
    ccurl -LSso $pathogen_file https://raw.githubusercontent.com/tpope/vim-pathogen/master/autoload/pathogen.vim
fi

# Systastic caused too many problems... revisit later!
#syntastic_folder=~/.vim/bundle/syntastic
#if [[ ! -d $syntastic_folder ]]; then
#    cprint "Systastic not found. Installing it now..."
#    mkdir -p $syntastic_folder
#    git clone https://github.com/scrooloose/syntastic.git $syntastic_folder > /dev/null 2>&1
#fi

puppet_vim_folder=~/.vim/bundle/vim-puppet
if [[ ! -d $puppet_vim_folder ]]; then
    cprint "Puppet-vim not found. Installing it now..."
    mkdir -p $puppet_vim_folder
    cgit clone https://github.com/rodjek/vim-puppet.git $puppet_vim_folder > /dev/null 2>&1
else
    cgit -C $puppet_vim_folder pull > /dev/null 2>&1
fi

docker_vim_folder=~/.vim/bundle/Dockerfile
if [[ ! -d $docker_vim_folder ]]; then
    cprint "Dockerfile.vim not found. Installing it now..."
    mkdir -p $docker_vim_folder
    cgit clone https://github.com/ekalinin/Dockerfile.vim.git $docker_vim_folder > /dev/null 2>&1
else
    cgit -C $docker_vim_folder pull > /dev/null 2>&1
fi

jedi_vim_folder=~/.vim/bundle/jedi-vim
if [[ ! -d $jedi_vim_folder ]]; then
    cprint "jedi-vim not found. Installing it now..."
    mkdir -p $jedi_vim_folder
    cgit clone --recursive https://github.com/davidhalter/jedi-vim.git $jedi_vim_folder > /dev/null 2>&1
else
    cgit -C $jedi_vim_folder pull > /dev/null 2>&1
fi

terraform_vim_folder=~/.vim/bundle/vim-terraform
if [[ ! -d $terraform_vim_folder ]]; then
    cprint "Terraform-vim not found. Installing it now..."
    mkdir -p $terraform_vim_folder
    cgit clone https://github.com/hashivim/vim-terraform.git $terraform_vim_folder > /dev/null 2>&1
else
    cgit -C $terraform_vim_folder pull > /dev/null 2>&1
fi

logstash_vim_folder=~/.vim/logstash.vim
if [[ ! -d $logstash_vim_folder ]]; then
    cprint "logstash.vim not found. Installing it now..."
    mkdir -p $logstash_vim_folder
    cgit clone https://github.com/robbles/logstash.vim $logstash_vim_folder > /dev/null 2>&1
    mkdir -p ~/.vim/syntax > /dev/null 2>&1
    mkdir -p ~/.vim/ftdetect > /dev/null 2>&1
    ln -f -s $logstash_vim_folder/syntax/logstash.vim $logstash_vim_folder/../syntax/logstash.vim
    ln -f -s $logstash_vim_folder/ftdetect/logstash.vim $logstash_vim_folder/../ftdetect/logstash.vim
else
    cgit -C $logstash_vim_folder pull > /dev/null 2>&1
fi

if [[ ! -f ~/.vim/syntax/groovy.vim ]]; then
    cprint "groovy.vim not found. Installing it now..."
    ccurl -s -L --max-time 5 -o ~/.vim/syntax/groovy.vim http://www.vim.org/scripts/download_script.php?src_id=2926
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

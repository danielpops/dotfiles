# Only echo the text if it is an interactive shell (e.g. a real human logging in)
# Otherwise, some automated tasks may fail when they receive the unexpected text
# e.g. rsync, sshfs type things, etc...
if [ ! -z "$PS1" ]; then
    echo Loading ~/.bashrc
fi

# Figure out what kind of machine we're running on,
# since some customizations are different on mac vs linux
platform=$(uname)
mac=false
linux=false
unknown=false

if [ $platform=='Darwin' ]; then
    platform='osx'
    mac=true
elif [ $platform=='Linux' ]; then
    platform='linux'
    linux=true
else
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

# High Intensity
IBlack='\e[0;90m'       # Black
IRed='\e[0;91m'         # Red
IGreen='\e[0;92m'       # Green
IYellow='\e[0;93m'      # Yellow
IBlue='\e[0;94m'        # Blue
IPurple='\e[0;95m'      # Purple
ICyan='\e[0;96m'        # Cyan
IWhite='\e[0;97m'       # White
ILightBlue='\e[0;99m'   # Light Blue

# Bold High Intensity
BIBlack='\e[1;90m'      # Black
BIRed='\e[1;91m'        # Red
BIGreen='\e[1;92m'      # Green
BIYellow='\e[1;93m'     # Yellow
BIBlue='\e[1;94m'       # Blue
BIPurple='\e[1;95m'     # Purple
BICyan='\e[1;96m'       # Cyan
BIWhite='\e[1;97m'      # White
BILightBlue='\e[1;99m'  # Light Blue

# High Intensity backgrounds
On_IBlack='\e[0;100m'   # Black
On_IRed='\e[0;101m'     # Red
On_IGreen='\e[0;102m'   # Green
On_IYellow='\e[0;103m'  # Yellow
On_IBlue='\e[0;104m'    # Blue
On_IPurple='\e[0;105m'  # Purple
On_ICyan='\e[0;106m'    # Cyan
On_LightBlue='\e[0:110m' # Light Blue

FancyX='\342\234\227'
Checkmark='\342\234\223'

# Environment Variables
export CLICOLOR=1
export LSCOLORS=ExFxBxDxCxegedabagacad
export PATH="/usr/local/sbin:$PATH"

# Local variables (used in this script only)
platform="unknown"

# Aliases
alias glga="git log --graph --abbrev-commit --date=short --pretty=format:\
'%C(yellow)%h%Creset %C(bold blue)(%an)%Creset%C(yellow)%d%Creset %s %Cgreen<%cr, %ar>%Creset'"
alias grep="grep --color=auto"
alias myprocs="ps aux | grep -v grep | grep -v \"^ps aux\" | grep -P \"^$(whoami)\s+\d+\""
alias ..="cd .."
#alias __git_ps1="git branch 2>/dev/null | grep '*' | sed 's/* \(.*\)/(\1)/'"

if [ $mac == true ]; then
    # On mac, the ls alias to make the colors look pretty is different than on linux
    alias ls="ls -GFh"

    # On mac, this is where the Adium irc logs go.  It's an annoying path to remember otherwise.
    alias irclogs="cd ~/Library/Application\ Support/Adium\ 2.0/Users/Default/Logs/IRC.$USER"
fi

if [ $linux == true ]; then
    # On linux, the ls alias to make the colors look pretty is different than on mac
    alias ls='ls --color=tty -Fh'

    # Ignore disabled test suites if we're using testify.  Ain't nobody got time for dat!
    alias testify='testify -x disabled'
fi

# Check if brew is installed
which brew > /dev/null
if [ $? == 0 ]; then
    # Since brew is installed, check for a few things that we like to use
    # such as bash completion and git prompt completion

    brew_path=$(brew --prefix)
    git_prompt=$brew_path/etc/bash_completion.d/git-prompt.sh
    if [ -a $git_prompt ]; then
        . $git_prompt
    fi

    # TODO: Add an 'else' here that does the brew install of those nice things that you like

    bash_completion=$brew_path/etc/bash_completion
    if [ -a $bash_completion ]; then
      . $bash_completion
    fi

fi
# Shell Customizations
export PS1="\[$BPurple\]\u@\[$BGreen\]\h:\[$BYellow\]\w\[$BCyan\]\$(__git_ps1)\r\n\[$Color_Off\]\\$ "


# Try to re-mount the dev35-devc dpopes home directory (may fail if already mounted, but doesn't hurt)
# This is too specific to my work dev laptop.  Consider removing it or addressing it some other way
sshfs -o reconnect dpopes@dev35-devc:/nail/home/dpopes/ ~/dev/dev35-devc 2>/dev/null
# Keeping the 'unmount' command here for reference:
# diskutil unmountDisk force /Volumes/DISK_NAME

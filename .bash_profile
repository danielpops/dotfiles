# Only echo the text if it is an interactive shell (e.g. a real human logging in)
# Otherwise, some automated tasks may fail when they receive the unexpected text
# e.g. rsync, sshfs type things, etc...
cprint() {
    if [[ $- == *i* ]]; then
        echo $*
    fi
}

cprint "Loading ~/.bash_profile"

# If the ~/.bashrc file exists, then load it
if [ -f ~/.bashrc ]; then
   source ~/.bashrc
fi

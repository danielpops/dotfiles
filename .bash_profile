# Only echo the text if it is an interactive shell (e.g. a real human logging in)
# Otherwise, some automated tasks may fail when they receive the unexpected text
# e.g. rsync, sshfs type things, etc...
cprint() {
    if [[ $- == *i* ]]; then
        echo $*
    fi
}

cprint "Loading ~/.bash_profile"
cprint "Bash version: $(echo $BASH_VERSION)"

# If the ~/.bashrc file exists, then load it
if [ -f ~/.bashrc ]; then
    # sourcing .bashrc was causing terminal to hang on osx catalina
    # exec bash seemed to achieve the desired behavior without hanging
    # but only for interactive shells
    if [[ $- == *i* ]]; then
        # Check if brew is installed
        which brew > /dev/null
        if [[ $? = 0 ]]; then
            exec $(brew --prefix)/bin/bash
        else
            exec bash
        fi
    fi
fi

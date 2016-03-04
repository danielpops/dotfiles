echo "Loading ~/.bash_profile"

# If the ~/.bashrc file exists, then load it
if [ -f ~/.bashrc ]; then
   source ~/.bashrc
fi

test -e "${HOME}/.iterm2_shell_integration.bash" && source "${HOME}/.iterm2_shell_integration.bash"

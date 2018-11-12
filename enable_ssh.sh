#!/bin/bash

SSH_ENABLED=$(systemsetup -getremotelogin)
if [[ "${SSH_ENABLED}" == "Remote Login: Off" ]]; then
    echo "SSH was disabled. Re-enabling it..."
    sudo launchctl load -w /System/Library/LaunchDaemons/ssh.plist
    echo "Successfully enabled ssh"
fi

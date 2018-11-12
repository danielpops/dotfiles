#!/bin/bash

CALLER=$(whoami)
if [[ "${CALLER}" != "root" ]]; then
    echo "Must call this script as root"
    exit -1
fi

launchctl load com.dpopes.enablessh.plist

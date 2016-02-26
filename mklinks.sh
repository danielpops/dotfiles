#!/bin/bash
for f in $(find . -type f -name ".*"); do
    if [ -a ~/$f ]; then
        echo "File ~/$f exists... Renaming it!"
        mv ~/$f ~/$f.bak
    fi
    if [ -h ~/$f ]; then
        echo "File ~/$f exists and is a symbolic link... Renaming it!"
        mv ~/$f ~/$f.bak
    fi
    echo "Linking ~/$f to $(pwd)/$f..."
    ln -s $(pwd)/$f ~/$f
done

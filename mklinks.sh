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

# Other one-off files or folders
htoprc=.config/htop/htoprc
if [ -a ~/$htoprc ]; then
    echo "File ~/$htoprc exists... Renaming it!"
    mv ~/$htoprc ~/$htoprc.bak
fi
if [ -h ~/$htoprc ]; then
    echo "File ~/$htoprc exists and is a symbolic link... Renaming it!"
    mv ~/$htoprc ~/$htoprc.bak
fi
echo "Linking ~/$htoprc to $(pwd)/$htoprc..."
mkdir ln -s -f -d $(pwd)/.config/htop/htoprc ~/.config/htop/htoprc

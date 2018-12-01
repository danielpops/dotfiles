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
mkdir -p ~/.config/htop 2> /dev/null
ln -s -f $(pwd)/.config/htop/htoprc ~/.config/htop/htoprc

karabiner_json=.config/karabiner/karabiner.json
if [ -a ~/$karabiner_json]; then
    echo "File ~/$karabiner_json exists... Renaming it!"
    mv ~/$karabiner_json ~/$karabiner_json.bak
fi
if [ -h ~/$karabiner_json ]; then
    echo "File ~/$karabiner_json exists and is a symbolic link... Renaming it!"
    mv ~/$karabiner_json ~/$karabiner_json.bak
fi

echo "Linking ~/$karabiner_json to $(pwd)/$karabiner_json ..."
mkdir -p ~/.config/karabiner 2> /dev/null
ln -s -f $(pwd)/$karabiner_json ~/$karabiner_json

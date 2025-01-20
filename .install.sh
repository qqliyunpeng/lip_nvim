#!/bin/bash

# install yazi
wget https://github.com/sxyazi/yazi/releases/download/v0.4.2/yazi-x86_64-unknown-linux-gnu.zip
[ -d ~/yazi/ ] && rm ~/yazi/ -rf
mkdir ~/yazi/

unzip yazi-x86_64-unknown-linux-gnu.zip -d ~/yazi/
rm yazi-x86_64-unknown-linux-gnu.zip

sudo ln -sf ~/yazi/yazi-x86_64-unknown-linux-gnu/yazi /usr/bin/yazi

# support sqlite
sudo apt-get install sqlite3 libsqlite3-dev


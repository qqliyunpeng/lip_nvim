#!/bin/bash

# install yazi v26.5.6 (musl 静态包，不依赖系统 glibc)
# 源: https://gitee.com/qqliyunpeng/yazi (tag v26.5.6)
# 说明: Gitee 匿名 Raw 下载大文件需要登录（403 large file require login），
#       因此改用标签归档下载；归档内的 yazi-x86_64-unknown-linux-musl.zip
#       即上游原始发布包，可直接解压使用。
wget https://gitee.com/qqliyunpeng/yazi/repository/archive/v26.5.6.tar.gz
tar xzf v26.5.6.tar.gz

[ -d ~/yazi/ ] && rm ~/yazi/ -rf
mkdir ~/yazi/

unzip yazi-v26.5.6/yazi-x86_64-unknown-linux-musl.zip -d ~/yazi/
rm -rf v26.5.6.tar.gz yazi-v26.5.6

sudo ln -sf ~/yazi/yazi-x86_64-unknown-linux-musl/yazi /usr/bin/yazi

# support sqlite
sudo apt-get install sqlite3 libsqlite3-dev

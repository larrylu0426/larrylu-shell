#!/bin/bash

# author: larrylu
# description: The script to deploy devlop-environment of terminal

function msg() {
    printf '%b\n' "$1" >&2
}

function success() {
    msg "\33[32m[✔]\33[0m ${1}${2}"
}

function error() {
    msg "\33[31m[✘]\33[0m ${1}${2}"
    exit 1
}

function ubuntu_exec() {
    if [ "$platform" == 'Linux' ]; then
        if [ "$os" == 'ubuntu' ]; then
            eval $1
        fi
    fi
}

function centos_exec() {
    if [ "$platform" == 'Linux' ]; then
        if [ "$os" == 'centos' ]; then
            eval $1
        fi
    fi
}

function macos_exec() {
    if [ "$platform" == 'Darwin' ]; then
        eval $1
    fi
}

function app_cmd() {
    if [ $# == 2 ]; then
        command -v $2 > /dev/null 2>&1 || {
            ubuntu_exec "sudo apt $1 -y $2"
            centos_exec "sudo yum $1 -y $2"
            macos_exec "brew $1 $2"
        }
    else
        command -v $2 > /dev/null 2>&1 || ubuntu_exec "sudo apt $1 -y $2"
        command -v $3 > /dev/null 2>&1 || centos_exec "sudo yum $1 -y $3"
        command -v $4 > /dev/null 2>&1 ||  macos_exec "brew $1 $4"
    fi
}

function setup() {
    msg 'Installation start'

    # upadate mirrors-repo
    ubuntu_exec "sudo apt update"

    # install base-dependency items
    if [ "$platform" == 'Darwin' ]; then
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        eval "$(/opt/homebrew/bin/brew shellenv)"
    fi

    app_cmd install sudo
    app_cmd install curl curl-devel
    app_cmd install wget
    app_cmd install git
    app_cmd install exuberant-ctags ctags-etags ctags
    app_cmd install silversearcher-ag silver_searcher silver_searcher
    app_cmd install zsh
    app_cmd install sed sed gnu-sed
    sed_cmd=$([ $platform == 'Linux' ] && echo 'sed' || echo 'gsed')

    # oh-my-zsh
    sudo chsh -s /bin/zsh $USER
    curl -L https://raw.github.com/robbyrussell/oh-my-zsh/master/tools/install.sh | sh
    $sed_cmd -i 's/ZSH_THEME="robbyrussell"/ZSH_THEME="bira"/g'  $HOME/.zshrc
    macos_exec echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> $HOME/.zshrc

    # zsh-syntax-highlighting
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git $HOME/.oh-my-zsh/plugins/zsh-syntax-highlighting
    echo source $HOME/.oh-my-zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh >> $HOME/.zshrc

    # fzf
    mkdir -p $HOME/.oh-my-zsh/repos && git clone --depth 1 https://github.com/junegunn/fzf.git $HOME/.oh-my-zsh/repos/fzf
    $HOME/.oh-my-zsh/repos/fzf/install --completion --key-bindings --update-rc
    rm -rf $HOME/.fzf.bash
    mv $HOME/.fzf.zsh $HOME/.oh-my-zsh/plugins/fzf.zsh
    $sed_cmd -i 's/~\/.fzf.zsh/~\/.oh-my-zsh\/plugins\/fzf.zsh/g'  $HOME/.zshrc

    # install python-related items
    app_cmd install python-dev python-devel
    curl -L https://bootstrap.pypa.io/pip/2.7/get-pip.py | sudo python

    pip install pip -U  -i https://mirrors.tencent.com/pypi/simple
    pip install --upgrade setuptools
    pip config set global.index-url https://mirrors.tencent.com/pypi/simple

    PYTHON_LOCAL_PATH=$([ $platform == 'Linux' ] && echo '$HOME/.local/bin' || echo '$HOME/Library/Python/2.7/bin')
    echo export PATH="$PYTHON_LOCAL_PATH:\$PATH" >> $HOME/.zshrc

    # powerline-status
    pip install powerline-status powerline-mem-segment psutil --user

    # tmux
    tmux_file='.tmux.conf'
    touch $tmux_file
    echo 'run-shell "powerline-daemon --replace"' >> $tmux_file
    echo 'run-shell "powerline-daemon -q"' >> $tmux_file
    echo 'set-option -g default-shell /bin/zsh' >> $tmux_file
    echo 'set -g mouse on' >> $tmux_file
    if [ "$platform" == 'Linux' ]; then
        sudo cp assets/tmux-themes-default.json $HOME/.local/lib/python2.7/site-packages/powerline/config_files/themes/tmux/default.json
        sudo cp assets/tmux-colorschemes-default.json $HOME/.local/lib/python2.7/site-packages/powerline/config_files/colorschemes/default.json
        echo source "$HOME/.local/lib/python2.7/site-packages/powerline/bindings/tmux/powerline.conf" >> $tmux_file
    elif [ "$platform" == 'Darwin' ]; then
        sudo cp assets/tmux-themes-default.json $HOME/Library/Python/2.7/lib/python/site-packages/powerline/config_files/themes/tmux/default.json
        sudo cp assets/tmux-colorschemes-default.json $HOME/Library/Python/2.7/lib/python/site-packages/powerline/config_files/colorschemes/default.json
        echo source "$HOME/Library/Python/2.7/lib/python/site-packages/powerline/bindings/tmux/powerline.conf" >> $tmux_file
    fi
    mv $tmux_file $HOME/
    app_cmd install tmux

    # vim
    git clone https://github.com/vim/vim.git /tmp/vim
    cd /tmp/vim/src
    if [ "$platform" == 'Darwin' ]; then
        brew install lua
        ./configure --with-features=huge --enable-cscope --enable-rubyinterp --enable-largefile --disable-netbeans --enable-pythoninterp --with-python-config-dir=/usr/lib/python2.7/config --enable-perlinterp --enable-luainterp --enable-fail-if-missing --with-lua-prefix=/opt/homebrew/Cellar/lua/5.4.3
    fi
    if [ "$platform" == 'Linux' ]; then
        if [ "$os" == 'ubuntu' ]; then
            sudo apt-get remove -y vim vim-runtime  vim-tiny vim-common vim-gui-common
            sudo apt-get purge  -y vim vim-runtime  vim-tiny vim-common vim-gui-common
            sudo apt-get install -y luajit libncurses-dev ruby-dev mercurial libperl-dev
        elif [ "$os" == 'centos' ]; then
            sudo yum remove -y vim-enhanced vim-common vim-filesystem vim-minimal
            sudo yum install -y luajit luajit-devel ncurses ncurses-devel ruby ruby-devel mercurial perl perl-devel lua-devel
        fi
        ./configure --with-features=huge --enable-cscope --enable-rubyinterp --enable-largefile --disable-netbeans --enable-pythoninterp --with-python-config-dir=/usr/lib/python2.7/config --enable-perlinterp --enable-luainterp --with-luajit --enable-fail-if-missing --with-lua-prefix=/usr --enable-gui=gnome2 --enable-cscope --prefix=/usr
    fi
    make -j$(cat /proc/cpuinfo| grep "processor"| wc -l)
    sudo make install
    success "Installation done"
}

############# MAIN() #############

platform=`uname`
os=$1

setup

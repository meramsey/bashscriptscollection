#!/usr/bin/env bash
## Author: Michael Ramsey
## 
## Setup mint linux or popos with needed defaults.
## How to use.
#

sudo apt-get install -y zsh cargo zoxide fzf gpa git gcc nano vim htop network-manager-openvpn-gnome screen virt-manager build-essential libssl-dev zlib1g-dev libncurses5-dev libreadline-dev libgdbm-dev libdb5.3-dev libbz2-dev liblzma-dev libsqlite3-dev libffi-dev tcl-dev tk tk-dev xclip yadm

bash sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/ma
ster/tools/install.sh)" "" --unattended

git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k

# Firacode nerd font mono
font_url='https://github.com/ryanoasis/nerd-fonts/releases/download/v2.1.0/FiraCode.zip'; font_name=${font_url##*/}; wget ${font_url} && unzip ${font_name} -d ~/.fonts &&fc-cache -fv ;

# Install PHP needed for CSFixer and PHPStorm
sudo add-apt-repository ppa:ondrej/php
sudo apt update -y
sudo apt -y install php7.4 php8.0


# Install starship
sh -c "$(curl -fsSL https://starship.rs/install.sh)"

#homebrew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# pyenv
curl https://pyenv.run | bash
python_version=3.9.6
CONFIGURE_OPTS=--enable-shared pyenv install $python_version && pyenv global $python_version && pyenv rehash

# poetry
curl -sSL https://raw.githubusercontent.com/python-poetry/poetry/master/get-poetry.py | python3 -

# https://keybase.io/docs/the_app/install_linux
curl --remote-name https://prerelease.keybase.io/keybase_amd64.deb
sudo apt install ./keybase_amd64.deb
run_keybase

# https://github.com/cli/cli/blob/trunk/docs/install_linux.md
curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo gpg --dearmor -o /usr/share/keyrings/githubcli-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
sudo apt update
sudo apt install gh

#chrome
curl --remote-name https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb && sudo apt install -y ./google-chrome-stable_current_amd64.deb

# https://docs.sentry.io/product/cli/installation/
curl -sL https://sentry.io/get-cli/ | bash

# https://fpm.readthedocs.io/en/latest/installing.html
sudo apt-get install ruby ruby-dev build-essential -y && sudo gem install --no-document fpm

# Qt designer
sudo apt-get install -y qtcreator pyqt5-dev-tools

# Openvpn
sudo apt install -y network-manager-openvpn-gnome

# sudo without pass 
#sudo visudo /etc/sudoers.d/mike
echo "%${USER}  ALL=(ALL) NOPASSWD:ALL" | sudo tee /etc/sudoers.d/${USER}

# your local user
# mike ALL=(ALL) NOPASSWD:ALL

# virt-manager and osx prep
sudo apt-get install qemu uml-utilities virt-manager git wget libguestfs-tools p7zip-full uml-utilities virt-viewer qemu-kvm libvirt-daemon-system libvirt-clients bridge-utils -y
sudo virsh net-start default
sudo virsh net-autostart default


# JetBrains Toolbox
wget -cO jetbrains-toolbox.tar.gz "https://data.services.jetbrains.com/products/download?platform=linux&code=TBA"
tar -xzf jetbrains-toolbox.tar.gz
DIR=$(find . -maxdepth 1 -type d -name jetbrains-toolbox-\* -print | head -n1)
cd $DIR
./jetbrains-toolbox
cd ..
rm -r $DIR
rm jetbrains-toolbox.tar.gz

# todo: csfixer global
#cp php-cs-fixer /usr/local/bin/php-cs-fixer

#cp .php-cs-fixer.php /usr/local/src/cs-fixer/config/.php-cs-fixer.php 


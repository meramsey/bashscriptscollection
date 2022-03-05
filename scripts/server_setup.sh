#!/usr/bin/env bash
## Author: Michael Ramsey
## Objective Set Bash profiles timezone and add public keys
## https://gitlab.com/mikeramsey/server-profile-setup/blob/master/server_setup.sh
## How to use.
# ./server_setup.sh
# sh server_setup.sh
## Oneliner
## sh <(curl https://gitlab.com/mikeramsey/server-profile-setup/raw/master/server_setup.sh || wget -O - https://gitlab.com/mikeramsey/server-profile-setup/raw/master/server_setup.sh)

### Configure

#Define timezone: https://en.wikipedia.org/wiki/List_of_tz_database_time_zones
Timezone="America/Detroit"

#GitProvider to fetch public keys (gitlab.com,github.com)
GitProvider="gitlab.com"
GitUsername="mikeramsey"

PUB_KEY="ssh-rsa somekeywouldbehere== somecomment"

### Stop Configuring

# Colorize Bash terminal : create your profile http://ezprompt.net/
echo 'export PS1="[\[\e[31m\]\u\[\e[m\]\[\e[33m\]@\[\e[m\]\[\e[34m\]\h\[\e[m\]:\[\e[35m\]\w\[\e[m\]]\\$ "' >> /etc/profile.d/bash_prompt.sh && source /etc/profile.d/bash_prompt.sh;

#Set Timezone in .bashrc
echo "Before: $(date)" && export TZ="/usr/share/zoneinfo/${Timezone}" && echo "export TZ="/usr/share/zoneinfo/${Timezone}"" >> ~/.bashrc && echo "After: $(date)"

#Set Global Timezone forcefully
ln -sf /usr/share/zoneinfo/${Timezone} /etc/localtime

#Add Public Key to server without duplication
#umask 0077 ; mkdir -p ~/.ssh ; grep -q -F \"$PUB_KEY\" ~/.ssh/authorized_keys 2>/dev/null || echo \"$PUB_KEY\" >> ~/.ssh/authorized_keys

#Add Public keys from gitprovider for user to authorized keys
mkdir -p ~/.ssh ; curl https://${GitProvider}/${GitUsername}.keys | tee -a ~/.ssh/authorized_keys 

#Dedupe public keys in ~/.ssh/authorized_keys and backup original
awk '!x[$0]++' ~/.ssh/authorized_keys > ~/.ssh/authorized_keys_deduped && mv ~/.ssh/authorized_keys ~/.ssh/authorized_keys.bak && mv ~/.ssh/authorized_keys_deduped ~/.ssh/authorized_keys

echo 'Completed Configuration'


#!/usr/bin/env bash

# https://sethforprivacy.com/guides/run-a-monero-node-advanced/#download-and-install-monerod

function install_prereqs(){
	sudo apt-get update && sudo apt-get upgrade -y
	sudo apt-get install -y ufw gpg wget
}

function setup_ufw(){
	# Deny all non-explicitly allowed ports
	sudo ufw default deny incoming
	sudo ufw default allow outgoing

	# Allow SSH access
	sudo ufw allow ssh

	# Allow monerod p2p port
	sudo ufw allow 18080/tcp

	# Allow monerod restricted RPC port
	sudo ufw allow 18089/tcp

	# Enable UFW
	sudo ufw enable
}

function setup_monero_user_files(){
	# Create a system user and group to run monerod as
	sudo addgroup --system monero
	sudo adduser --system monero --home /var/lib/monero

	# Create necessary directories for monerod
	sudo mkdir /var/run/monero
	sudo mkdir /var/log/monero
	sudo mkdir /etc/monero

	# Create monerod config file
	sudo touch /etc/monero/monerod.conf

	# Set permissions for new directories
	sudo chown monero:monero /var/run/monero
	sudo chown monero:monero /var/log/monero
	sudo chown -R monero:monero /etc/monero
}

function download_install_verify_binaryfate(){
	# Download binaryfate's GPG key
	wget -q -O binaryfate.asc https://raw.githubusercontent.com/monero-project/monero/master/utils/gpg_keys/binaryfate.asc

	# Verify binaryfate's GPG key
	echo "1. Verify binaryfate's GPG key: "
	gpg --keyid-format long --with-fingerprint binaryfate.asc

	# Prompt user to confirm the key matches that posted on https://src.getmonero.org/resources/user-guides/verification-allos-advanced.html
	echo
	read -p "Does the above output match https://src.getmonero.org/resources/user-guides/verification-allos-advanced.html?" -n 1 -r
	echo
	if [[ $REPLY =~ ^[Yy]$ ]]
	then
			# Import binaryfate's GPG key
			echo
			echo "----------------------------"
			echo "2. Import binaryfate's GPG key"
			gpg --import binaryfate.asc
	fi
}

function remove_stale_downloads(){
	# Delete stale .bz2 Monero downloads
	rm -f monero-linux-x64-*.tar.bz2
}

function download_verify_hashes(){
	# Download hashes.txt
	wget -q -O hashes.txt https://getmonero.org/downloads/hashes.txt

	# Verify hashes.txt
	echo
	echo "--------------------"
	echo "3. Verify hashes.txt"
	gpg --verify hashes.txt
}

function download_latest_binaries(){
	# Download latest 64-bit binaries
	echo
	echo "-------------------------------------"
	echo "4. Download latest Linux binaries"
	echo "Downloading..."
	wget -q --content-disposition https://downloads.getmonero.org/cli/linux64
}

function verify_downloaded_binaries(){
	# Verify shasum of downloaded binaries
	echo
	echo "---------------------------------------"
	echo "5. Verify hashes of downloaded binaries"
	if shasum -a 256 -c hashes.txt -s 2>&1 | grep -v 'No such file or directory'
	then
			echo
			echo "Success: The downloaded binaries verified properly!"
	else
			echo
			echo -e "\e[31mDANGER: The download binaries have been tampered with or corrupted\e[0m"
			rm -rf monero-linux-x64-*.tar.bz2
			exit 1
	fi
}

function install_monero_binaries(){
	tar xvf monero-linux-*.tar.bz2
	rm monero-linux-*.tar.bz2
	sudo cp -r monero-x86_64-linux-gnu-*/* /usr/local/bin/
	sudo chown -R monero:monero /usr/local/bin/monero*
}



file="somefiletext"
	cat >> "${file}" <<-EOL
 	Some test text here
	EOL
#!/usr/bin/env bash

filename='some_file'
CHECKSUM='263014b67cfee4dd9266380d15538f5c12e9d38af39e2c0074f33d16356d57d8'

CHECK_HASH_VALID(){
	local FILE_NAME
	local VALID_CHECKSUM
	FILE_NAME=$1
	VALID_CHECKSUM=$2
	
	echo "Checking ${FILE_NAME} checksum matches ${VALID_CHECKSUM}"
	if sha256sum "${FILE_NAME}"|grep -Eo '^\w+'|cmp -s <(echo "$VALID_CHECKSUM"); then
		echo "Hash check: for ${FILE_NAME} passed...";
	else
		echo "Hash check: for ${FILE_NAME} FAILED...";
		exit 1
	fi
}


EXTRACT_IF_HASH_VALID(){
	# cd $HOME;
	CHECK_HASH_VALID "${filename}" "$CHECKSUM"
	if [ $? -ne 0 ]; then
		echo "Skipping extraction for ${filename} as hashcheck FAILED...";
		exit 1
	else
		echo "Extracting now...";
		# tar -xvzf "${filename}";
		echo 'Running installer and providing encryption password'
		# printf "${encryption_password}\n" | ./Installer.sh
		
	fi
}

EXTRACT_IF_HASH_VALID

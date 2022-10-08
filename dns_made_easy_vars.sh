#!/usr/bin/env bash

# ~/dns_made_easy_vars.sh

# vars file for use in dns_made_easy_updater.sh

# This is the e-mail address that you use to login
DMEUSER=

# This is your dns record password
DMEPASS=

# These are the unique numbers for the record that you are updating.
# This number can be obtained by clicking on the DDNS link for the
# record that you wish to update; the number for the record is listed
# on the next page.
DMEIDS=(
	# "" # domain1
	# "" # domain2
	# "" # domain3
	# "" # domain4 
	# "" # domain5 
	# "" # domain6
	# "" # ftp
)

export DMEUSER
export DMEPASS
export DMEIDS
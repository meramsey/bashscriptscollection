#!/usr/bin/env bash
## Author: Michael Ramsey
## Objective clear client login ips in whmcs logs

## Start Config ##
DB_NAME='database_name';
DB_USERNAME='database_username';
export PASSWORD='Passwordhere';
## END Config ##

# Clear clients last login IP address in table tblclients > ip,host
mysql "${DB_NAME}" -u "${DB_USERNAME}" "-p${PASSWORD}" -e "UPDATE tblclients SET ip = '', host = ''"

# WHMCS Clear last login IP address in tblusers last_ip last_hostname
mysql "${DB_NAME}" -u "${DB_USERNAME}" "-p${PASSWORD}" -e "UPDATE tblusers SET last_ip = '', last_hostname = ''"

# Clear Order Ipaddress in table tblorders > ipaddress
mysql "${DB_NAME}" -u "${DB_USERNAME}" "-p${PASSWORD}" -e "UPDATE tblorders SET ipaddress = ''"

# Clear Order Ipaddress in table tblactivitylog > ipaddr where Client
mysql "${DB_NAME}" -u "${DB_USERNAME}" "-p${PASSWORD}" -e "UPDATE tblactivitylog SET ipaddr = '' WHERE user = 'Client'"

unset PASSWORD

#!/usr/bin/env bash
#cPanel VPS Deploy Script cust-deploy.sh located in /etc/cpanel/cust-deploy.sh  --firstboot-command /bin/sh /etc/cpanel/cust-deploy.sh

#Find Server IP 
IP=$(hostname -I | cut -d ' ' -f 1)

#set IP address of VPS in cPanel /etc/wwwacct.conf
sed -i "s/IPADDR/$IP/g" /etc/wwwacct.conf

readonly PROGNAME=$(basename $0)
readonly PROGDIR=$(readlink -m $(dirname $0))
readonly ARGS="$@"
readonly HOSTNAME=$(hostname --fqdn)
readonly CPHULKPASS=$(/usr/local/cpanel/3rdparty/bin/perl -MCpanel::PasswdStrength::Generate -e 'print Cpanel::PasswdStrength::Generate::generate_password(14)')
readonly MSECPASS=$(/usr/local/cpanel/3rdparty/bin/perl -MCpanel::PasswdStrength::Generate -e 'print Cpanel::PasswdStrength::Generate::generate_password(14)')
readonly ESTATSPASS=$(/usr/local/cpanel/3rdparty/bin/perl -MCpanel::PasswdStrength::Generate -e 'print Cpanel::PasswdStrength::Generate::generate_password(14)')
readonly LPROTPASS=$(/usr/local/cpanel/3rdparty/bin/perl -MCpanel::PasswdStrength::Generate -e 'print Cpanel::PasswdStrength::Generate::generate_password(14)')
readonly RCUBEPASS=$(/usr/local/cpanel/3rdparty/bin/perl -MCpanel::PasswdStrength::Generate -e 'print Cpanel::PasswdStrength::Generate::generate_password(14)')
readonly MYSQLPASS=$(/usr/local/cpanel/3rdparty/bin/perl -MCpanel::PasswdStrength::Generate -e 'print Cpanel::PasswdStrength::Generate::generate_password(14)')

is_file() {
    local file=$1
    [[ -f $file  ]]
}

is_dir() {
    local dir=$1
    [[ -d $dir  ]]
}

main() {
    is_dir /usr/local/cpanel \
        && /usr/local/cpanel/bin/set_hostname ${HOSTNAME} \
        && /usr/local/cpanel/bin/checkallsslcerts --allow-retry \
        && /scripts/build_cpnat \
        && /scripts/rebuildhttpdconf \
        && /scripts/mysqlpasswd root ${MYSQLPASS} \
    is_file /var/cpanel/hulkd/password \
        && /scripts/mysqlpasswd cphulkd ${CPHULKPASS} \
        && echo -e "user=\"cphulkd\"\npass=\"${CPHULKPASS}\"">/var/cpanel/hulkd/password \
        && /scripts/restartsrv_cphulkd
    is_file /var/cpanel/modsec_db_pass \
        && /scripts/mysqlpasswd modsec ${MSECPASS} \
        && echo ${MSECPASS} >/var/cpanel/modsec_db_pass
    is_file /var/cpanel/roundcubepass \
        && /scripts/mysqlpasswd roundcube ${RCUBEPASS} \
        && echo ${RCUBEPASS} >/var/cpanel/roundcubepass
    is_file /var/cpanel/eximstatspass \
        && /scripts/mysqlpasswd eximstats ${ESTATSPASS} \
        && echo ${ESTATSPASS} >/var/cpanel/eximstatspass \
        && /scripts/restartsrv_eximstats
    is_file /var/cpanel/leechprotectpass \
        && /scripts/mysqlpasswd leechprotect ${LPROTPASS} \
        && echo ${LPROTPASS} >/var/cpanel/leechprotectpass
}
 
main



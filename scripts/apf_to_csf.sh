#!/usr/bin/env bash
#Install Csf and Modsec and Convert from APF to CSF for normal MVPS/Mdedicateds
#Modified CORP installer by Mike Ramsey and Ross B
#Setup variables for APF Conversion
APF_conf="/etc/apf/conf.apf"
APF_conf_allow_hosts="/etc/apf/allow_hosts.rules"
APF_conf_deny_hosts="/etc/apf/deny_hosts.rules"
APF_Backup_Ports="/root/apf.ports"
APF_Backup_allow_hosts="/root/apf_customers.allow"
APF_Backup_deny_hosts="/root/apf_customers.deny"
CSF_allow_hosts="/etc/csf/customers.allow"
CSF_deny_hosts="/etc/csf/csf.deny"
apf_port_dedupe () {
#needed to dedupe
cp /etc/csf/csf.conf csf.conf
#Run after csf finished installed
echo 'Combined deduped port rules'
echo 'Combined deduped port rules for TCP_IN'
grep -hE "TCP_IN" {apf.ports,csf.conf}| sed -e 's/TCP_IN = //' -e 's/TCP_IN=//' -e 's/"//g'|paste -sd ',' -|awk 'BEGIN{RS=ORS=","} !seen[$0]++'| sed -e 's/,/\n/g' | sort -Vu| tr '\n' ','| sed 's|^,||'
echo ""
echo 'Combined deduped port rules for TCP_OUT'
echo ""
grep -hE "TCP_OUT" {apf.ports,csf.conf}| sed -e 's/TCP_OUT = //' -e 's/TCP_OUT=//' -e 's/"//g'|paste -sd ',' -|awk 'BEGIN{RS=ORS=","} !seen[$0]++'| sed -e 's/,/\n/g' | sort -Vu| tr '\n' ','| sed 's|^,||'
echo ""
echo 'Combined deduped port rules for UDP_IN'
grep -hE "UDP_IN" {apf.ports,csf.conf}| sed -e 's/UDP_IN = //' -e 's/UDP_IN=//' -e 's/"//g'|paste -sd ',' -|awk 'BEGIN{RS=ORS=","} !seen[$0]++'| sed -e 's/,/\n/g' | sort -Vu| tr '\n' ','| sed 's|^,||'
echo ""
echo 'Combined deduped port rules for UDP_OUT'
grep -hE "UDP_OUT" {apf.ports,csf.conf}| sed -e 's/UDP_OUT = //' -e 's/UDP_OUT=//' -e 's/"//g'|paste -sd ',' -|awk 'BEGIN{RS=ORS=","} !seen[$0]++'| sed -e 's/,/\n/g' | sort -Vu| tr '\n' ','| sed 's|^,||'
echo ""
echo 'convert/append the apf rules to csf version rules including fixing port format syntax'
grep -Ev '^#' ${APF_Backup_allow_hosts} | tee -a ${CSF_allow_hosts} 
echo ""
echo 'append the apf deny rules to csf version rules including fixing port format syntax'
cat ${APF_Backup_deny_hosts} | tee -a ${CSF_deny_hosts} 
echo ""
}
if [[ -f /etc/apf/conf.apf ]]
then
    echo 'Backup Apf ports'
    grep -E "CPORTS" ${APF_conf} | grep -v '^#'|sed 's|_|:|g'|sed -e 's/IG:TCP:CPORTS/TCP_IN/g' -e 's/IG:UDP:CPORTS/UDP_IN/g' -e 's/EG:TCP:CPORTS/TCP_OUT/g' -e 's/EG:UDP:CPORTS/UDP_OUT/g'| tee ${APF_Backup_Ports}
    echo ""
    echo 'Backup Apf allow'
    sed '1!G;h;$!d' "${APF_conf_allow_hosts}"| sed -e ':1 ; N ; $!b1' -e 's/\n\+\( *[^[:alnum:]]\)/ \1/g'|sed 's/:/|/g'|grep -Ev '^#'|sed 's/##.*//'| tac| tee ${APF_Backup_allow_hosts}
    echo ""
    echo 'Backup Apf deny and convert to CSF'
    sed '1!G;h;$!d' "${APF_conf_deny_hosts}"| sed -e ':1 ; N ; $!b1' -e 's/\n\+\( *[^[:alnum:]]\)/ \1/g'|grep -Ev '^#'|sed 's/##.*//'| tac| tee ${APF_Backup_deny_hosts}
    echo ""
fi
if [[ -f /etc/csf/corp_sync ]]
then
    echo "CSF/CMC/Modsec Already Installed"
else
    echo "Installing CSF" 
    yum -y install ipset
    cd /usr/src
    rm -fv csf.tgz
    wget https://download.configserver.com/csf.tgz
    tar -xzf csf.tgz
    cd csf 
    sh install.sh
    cd /root/
    useradd csf -s /bin/false
    
    sed -i 's|TESTING \=.*|TESTING = "0"|' /etc/csf/csf.conf
    sed -i 's|IPV6 \=.*|IPV6 = "0"|'  /etc/csf/csf.conf
    sed -i 's|LF_IPSET \=.*|LF_IPSET = "0"|' /etc/csf/csf.conf
    sed -i 's|DENY_IP_LIMIT \=.0|DENY_IP_LIMIT = "2000"|' /etc/csf/csf.conf
    sed -i 's|MESSENGERV2 \=.*|MESSENGERV2 = "0"|' /etc/csf/csf.conf
    sed -i 's/TCP_IN =.*/TCP_IN = "21,22,25,53,80,125,443,445,110,143,465,587,902,993,995,2041,2077,2078,2079,2080,2082,2083,2084,2086,2087,2095,2096,2525,3306,4505,4506,5432,6109,6556,7770:7800,7822,9850:9877,25001,30000:50000,55555,55556"/' /etc/csf/csf.conf
    sed -i 's/TCP_OUT =.*/TCP_OUT = "21,22,25,37,43,53,80,110,111,113,123,389,443,445,464,465,514,587,636,749,873,881,902,953,993,995,1021,2049,2401,2077,2078,2079,2080,2083,2089,2087,2195,2525,2703,3306,3690,4505,4506,5308,5432,6109,7770:7800,7822,8443,9418,25001,44445,55555,55556"/' /etc/csf/csf.conf
    sed -i 's/^PORTS_sshd.*/PORTS_sshd = "22,7822"/g' /etc/csf/csf.conf
    systemctl stop firewalld
    systemctl disable firewalld
    sh /usr/local/csf/bin/remove_apf_bfd.sh
    # systemctl restart csf 
    # csf -s
    rm -fv /usr/local/sbin/apf
    rm -fv /usr/local/sbin/fwmgr
    echo "Installing CMC/Modsec" 
    mkdir /var/asl
    mkdir /var/asl/data/
    mkdir /var/asl/data/msa
    mkdir /var/asl/data/audit
    mkdir /var/asl/data/suspicious
    chown nobody.nobody /var/asl/data/msa
    chown nobody.nobody /var/asl/data/audit
    chown nobody.nobody /var/asl/data/suspicious
    chmod o-rx -R /var/asl/data/*
    chmod ug+rwx -R /var/asl/data/*
    cd /usr/src
    rm -fv /usr/src/cmc.tgz
    wget http://download.configserver.com/cmc.tgz 
    tar -xzf cmc.tgz
    cd cmc
    sh install.sh 
    cd /root/
    rm -Rfv /usr/src/cmc*
    mkdir /etc/apache2/conf.d/modsec/modsec_owasp
    echo "Applying csf/cmc/modsec changes" 
    salt-call state.apply
    cf-agent -vK
    csf -r
    service httpd restart
    apf_port_dedupe
fi

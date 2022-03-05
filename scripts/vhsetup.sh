#!/usr/bin/env bash
# /********************************************************************
# LiteSpeed domain setup Script
# @Author:   LiteSpeed Technologies, Inc. (https://www.litespeedtech.com)
# @Copyright: (c) 2019-2021
# @Version: 2.0.0
# *********************************************************************/
MY_DOMAIN=''
MY_DOMAIN2=''
WWW_PATH='/var/www'
LSDIR='/usr/local/lsws'
WEBCF="${LSDIR}/conf/httpd_config.conf"
VHDIR="${LSDIR}/conf/vhosts"
EMAIL='localhost'
WWW='FALSE'
BOTCRON='/etc/cron.d/certbot'
PLUGINLIST="litespeed-cache.zip"
CKREG="^[a-z0-9!#\$%&'*+/=?^_\`{|}~-]+(\.[a-z0-9!#$%&'*+/=?^_\`{|}~-]+)*\
@([a-z0-9]([a-z0-9-]*[a-z0-9])?\.)+[a-z0-9]([a-z0-9-]*[a-z0-9])?\$"
THEME='twentytwenty'
PHPVER=lsphp74
USER='www-data'
GROUP='www-data'
DOMAIN_PASS='ON'
DOMAIN_SKIP='OFF'
EMAIL_SKIP='OFF'
SILENT='OFF'
TMP_YN='OFF'
ISSUECERT='OFF'
FORCE_HTTPS='OFF'
WORDPRESS='OFF'
CLASSICPRESS='OFF'
DB_TEST=0
EPACE='        '

echoR() {
    echo -e "\e[31m${1}\e[39m"
}
echoG() {
    echo -e "\e[32m${1}\e[39m"
}
echoY() {
    echo -e "\e[33m${1}\e[39m"
}
echoB() {
    echo -e "\033[1;4;94m${1}\033[0m"
}
echoW(){
    FLAG=${1}
    shift
    echo -e "\033[1m${EPACE}${FLAG}\033[0m${@}"
}

show_help() {
    case ${1} in
    "1")
        echo -e "\033[1mOPTIONS\033[0m"
        echoW "-D, --domain [DOMAIN_NAME]"
        echo "${EPACE}${EPACE}If you wish to add www domain , please attach domain with www"
        echoW "-LE, --letsencrypt [EMAIL]"
        echo "${EPACE}${EPACE}Issue let's ecnrypt certificate, must follow with E-mail address."
        echoW "-F, --force-https"
        echo "${EPACE}${EPACE}This will add a force HTTPS rule in htaccess file"
        echoW "-W, --wordpress"
        echo "${EPACE}${EPACE}This will install a Wordpress with LiteSpeed Cache plugin."
        echo "${EPACE}${EPACE}Example: ./vhsetup.sh -d www.example.com -le admin@example.com -f -w"
        echo "${EPACE}${EPACE}Above example will create a virtual host with www.example.com and example.com domain"
        echo "${EPACE}${EPACE}Issue and install Let's encrypt certificate and Wordpress with LiteSpeed Cache plugin."
        echoW "-C, --classicpress"
        echo "${EPACE}${EPACE}This will install a ClassicPress with LiteSpeed Cache plugin."   
        echoW '-H, --help'
        echo "${EPACE}${EPACE}Display help and exit."
        exit 0
    ;;    
    "2")
        echo "If you need to install cert manually later, please check:" 
        echo "https://docs.litespeedtech.com/shared/cloud/OPT-LETSHTTPS/"
        echo ''
    ;;  
    "3")
        echo "Please make sure you have ${HM_PATH}/.db_password file with content:"
        echo 'root_mysql_pass="YOUR_DB_PASSWORD"'
    ;;  
    esac
}
check_os() {
    if [ -f /etc/redhat-release ]; then
        OSNAME=centos
        USER='nobody'
        GROUP='nobody'
    elif [ -f /etc/lsb-release ]; then
        OSNAME=ubuntu
    elif [ -f /etc/debian_version ]; then
        OSNAME=debian
    fi
}
check_provider()
{
    if [[ "$(sudo cat /sys/devices/virtual/dmi/id/product_uuid | cut -c 1-3)" =~ (EC2|ec2) ]]; then 
        PROVIDER='aws'
    elif [ "$(dmidecode -s bios-vendor)" = 'Google' ];then
        PROVIDER='google'
    elif [ "$(dmidecode -s system-product-name | cut -c 1-7)" = 'Alibaba' ];then
        PROVIDER='aliyun'  
    elif [ "$(dmidecode -s system-manufacturer)" = 'Microsoft Corporation' ];then    
        PROVIDER='azure'        
    else
        PROVIDER='undefined'  
    fi
}
check_home_path()
{
    if [ ${PROVIDER} = 'aws' ] && [ -d /home/ubuntu ]; then 
        HM_PATH='/home/ubuntu'
    elif [ ${PROVIDER} = 'google' ] && [ -d /home/ubuntu ]; then 
        HM_PATH='/home/ubuntu'  
    elif [ ${PROVIDER} = 'aliyun' ] && [ -d /home/ubuntu ]; then
        HM_PATH='/home/ubuntu'
    else
        HM_PATH='/root'
    fi    
}
check_root(){
    if [ "$(id -u)" -ne 0 ]; then
        echo "Please run this script as root user or use sudo"
        exit 2
    fi
}
check_process(){
    ps aux | grep "${1}" | grep -v grep >/dev/null 2>&1
}
install_ed() {
    if [ -f /bin/ed ]; then
        echo "ed exist"
    else
        echo "no ed, ready to install"
        if [ "${OSNAME}" = 'ubuntu' ] || [ "${OSNAME}" = 'debian' ]; then
            apt-get install ed -y >/dev/null 2>&1
        elif [ "${OSNAME}" = 'centos' ]; then
            yum install ed -y >/dev/null 2>&1
        fi
    fi
}
create_file(){
    if [ ! -f "${1}" ]; then
        touch "${1}"
    fi
}
create_folder(){
    if [ ! -d "${1}" ]; then
        mkdir -p "${1}"
    fi
}
change_owner() {
    chown -R ${USER}:${GROUP} ${DOCHM}
}
line_insert(){
    LINENUM=$(grep -n "${1}" ${2} | cut -d: -f 1)
    ADDNUM=${4:-0} 
    if [ -n "$LINENUM" ] && [ "$LINENUM" -eq "$LINENUM" ] 2>/dev/null; then
        LINENUM=$((${LINENUM}+${4}))
        sed -i "${LINENUM}i${3}" ${2}
    fi  
}
install_wp_cli() {
    if [ ! -e /usr/local/bin/wp ]; then
        curl -sO https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
        chmod +x wp-cli.phar
        mv wp-cli.phar /usr/local/bin/wp
    fi    
    if [ ! -f /usr/bin/php ]; then
        if [ -e ${LSDIR}/${PHPVER}/bin/php ]; then
            ln -s ${LSDIR}/${PHPVER}/bin/php /usr/bin/php
        else
            echo "${LSDIR}/${PHPVER}/bin/php not exist, please check your PHP version!"
            exit 1 
        fi        
    fi      
}
gen_password(){
    ROOT_PASS=$(cat ${HM_PATH}/.db_password | head -n 1 | awk -F '"' '{print $2}')
    WP_DB=$(echo "${MY_DOMAIN}" | sed -e 's/\.//g; s/-//g')
    WP_USER=$(head /dev/urandom | tr -dc A-Za-z0-9 | head -c 8; echo '')
    WP_PASS=$(head /dev/urandom | tr -dc A-Za-z0-9 | head -c 48; echo '')
}

check_which_cms(){
    if [ ${SILENT} = 'OFF' ]; then
		while true; do
			echo -e "Please choose whether to install WordPress or ClassicPress"
            if [ "${WORDPRESS}" = 'OFF' ] && [ "${CLASSICPRESS}" = 'OFF' ]; then
                printf "%s" "Install WordPress? [y/N]: "
                read TMP_YN
                if [[ "${TMP_YN}" =~ ^(y|Y) ]]; then
                    WORDPRESS='ON'
                else
                    WORDPRESS='OFF'    
                fi
            fi
            if [ "${WORDPRESS}" = 'OFF' ] && [ "${CLASSICPRESS}" = 'OFF' ]; then 
                printf "%s" "Install ClassicPress? [y/N]: "
                read TMP_YN
                if [[ "${TMP_YN}" =~ ^(y|Y) ]]; then
                    CLASSICPRESS='ON'
                else
                    CLASSICPRESS='OFF'    
                fi
            fi
            if [ "${WORDPRESS}" = 'ON' ]; then
                printf "%s" "The Application you input is WordPress. [y/N]: "
            elif [ "${CLASSICPRESS}" = 'ON' ]; then
                printf "%s" "The Application you input is ClassicPress. [y/N]: "
            else
                printf "%s" "The Application you input is None. [y/N]: "
            fi
            read TMP_YN
            if [[ "${TMP_YN}" =~ ^(y|Y) ]]; then
                break
            else
                WORDPRESS='OFF'
                CLASSICPRESS='OFF'
            fi
		done
	fi
}

get_theme_name(){
    THEME_NAME=$(grep WP_DEFAULT_THEME ${DOCHM}/wp-includes/default-constants.php | grep -v '!' | awk -F "'" '{print $4}')
    echo "${THEME_NAME}" | grep 'twenty' >/dev/null 2>&1
    if [ ${?} = 0 ]; then
        THEME="${THEME_NAME}"
    fi
}

install_wp_plugin(){
    for PLUGIN in ${PLUGINLIST}; do
        echo "Install ${PLUGIN}"
        wget -q -P ${DOCHM}/wp-content/plugins/ https://downloads.wordpress.org/plugin/${PLUGIN}
        if [ ${?} = 0 ]; then
            unzip -qq -o ${DOCHM}/wp-content/plugins/${PLUGIN} -d ${DOCHM}/wp-content/plugins/
        else
            echo "${PLUGINLIST} FAILED to download"
        fi
    done
    rm -f ${DOCHM}/wp-content/plugins/*.zip
}

set_lscache(){
    if [ ! -f ${DOCHM}/wp-content/themes/${THEME}/functions.php.bk ]; then
        cp ${DOCHM}/wp-content/themes/${THEME}/functions.php ${DOCHM}/wp-content/themes/${THEME}/functions.php.bk
        install_ed
        ed ${DOCHM}/wp-content/themes/${THEME}/functions.php <<END >>/dev/null 2>&1
19i
require_once( WP_CONTENT_DIR.'/../wp-admin/includes/plugin.php' );
\$path = 'litespeed-cache/litespeed-cache.php' ;
if (!is_plugin_active( \$path )) {
  activate_plugin( \$path ) ;
  rename( __FILE__ . '.bk', __FILE__ );
}
.
w
q
END
    fi
}

create_db_user(){
    if [ -e ${HM_PATH}/.db_password ]; then
        gen_password
        mysql -uroot -p${ROOT_PASS} -e "create database ${WP_DB};"
        if [ ${?} = 0 ]; then
            mysql -uroot -p${ROOT_PASS} -e "CREATE USER '${WP_USER}'@'localhost' IDENTIFIED BY '${WP_PASS}';"
            mysql -uroot -p${ROOT_PASS} -e "GRANT ALL PRIVILEGES ON * . * TO '${WP_USER}'@'localhost';"
            mysql -uroot -p${ROOT_PASS} -e "FLUSH PRIVILEGES;"
        else
            echo "something went wrong when create new database, please proceed to manual installtion."
            DB_TEST=1
        fi
    else
        echo "No DataBase Password, skip!"  
        DB_TEST=1
        show_help 3
    fi    
}

install_wp() {
    create_db_user
    if [ ${DB_TEST} = 0 ]; then
        install_wp_cli
        rm -f ${DOCHM}/index.php
        export WP_CLI_CACHE_DIR=${WWW_PATH}/.wp-cli/
        wp core download --path=${DOCHM} --allow-root --quiet
        wp core config --dbname=${WP_DB} --dbuser=${WP_USER} --dbpass=${WP_PASS} \
            --dbhost=localhost --dbprefix=wp_ --path=${DOCHM} --allow-root --quiet
        get_theme_name
        config_wp
        change_owner
        echo "WP downloaded, please access your domain to complete the setup."    
    fi
}

set_wp_htaccess(){
    create_file "${DOCHM}/.htaccess"
    cat <<EOM >${DOCHM}/.htaccess
# BEGIN WordPress
<IfModule mod_rewrite.c>
RewriteEngine On
RewriteBase /
RewriteRule ^index\.php$ - [L]
RewriteCond %{REQUEST_FILENAME} !-f
RewriteCond %{REQUEST_FILENAME} !-d
RewriteRule . /index.php [L]
</IfModule>
# END WordPress
EOM
}

config_wp() {
    echo 'Setting WordPress'
    install_wp_plugin
    set_wp_htaccess
    set_lscache
    echo 'Finish WordPress'
}

check_install_wp() { 
    if [ ${WORDPRESS} = 'ON' ]; then
        check_process 'mysqld'
        if [ ${?} = 0 ]; then
            if [ ! -f ${DOCHM}/wp-config.php ]; then
                install_wp
            else
                echo 'WordPress existed, skip!'    
            fi    
        else
            echo 'No MySQL environment, skip!'
        fi                
    fi
}

install_cp() {
    create_db_user
    if [ ${DB_TEST} = 0 ]; then
        install_wp_cli
        export WP_CLI_CACHE_DIR=${WWW_PATH}/.wp-cli/
        cd ${DOCHM}
        wget -q --no-check-certificate https://www.classicpress.net/latest.tar.gz -O classicpress.tar.gz
        tar -xzvf classicpress.tar.gz --strip-components=1 -C ${DOCHM}  >/dev/null 2>&1
        rm -rf classicpress.tar.gz
        wp core config --dbname=${WP_DB} --dbuser=${WP_USER} --dbpass=${WP_PASS} \
            --dbhost=localhost --dbprefix=cp_ --path=${DOCHM} --allow-root --quiet
        get_theme_name
        config_cp
        change_owner
        echo "ClassicPress downloaded, please access your domain to complete the setup." 
    fi    
}

set_cp_htaccess(){
    create_file "${DOCHM}/.htaccess"
    cat <<EOM >${DOCHM}/.htaccess
# BEGIN ClassicPress
<IfModule mod_rewrite.c>
RewriteEngine On
RewriteBase /
RewriteRule ^index\.php$ - [L]
RewriteCond %{REQUEST_FILENAME} !-f
RewriteCond %{REQUEST_FILENAME} !-d
RewriteRule . /index.php [L]
</IfModule>
# END ClassicPress
EOM
}

config_cp() {
    echo 'Setting ClassicPress'
    install_wp_plugin
    set_cp_htaccess
    set_lscache
    echo 'Finish ClassicPress'
}

check_install_cp() {
    if [ "${CLASSICPRESS}" = 'ON' ]; then
        check_process 'mysqld'
        if [ ${?} = 0 ]; then
            if [ ! -f ${DOCHM}/wp-config.php ]; then
                install_cp
            else
                echo "ClassicPress already exists at ${DOCHM}. Skip!"   
            fi    
        else
            echo 'No MySQL environment, skip!'
        fi                
    fi
}

check_duplicate() {
    grep -w "${1}" ${2} >/dev/null 2>&1
}
restart_lsws(){
    ${LSDIR}/bin/lswsctrl restart >/dev/null
}   
set_vh_conf() {
    create_folder "${DOCHM}"
    create_folder "${VHDIR}/${MY_DOMAIN}"
    create_file "${VHDIR}/${MY_DOMAIN}/htpasswd"
    create_file "${VHDIR}/${MY_DOMAIN}/htgroup"
    if [ ! -f "${DOCHM}/index.php" ]; then
        cat <<'EOF' >${DOCHM}/index.php
<?php
phpinfo();
EOF
        change_owner
    fi
    if [ ! -f "${VHDIR}/${MY_DOMAIN}/vhconf.conf" ]; then
        cat > ${VHDIR}/${MY_DOMAIN}/vhconf.conf << EOF
docRoot                   \$VH_ROOT/html
vhDomain                  \$VH_DOMAIN
vhAliases                 www.\$VH_DOMAIN
adminEmails               admin@\$VH_DOMAIN
enableGzip                1
enableBr                  1

errorlog \$VH_ROOT/html/logs/\$VH_NAME.error_log {
useServer               0
logLevel                ERROR
rollingSize             10M
}

accesslog \$VH_ROOT/html/logs/\$VH_NAME.access_log {
useServer               0
logFormat               "%h %l %u %t "%r" %>s %b "%{Referer}i" "%{User-Agent}i""
logHeaders              7
rollingSize             10M
keepDays                10
}

index  {
useServer               0
indexFiles              index.php, index.html
}

scripthandler  {
add                     lsapi:${PHPVER} php
}

phpIniOverride  {
php_admin_flag log_errors On
php_admin_value error_log logs/php_error_log
}

realm Default {
  note                    Default password protected realm

  userDB  {
    location              \$SERVER_ROOT/conf/vhosts/\$VH_NAME/htpasswd
  }

  groupDB  {
    location              \$SERVER_ROOT/conf/vhosts/\$VH_NAME/htgroup
  }
}

extprocessor ${PHPVER} {
type                    lsapi
address                 uds://tmp/lshttpd/${MY_DOMAIN}.sock
maxConns                35
env                     PHP_LSAPI_CHILDREN=35
env                     PHP_INI_SCAN_DIR=:\$VH_ROOT/html
initTimeout             600
retryTimeout            0
persistConn             1
respBuffer              0
autoStart               1
path                    ${LSDIR}/${PHPVER}/bin/lsphp
backlog                 100
instances               1
runOnStartUp            1
priority                0
memSoftLimit            2047M
memHardLimit            2047M
procSoftLimit           400
procHardLimit           500
}

### Insert context configs below this line

context /logs/ {
  location                logs/
  allowBrowse             0
  note                    Deny public access to logs directory

  rewrite  {

  }
  addDefaultCharset       off

  phpIniOverride  {

  }
}

context / {
  allowBrowse             1
  note                    Default Context Headers
  extraHeaders            <<<END_extraHeaders
# Headers go below this line
# Headers go above this line
  END_extraHeaders


  rewrite  {

  }
  addDefaultCharset       off

  phpIniOverride  {

  }
}

rewrite  {
enable                  1
autoLoadHtaccess        1
logLevel                0
}

vhssl  {
keyFile                 /etc/letsencrypt/live/\$VH_NAME/privkey.pem
certFile                /etc/letsencrypt/live/\$VH_NAME/fullchain.pem
certChain               1
sslProtocol             24
ciphers                 EECDH+AESGCM:EDH+AESGCM:AES256+EECDH:AES256+EDH:ECDHE-RSA-AES128-GCM-SHA384:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA128:DHE-RSA-AES128-GCM-SHA384:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES128-GCM-SHA128:ECDHE-RSA-AES128-SHA384:ECDHE-RSA-AES128-SHA128:ECDHE-RSA-AES128-SHA:ECDHE-RSA-AES128-SHA:DHE-RSA-AES128-SHA128:DHE-RSA-AES128-SHA128:DHE-RSA-AES128-SHA:DHE-RSA-AES128-SHA:ECDHE-RSA-DES-CBC3-SHA:EDH-RSA-DES-CBC3-SHA:AES128-GCM-SHA384:AES128-GCM-SHA128:AES128-SHA128:AES128-SHA128:AES128-SHA:AES128-SHA:DES-CBC3-SHA:HIGH:!aNULL:!eNULL:!EXPORT:!DES:!MD5:!PSK:!RC4
enableECDHE             1
renegProtection         1
sslSessionCache         1
enableSpdy              15
enableQuic              1
enableStapling           1
ocspRespMaxAge           86400
}
EOF
        chown -R lsadm:lsadm ${VHDIR}/*
    else
        echo "Targeted file already exist, skip!"
    fi
}
set_server_conf() {
    if [ ${WWW} = 'TRUE' ]; then
        NEWKEY="  map                     ${MY_DOMAIN2} ${MY_DOMAIN}, ${MY_DOMAIN2}"
        local TEMP_DOMAIN=${MY_DOMAIN2}
    else
        NEWKEY="  map                     ${MY_DOMAIN} ${MY_DOMAIN}"    
        local TEMP_DOMAIN=${MY_DOMAIN}
    fi
    PORT_ARR=$(grep "address.*:[0-9]"  ${WEBCF} | awk '{print substr($2,3)}')
    if [  ${#PORT_ARR[@]} != 0 ]; then
        for PORT in ${PORT_ARR[@]}; do 
            line_insert ":${PORT}$"  ${WEBCF} "${NEWKEY}" 2
        done
    else
        echo 'No listener port detected, listener setup skip!'    
    fi
    echo "
virtualhost ${TEMP_DOMAIN} {
vhRoot                  ${WWW_PATH}/${MY_DOMAIN}
configFile              ${VHDIR}/${MY_DOMAIN}/vhconf.conf
allowSymbolLink         1
enableScript            1
restrained              1
setUIDMode              2
}" >>${WEBCF}
}
update_vh_conf(){
    sed -i 's|localhost|'${EMAIL}'|g' ${VHDIR}/${MY_DOMAIN}/vhconf.conf
    sed -i "s|\$VH_NAME|'${MY_DOMAIN}|g" ${VHDIR}/${MY_DOMAIN}/vhconf.conf
    # sed -i 's|'${LSDIR}'/conf/example.key|/etc/letsencrypt/live/'${MY_DOMAIN}'/privkey.pem|g' ${VHDIR}/${MY_DOMAIN}/vhconf.conf
    # sed -i 's|'${LSDIR}'/conf/example.crt|/etc/letsencrypt/live/'${MY_DOMAIN}'/fullchain.pem|g' ${VHDIR}/${MY_DOMAIN}/vhconf.conf
    echo "\ncertificate has been successfully installed..."  
}
main_set_vh(){
    create_folder ${WWW_PATH}
    DOCHM="${WWW_PATH}/${1}/html"
    if [ ${DOMAIN_SKIP} = 'OFF' ]; then
        set_vh_conf
        set_server_conf
        restart_lsws
        echo "Vhost created success!"
    fi    
}
verify_domain() {
    curl -Is http://${MY_DOMAIN}/ | grep -i LiteSpeed >/dev/null 2>&1
    if [ ${?} = 0 ]; then
        echo "${MY_DOMAIN} check PASS"
    else
        echo "${MY_DOMAIN} inaccessible, skip!"
        DOMAIN_PASS='OFF'
    fi
    if [ ${WWW} = 'TRUE' ]; then
        curl -Is http://${MY_DOMAIN}/ | grep -i LiteSpeed >/dev/null 2>&1
        if [ ${?} = 0 ]; then
            echo "${MY_DOMAIN2} check PASS"
        else
            echo "${MY_DOMAIN2} inaccessible, skip!"
            DOMAIN_PASS='OFF'
        fi
    fi
}
input_email() {
    if [ ${SILENT} = 'OFF' ]; then
    	while true; do
            printf "%s" "Please enter your E-mail: "
            read EMAIL
            echo "The E-mail you entered is: ${EMAIL}"
            printf "%s" "Please verify it is correct. [y/N]: "
            read TMP_YN
            if [[ "${TMP_YN}" =~ ^(y|Y) ]]; then
                break
            fi    
	    done
    fi
    if [[ ! ${EMAIL} =~ ${CKREG} ]]; then
    	echo "\nPlease enter a valid E-mail, skip!\n"
        EMAIL_SKIP='ON'
    fi	
}
apply_lecert() {
    if [ ${WWW} = 'TRUE' ]; then
        certbot certonly --non-interactive --agree-tos -m ${EMAIL} --webroot -w ${DOCHM} -d ${MY_DOMAIN} -d ${MY_DOMAIN2}
    else
        certbot certonly --non-interactive --agree-tos -m ${EMAIL} --webroot -w ${DOCHM} -d ${MY_DOMAIN}
    fi
    if [ ${?} -eq 0 ]; then
        update_vh_conf
    else
        echo "Oops, something went wrong..."
        exit 1
    fi
}
hook_certbot() {
    sed -i 's/0.*/&  --deploy-hook "\/usr\/local\/lsws\/bin\/lswsctrl restart"/g' ${BOTCRON}
    check_duplicate 'restart' ${BOTCRON}
    if [ ${?} = 0 ]; then
        echo 'Certbot hook update success'
    else
        echo 'Please check certbot crond!'
    fi
}
force_https() {
    if [ ${SILENT} = 'OFF' ]; then
        printf "%s" "Do you wish to add a force https redirection rule? [y/N]: "
        read TMP_YN
        if [[ "${TMP_YN}" =~ ^(y|Y) ]]; then
            FORCE_HTTPS='ON'
        fi  
    fi    
    if [ ${FORCE_HTTPS} = 'ON' ]; then
        create_file "${DOCHM}/.htaccess"
        check_duplicate 'https://' "${DOCHM}/.htaccess"   
        if [ ${?} = 1 ]; then
            echo "$(echo '
### Forcing HTTPS rule start
RewriteEngine On
RewriteCond %{SERVER_PORT} 80
RewriteRule (.*) https://%{HTTP_HOST}%{REQUEST_URI} [R=301,L]
### Forcing HTTPS rule end
            ' | cat - ${DOCHM}/.htaccess)" >${DOCHM}/.htaccess
            restart_lsws
            echo "Force HTTPS rules added success!" 
        else
            echo "Force HTTPS rules already existed, skip!"
        fi
    fi 
}
check_empty(){
    if [ -z "${1}" ]; then
        echo "\nPlease input a value! exit!\n"
        exit 1
    fi
}
check_www_domain(){
    CHECK_WWW=$(echo "${1}" | cut -c1-4)
    if [[ ${CHECK_WWW} == www. ]]; then
        WWW='TRUE'
        MY_DOMAIN2=$(echo "${1}" | cut -c 5-)
    else
        MY_DOMAIN2="${1}"
    fi
}
domain_input(){
    if [ ${SILENT} = 'OFF' ]; then
        while true; do
            echo -e "Please enter your domain: e.g. www.domain.com or sub.domain.com"
            printf "%s" "Your domain: "
            read MY_DOMAIN
            echo "The domain you put is: ${MY_DOMAIN}"
            printf "%s" "Please verify it is correct. [y/N]: "
            read TMP_YN
            if [[ "${TMP_YN}" =~ ^(y|Y) ]]; then
                break
            fi    
        done
    fi
    check_empty ${MY_DOMAIN}
    check_duplicate ${MY_DOMAIN} ${WEBCF}
    if [ ${?} = 0 ]; then
        echo "domain existed, skip!"
        DOMAIN_SKIP='ON'
    fi
    check_www_domain ${MY_DOMAIN}
}
issue_cert(){
    if [ ${SILENT} = 'OFF' ]; then
        printf "%s" "Do you wish to issue a Let's encrypt certificate for this domain? [y/N]: "
        read TMP_YN
        if [[ "${TMP_YN}" =~ ^(y|Y) ]]; then
            ISSUECERT='ON'
        fi  
    fi    
    if [ ${ISSUECERT} = 'ON' ]; then
        verify_domain
        if [ ${DOMAIN_PASS} = 'ON' ]; then
            input_email
            if [ ${EMAIL_SKIP} = 'OFF' ]; then
                apply_lecert
                hook_certbot
            fi    
        else
            show_help 2   
        fi    
    fi
}

end_msg(){
    echo 'Setup finished!'
}    

main() {
    check_root
    check_provider
    check_home_path
    check_os
    domain_input
    main_set_vh ${MY_DOMAIN}
    issue_cert
    check_which_cms
    check_install_wp
    check_install_cp
    force_https
    end_msg
}

while [ ! -z "${1}" ]; do
    case $1 in
        -[dD] | --domain) shift
            if [ "${1}" = '' ]; then
                show_help 1
            else
                MY_DOMAIN="${1}"
                SILENT='ON'
            fi
        ;;
        -le | -LE | --letsencrypt) shift
            if [ "${1}" = '' ] || [[ ! ${1} =~ ${CKREG} ]]; then
                echo "\nPlease enter a valid E-mail, exit!\n"   
                exit 1
            else
                ISSUECERT='ON'
                EMAIL="${1}"
            fi
        ;;
        -[fF] | --force-https)
            FORCE_HTTPS='ON'
        ;;
        -[hH] | --help)
            show_help 1
        ;;
        -[wW] | --wordpress)
            WORDPRESS='ON'
        ;;
        -[cC] | --classicpress)
            CLASSICPRESS='ON'
        ;;        
        *)
            echo "unknown argument..."
            show_help 1
        ;;
    esac
    shift
done
main
exit 0

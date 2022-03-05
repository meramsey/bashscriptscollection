#!/usr/bin/env bash
## Author: Michael Ramsey
## Objective: Opencart Hardener: change default admin path, Enable HTTPS, and secure permissions.
## https://gitlab.com/mikeramsey/
## 
## How to use. start script and optionally specify custom admin folder name and OpenCart document root
# ./opencart_hardener.sh customadmin /full/path/to/opencart/docroot/
# sh opencart_hardener.sh customadmin /home/username/public_html/


CUSTOMADMIN="${1:-ogadmin69}"

#Default Document root
DEFAULTDOCROOT=$("$HOME"/public_html); #echo $DEFAULTDOCROOT

#If no Document root specified fallback to default document root
DOCROOT="${2:-$DEFAULTDOCROOT}"

#Strip trailing slash "/" from path
DOCROOT=$(echo "$DOCROOT"| sed 's:/*$::')

echo user name: "$USER", user home: "$HOME"
echo ""

echo "Opencart Document Root: $DOCROOT"
echo ""

echo '1. Finding current Opencart Base URL from config.php'
#define('HTTP_SERVER', 'https://domain.com/');
# https://domain.com/
OCBASEURL=$(grep HTTP_SERVER "$DOCROOT"/config.php | grep -Eo "(http|https)://[a-zA-Z0-9./?=_-]*")
echo ""

echo "Found: $OCBASEURL"
echo ""

echo '2. Enable HTTPS'
echo ""

echo "Enabling HTPPS in $DOCROOT/.htaccess"
echo ""

echo 'Create SSL rewrite rules tmp file /tmp/opencartsslrewrite'
cat >> /tmp/opencartsslrewrite <<EOL
# Force https everywhere
RewriteCond %{HTTPS} off
RewriteRule ^(.*)$ https://%{HTTP_HOST}%{REQUEST_URI} [L,R=301]

#Upgrade insecure requests
<ifModule mod_headers.c>
Header always set Content-Security-Policy "upgrade-insecure-requests;"
</IfModule>
EOL
echo ""

echo 'Append current htaccess rules to redirect to SSL'
cat "$DOCROOT"/.htaccess >> /tmp/opencartsslrewrite
echo ""

echo "backup current .htaccess to $DOCROOT/.htaccess-bak_$(date '+%Y-%m-%d_%H:%M:%S')"
mv "$DOCROOT"/.htaccess "$DOCROOT"/.htaccess-bak_"$(date '+%Y-%m-%d_%H:%M:%S')"
echo ""

echo 'Place new current htaccess with SSL rewrite rules at top' 
cp /tmp/opencartsslrewrite "$DOCROOT"/.htaccess
echo ""

echo "Enforce HTTPS: $DOCROOT/{config.php,admin/config.php}"
sed -i 's|http:|https:|g' "$DOCROOT"/{config.php,admin/config.php}
echo ""
# -admin/config.php

echo "3. Change admin to custom folder $DOCROOT/${CUSTOMADMIN} in admin/config.php"
# -admin/config.php
# define('HTTP_SERVER', 'http://domain.com/ogadmin69/');
# define('HTTPS_SERVER', 'https://domain.com/ogadmin69/');
# define('DIR_APPLICATION', '/home/username/public_html/ogadmin69/');
grep -rl '/admin/' "$DOCROOT"/admin/config.php | xargs sed -i "s|/admin/|/$CUSTOMADMIN/|g"
echo ""

#VQMOD Detection and modification
VQMODSTARTBLOCK="START REPLACES"
VQMODPART1='$replaces[] = array'
VQMODPART2="('~^admin\b~', '${CUSTOMADMIN}');"
VQMODCUSTOMADMIN="$VQMODPART1${VQMODPART2}"

FILE="$DOCROOT/vqmod/pathReplaces.php"
if [ -f $FILE ]; then
   echo "vQmod file $FILE exists. Configuring with custom admin path"
   sed -i "/$VQMODSTARTBLOCK/ a\ $VQMODCUSTOMADMIN" "$FILE"
else
   echo "No vQmod install detected: '$FILE' not found. Proceeding"
fi
echo ""

echo "4. Move files from $DOCROOT/admin to $DOCROOT/${CUSTOMADMIN}"
rsync -azh --remove-source-files --info=progress2 "$DOCROOT"/admin/ "$DOCROOT"/"${CUSTOMADMIN}"/
echo ""

echo '5. Remove empty admin source folders after admin folder moved'
find "$DOCROOT"/admin -mindepth 1 -type d -empty -delete
echo ""

echo '6. Setup deny alls for Catalog,System,default admin folder'
echo ""
#Catalog
cat >> "$DOCROOT"/catalog/.htaccess <<EOL
<FilesMatch "\.(php|twig|txt)$">
Order Deny,Allow
Deny from all
#Allow from "your ip address"
</FilesMatch>
EOL

#Wget option
#wget -O $DOCROOT/catalog/.htaccess https://gitlab.com/mikeramsey/opencart-hardener/raw/master/catalog_htaccess

#System
#cat >> "$DOCROOT"/system/.htaccess  <<EOL
#<Files *.*>
#Order Deny,Allow
#Deny from all
#Allow from "your ip address"
#</Files>
#EOL

#Wget option
#wget -O $DOCROOT/system/.htaccess https://gitlab.com/mikeramsey/opencart-hardener/raw/master/system_htaccess

#Honeypot Original OCAdmin
cat >> "$DOCROOT"/admin/.htaccess  <<EOL
Order Deny,Allow
Deny from all

#rickroll hackers
ErrorDocument 403 https://www.youtube.com/watch?v=dQw4w9WgXcQ
EOL

#Wget option
#wget -O $DOCROOT/admin/.htaccess https://gitlab.com/mikeramsey/opencart-hardener/raw/master/default_admin_htacces


#Custom Admin
cat >> "$DOCROOT"/"${CUSTOMADMIN}"/.htaccess  <<EOL
Order Deny,Allow
Deny from all
# whitelist home IP address
#allow from 1.2.3.4
 
#whitelist office IP Address
#allow from 1.2.3.5

#whitelist vpn IP Address
#allow from 1.2.3.6


# softy1 NL Amsterdam
Allow from 93.158.203.109

#softy2 NL Amsterdam
Allow from 93.158.203.91

#softy3 US Miami
Allow from 144.202.38.159

#softy4 US Chicago
Allow from 8.12.16.99

#softy5 US New Jersey
Allow from 45.32.6.181

#softy6 US Seattle
Allow from 144.202.93.38

#softy7 US Los Angeles
Allow from 45.76.174.145

#softy8 AU Sydney
Allow from 149.28.162.174

#softy9 JP Tokyo
Allow from 202.182.105.46

#softy10 HK Singapore
Allow from 149.28.151.117

#softy11 FR Paris
Allow from 140.82.54.59

#softy12 DE Frankfurt
Allow from 104.238.167.21

#softy13 UK London
Allow from 45.63.101.64

#Softy14 NL Amsterdam
Allow from 93.158.203.100

#softy15 NL Amsterdam
Allow from 93.158.203.112

#softy16 CA Toronto
Allow from 155.138.147.206
ErrorDocument 403 https://www.youtube.com/watch?v=dQw4w9WgXcQ
EOL

#Wget option
#wget -O $DOCROOT/${CUSTOMADMIN}/.htaccess https://gitlab.com/mikeramsey/opencart-hardener/raw/master/custom_admin_htaccess_WTS


echo '7. Harden permissions'
echo ""
#chmod 444 $DOCROOT/config.php
#chmod 444 $DOCROOT/index.php
#chmod 444 $DOCROOT/${CUSTOMADMIN}/config.php
#chmod 444 $DOCROOT/${CUSTOMADMIN}/index.php
#chmod 444 $DOCROOT/system/startup.php

chmod 444 "$DOCROOT"/{config.php,index.php,system/startup.php,"${CUSTOMADMIN}"/{config.php,index.php}}
#chmod 444 $DOCROOT/${CUSTOMADMIN}/{config.php,index.php}

#Strip trailing slash "/" from OCBASEURL 
OCBASEURL=$(echo "$OCBASEURL"| sed 's:/*$::')

echo 'OpenCart Hardening completed!'
echo ""
echo "New OpenCart Admin login page: $OCBASEURL/${CUSTOMADMIN}"
echo "New OpenCart Admin path: $DOCROOT/${CUSTOMADMIN}"
echo ""
OCBASEDOMAIN=$(echo "$OCBASEURL" | awk -F/ '{print $3}')

cat >> "$HOME"/opencart_hardener_updater_"$OCBASEDOMAIN".sh  <<EOL
#!/usr/bin/env bash
## Author: Michael Ramsey
## Objective: Opencart Hardener Updater: After installing new plugins or themes which installed to default admin area this should be run to move the files to the custom admin area.
## https://gitlab.com/mikeramsey/
## 
## How to use. start script to migrate stuff from default Opencart admin folder to the customadmin folder
# ./opencart_hardener_updater.sh 
# sh opencart_hardener_updater.sh
#Custom upgrade script for $OCBASEURL

echo "Move files from $DOCROOT/admin to $DOCROOT/${CUSTOMADMIN}"
rsync -azh --remove-source-files --exclude '.htaccess' --info=progress2 "$DOCROOT"/admin/ "$DOCROOT"/"${CUSTOMADMIN}"/

echo 'Remove empty admin source folders after files from default admin folder moved custom admin folder'
find "$DOCROOT"/admin -mindepth 1 -type d -empty -delete

EOL

echo ""
echo "After upgrading or installing plugins themes run the custom upgrade bash script: $HOME/opencart_hardener_updater_$OCBASEDOMAIN.sh"
echo ""
echo "Or run the below commands manually to move files from default admin to custom admin folder"
echo ""
echo "rsync -azh --remove-source-files --info=progress2 $DOCROOT/admin/ $DOCROOT/${CUSTOMADMIN}/"
echo "find $DOCROOT/admin -mindepth 1 -type d -empty -delete"


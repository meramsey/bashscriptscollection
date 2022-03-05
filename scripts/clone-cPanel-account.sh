#!/usr/bin/env bash
#https://forums.cpanel.net/threads/cannot-create-an-email-account-error-message.218471/#post913162

originaldomain=""
oldusername=""
newdomain=""
newusername=""

#mysqldump -u root $DB > $DB.sql
#sed -i 's/${oldusername}/${newusername}/g' $DB.sql
#sed -i 's/${originaldomain}/${newdomain}/g'
#mysql -u root $DB < $DB.sql


grep -rl "${oldusername}" /home/${newusername} | xargs sed -i 's/${oldusername}/${newusername}/g'
grep -rl "${originaldomain}" /home/${newusername} | xargs sed -i 's/${originaldomain}/${newdomain}/g'


sudo rsync --ignore-existing -r /home/${oldusername}/ /home/${newusername}/
sudo cagefsctl --enable ${newusername} && sudo cagefsctl --update-etc ${newusername}
link="https://gitlab.com/wizardassistantscripts/fixperms/-/raw/master/fixperms.sh"; bash <(curl -s $link || wget -qO - $link) -v -all "${newusername}"
sudo /scripts/mailperm --verbose ${newusername}
/usr/local/cpanel/bin/update_horde_config --user=${newusername} --full


mv /home/${newusername}/mail/${originaldomain} /home/${newusername}/mail/${newdomain}   
mv /home/${newusername}/etc/${originaldomain} /home/${newusername}/etc/${newdomain}   
mv /home/${newusername}/.cpanel/datastore/_Cpanel::Quota.pm__${oldusername} /home/${newusername}/.cpanel/datastore/_Cpanel::Quota.pm__${newusername}
mv /home/${newusername}/.cpanel/caches/filesys/~home~${oldusername}.stat /home/${newusername}/.cpanel/caches/filesys/~home~${newusername}.stat
mv /home/${newusername}/.cpanel/caches/filesys/~home~${oldusername} /home/${newusername}/.cpanel/caches/filesys/~home~${newusername}

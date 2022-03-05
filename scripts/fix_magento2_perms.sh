#!/bin/sh
#Magento 2 fixperms. run from document root for the magento installation

find . -type f -exec chmod 644 {} \;
find . -type d -exec chmod 755 {} \; 
find ./var -type d -exec chmod 777 {} \;
find ./pub/media -type d -exec chmod 777 {} \;
find ./pub/static -type d -exec chmod 777 {} \;
chmod 777 ./app/etc;
chmod 644 ./app/etc/*.xml;
echo 'Completed' | tee magento-fixperms-status.txt

#!/usr/bin/env bash
whmapi1 php_ini_set_directives directive-1=max_execution_time:300 directive-2=max_input_time:-1 directive-3=memory_limit:2048M directive-4=post_max_size:256M directive-5=upload_max_filesize:150M version=ea-php54 > raise_php_defaults.log
whmapi1 php_ini_set_directives directive-1=max_execution_time:300 directive-2=max_input_time:-1 directive-3=memory_limit:2048M directive-4=post_max_size:256M directive-5=upload_max_filesize:150M version=ea-php55 >> raise_php_defaults.log
whmapi1 php_ini_set_directives directive-1=max_execution_time:300 directive-2=max_input_time:-1 directive-3=memory_limit:2048M directive-4=post_max_size:256M directive-5=upload_max_filesize:150M version=ea-php56 >> raise_php_defaults.log
whmapi1 php_ini_set_directives directive-1=max_execution_time:300 directive-2=max_input_time:-1 directive-3=memory_limit:2048M directive-4=post_max_size:256M directive-5=upload_max_filesize:150M version=ea-php70 >> raise_php_defaults.log
whmapi1 php_ini_set_directives directive-1=max_execution_time:300 directive-2=max_input_time:-1 directive-3=memory_limit:2048M directive-4=post_max_size:256M directive-5=upload_max_filesize:150M version=ea-php71 >> raise_php_defaults.log
whmapi1 php_ini_set_directives directive-1=max_execution_time:300 directive-2=max_input_time:-1 directive-3=memory_limit:2048M directive-4=post_max_size:256M directive-5=upload_max_filesize:150M version=ea-php72 >> raise_php_defaults.log
echo 'Raise PHP defaults script completed please check raise_php_defaults.log'

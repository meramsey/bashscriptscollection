#!/usr/bin/env bash
# Get OLS/CSF WEB UI admin passes from csf.conf
## How to use:
## Directly from github as root user:
# link="https://raw.githubusercontent.com/meramsey/blaqpanel/main/scripts/get_ols_csf_admin_pass.sh";sh <(curl $link || wget -O - $link);

## Manually download
# wget -q -O /usr/local/blaqpanel/bin/get_ols_csf_admin_pass.sh https://raw.githubusercontent.com/meramsey/blaqpanel/main/scripts/get_ols_csf_admin_pass.sh && chmod +x /usr/local/blaqpanel/bin/get_ols_csf_admin_pass.sh; 
## Then execute:
# /usr/local/blaqpanel/bin/get_ols_csf_admin_pass.sh



#!/usr/bin/env bash
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 
   exit 1
fi


grep -E 'UI_PASS' /etc/csf/csf.conf| sed -e 's|UI_PASS = "||' -e 's/^"//' -e 's/"$//'
#!/usr/bin/env bash
#
# Reset CageFS for an account
#
#
#

_acc=$1

_reset_cage() {
  echo "Enabling CageFS for ${_acc}..."
  if cagefsctl --enable ${_acc}; then echo [OK]; fi

  echo "Updating CageFS for ${_acc}..."
  if cagefsctl --update-etc ${_acc}; then echo [OK]; fi
}

if [ -n "${_acc}" ]; then
  if grep -wq ${_acc} /etc/trueuserdomains; then
    _reset_cage
  else
    echo -e "${_acc} - is not a valid username."
  fi
else
  echo -e "Please specify a username. \n\nSyntax: ${0} [username]"
fi


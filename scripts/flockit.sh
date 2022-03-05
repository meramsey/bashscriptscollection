#!/usr/bin/env bash
# flockit.sh -- Singleton command execution for Linux/BSD via flock with fallback if not present
#
# Makes sure only one instance of the same process is running at once. This
# script does nothing if it was previously used to launch the same command
# and that instance is still running.
#
# /tmp/flockit-<md5sum of the arguments>.pid is used as the lock file. This file
# is removed if the process it refers to isn't actually running.
#
# Usage:   ./flockit.sh <command> <arguments>
# Example: ./flockit.sh wget --mirror http://mysite.com
#
# See http://patrickmylund.com/projects/one/ for more information.

# Switch out LFILE for something static to avoid running md5sum and cut, e.g.
# LFILE=/tmp/flockit-{pid}.pid
LFILE="/tmp/flockit-$(echo "$@" | md5sum | cut -d\  -f1).pid"


if ! command -v flock &> /dev/null
then
    echo "Warning: flock not installed using one.sh"
    if [ -e "${LFILE}" ] && kill -0 "$(cat ${LFILE})"; then
       exit
    fi

    trap "rm -f ${LFILE}; exit" INT TERM EXIT
    echo $$ > "${LFILE}"
    
    $@

    rm -f "${LFILE}"
fi

# /usr/bin/flock -w 0 /tmp/flockit-{pid}.pid <command>
flock -w 0 "${LFILE}" $@
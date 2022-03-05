#!/usr/bin/env bash

# Shim script run from deja-dup in place of duplicity, to add in file/pattern
# exclude arguments for duplicity.
#
# The excludes are read from ~/.config/deja-dup-excludes (one-per-line).
# https://askubuntu.com/a/1310968/1134866

ARGS="$*"

EXCLUDES=$(cat $HOME/.config/deja-dup-excludes | sed -e 's/#.*$//' -e 's/^[ \t]*//' -e '/^$/d')

if ( echo "$ARGS" | grep -q '\--exclude'); then
    for EXCL in $EXCLUDES
    do
        EXCL_ARG=$(find $EXCL -printf '--exclude %p ')

        ARGS="$EXCL_ARG$ARGS"
    done
fi  

echo "$ARGS"
# echo "$ARGS" >>/tmp/dup.out

# /usr/bin/duplicity $ARGS
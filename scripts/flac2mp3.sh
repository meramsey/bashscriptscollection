#!/usr/bin/env bash
for f in *.flac
do
OUTF=`echo "$f" | sed s/\.flac$/.mp3/g`

ARTIST=`metaflac "$f" --show-tag=ARTIST | sed s/.*=//g`
TITLE=`metaflac "$f" --show-tag=TITLE | sed s/.*=//g`
ALBUM=`metaflac "$f" --show-tag=ALBUM | sed s/.*=//g`
GENRE=`metaflac "$f" --show-tag=GENRE | sed s/.*=//g`
TRACKNUMBER=`metaflac "$f" --show-tag=TRACKNUMBER | sed s/.*=//g`
DATE=`metaflac "$f" --show-tag=DATE | sed s/.*=//g`

flac -c -d "$f" | lame --replaygain-accurate -q 0 --vbr-new -V 3 - "$OUTF"
id3 -t "$TITLE" -T "${TRACKNUMBER:-0}" -a "$ARTIST" -A "$ALBUM" -y "$DATE" -g "${GENRE:-12}" "$OUTF"
done
mkdir temp
mv *.mp3 ./temp  

#!/bin/bash
################################################################################
#
# refresh-updater-files.sh - Read update files, compare with source scripts
# and update files as needed.
# (C) 2015, Jared Ballou <insurgency@jballou.com>
# Released under the GPLv2
#
################################################################################

#Files to update
PLUGINS=$(cat plugins.jballou.txt)
#Loop through all files
for PLUGIN in $PLUGINS
do
	#Get base plugin name and source script
	BINARY=../plugins/$PLUGIN.smx
	SCRIPT=../scripting/$PLUGIN.sp
#	echo "[$PLUGIN](plugins/$PLUGIN.smx?raw=true): " > $PLUGIN.md
	echo "#### CVAR List" > cvar/$PLUGIN.md
	grep CreateConVar $SCRIPT | grep -v '_version"' | awk -F'"' -v OFS='' '{ for (i=2; i<=NF; i+=2) gsub(",", ";;", $i) } 1' | cut -d'(' -f2 | awk -F',' '{print " * "$1":"$3" (default:"$2")"}' |sed -e 's/"//g' -e 's/;;/,/g' >> cvar/$PLUGIN.md
	if [ ! -e description/$PLUGIN.md ]; then touch description/$PLUGIN.md; fi
	if [ ! -e todo/$PLUGIN.md ]; then touch todo/$PLUGIN.md; fi
	if [ ! -e dependencies/$PLUGIN.md ]; then touch dependencies/$PLUGIN.md; fi
done
git add *

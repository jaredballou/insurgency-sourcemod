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
	grep CreateConVar $SCRIPT | grep -v '_version"' | awk -F'"' -v OFS='' '{ for (i=2; i<=NF; i+=2) gsub(",", ";;", $i) } 1' | cut -d'(' -f2 | awk -F',' '{print " * "$1":"$3" (default:"$2")"}' |sed -e 's/"//g' -e 's/;;/,/g' > plugins/cvar/$PLUGIN.md
	if [ ! -e plugins/description/$PLUGIN.md ]; then touch plugins/description/$PLUGIN.md; fi
	if [ ! -e plugins/todo/$PLUGIN.md ]; then touch plugins/todo/$PLUGIN.md; fi
	if [ ! -e plugins/dependencies/$PLUGIN.md ]; then touch plugins/dependencies/$PLUGIN.md; fi

        NEWVER=$(grep -i '^#define.*_version' $SCRIPT | cut -d'"' -f2)
        NEWNAME=$(grep -i '^#define.*PLUGIN_NAME' $SCRIPT | cut -d'"' -f2)
        if [ "$NEWNAME" == "" ]
        then
                NEWNAME=$(grep -m1 -P '^[\s]*name[\s]*=.*"' $SCRIPT | cut -d'"' -f2)
        fi
	NEWNAME=$(echo $NEWNAME | sed -e 's/\[INS\] //')
        NEWDESC=$(grep -i '^#define.*PLUGIN_DESCRIPTION' $SCRIPT | cut -d'"' -f2)
        if [ "$NEWDESC" == "" ]
        then
                NEWDESC=$(grep -m1 -P '^[\s]*description[\s]*=.*"' $SCRIPT | cut -d'"' -f2)
        fi
        NEWTITLE=$(echo "$NEWNAME - $NEWDESC" | sed -e 's/[]\/$*.^|[]/\\&/g')
	echo "### $NEWNAME (version $NEWVER)" > plugins/$PLUGIN.md
	echo "$NEWDESC" >> plugins/$PLUGIN.md
	echo "[Plugin](plugins/$PLUGIN.smx?raw=true) - [Source](scripting/$PLUGIN.sp)" >> plugins/$PLUGIN.md
	cat plugins/description/$PLUGIN.md >> plugins/$PLUGIN.md
	echo "#### Dependencies" >> plugins/$PLUGIN.md
	cat plugins/dependencies/$PLUGIN.md >> plugins/$PLUGIN.md
	echo "#### CVAR List" >> plugins/$PLUGIN.md
	cat plugins/cvar/$PLUGIN.md >> plugins/$PLUGIN.md
	echo "#### Todo" >> plugins/$PLUGIN.md
	cat plugins/todo/$PLUGIN.md >> plugins/$PLUGIN.md

done
git add *

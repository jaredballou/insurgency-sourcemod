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
TOC=include/TOC.md
#Loop through all files
echo > $TOC
for PLUGIN in $PLUGINS
do
	echo "Processing $PLUGIN"
	#Get base plugin name and source script
	BINARY=../plugins/$PLUGIN.smx
	SCRIPT=../scripting/$PLUGIN.sp
	if [ ! -e plugins/description/$PLUGIN.md ]; then touch plugins/description/$PLUGIN.md; fi
	if [ ! -e plugins/todo/$PLUGIN.md ]; then touch plugins/todo/$PLUGIN.md; fi

	grep CreateConVar $SCRIPT | grep -v '_version"' | sed -e 's/""/NULLSTRING/g' | awk -F'"' -v OFS='' '{ for (i=2; i<=NF; i+=2) gsub(",", ";;", $i) } 1' | cut -d'(' -f2 | sed -e 's/"//g' | awk -F',' '{print $1" "$2" "$3}' | sed -e 's/;;/,/g' | awk '{printf " * \""$1"\" \""$2"\" //"$3;for(i=4;i<=NF;i++){printf " %s", $i}printf "\n"}' | sed -e 's/NULLSTRING//g' > plugins/cvar/$PLUGIN.md

	echo -ne > plugins/dependencies/$PLUGIN.md
	for CFGFILE in $(grep -Po 'LoadGameConfigFile\([^\)]+\)' $SCRIPT | cut -d'"' -f2)
	do
		echo " * [gamedata/$CFGFILE.txt](gamedata/$CFGFILE.txt)" >> plugins/dependencies/$PLUGIN.md
	done
	for TRANSFILE in $(grep -Po 'LoadTranslations\([^\)]+\)' $SCRIPT | cut -d'"' -f2)
	do
		echo " * [translations/$TRANSFILE.txt](translations/$TRANSFILE.txt)" >> plugins/dependencies/$PLUGIN.md
	done

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
	echo -e " * <a href='$NEWNAME'>$NEWNAME (version $NEWVER)</a>" >> $TOC
	echo -e "---\n### <a name='$NEWNAME'>$NEWNAME (version $NEWVER)</a>" > plugins/$PLUGIN.md
	echo "$NEWDESC" >> plugins/$PLUGIN.md
	echo "" >> plugins/$PLUGIN.md
	echo " * [Plugin - $PLUGIN.smx](plugins/$PLUGIN.smx?raw=true)" >> plugins/$PLUGIN.md
	echo " * [Source - $PLUGIN.sp](scripting/$PLUGIN.sp)" >> plugins/$PLUGIN.md
	echo "" >> plugins/$PLUGIN.md
	cat plugins/description/$PLUGIN.md >> plugins/$PLUGIN.md
	echo "" >> plugins/$PLUGIN.md
	if [ $(wc plugins/dependencies/$PLUGIN.md | awk '{print $2}') -gt 0 ]
	then
		echo "#### Dependencies" >> plugins/$PLUGIN.md
		cat plugins/dependencies/$PLUGIN.md >> plugins/$PLUGIN.md
		echo "" >> plugins/$PLUGIN.md
	fi
	if [ $(wc plugins/cvar/$PLUGIN.md | awk '{print $2}') -gt 0 ]
	then
		echo "#### CVAR List" >> plugins/$PLUGIN.md
		cat plugins/cvar/$PLUGIN.md >> plugins/$PLUGIN.md
		echo "" >> plugins/$PLUGIN.md
	fi
	if [ $(wc plugins/todo/$PLUGIN.md | awk '{print $2}') -gt 0 ]
	then
		echo "#### Todo" >> plugins/$PLUGIN.md
		cat plugins/todo/$PLUGIN.md >> plugins/$PLUGIN.md
		echo "" >> plugins/$PLUGIN.md
	fi
done
cat include/HEADER.md include/TOC.md plugins/*.md include/FOOTER.md > ../README.md

git add *

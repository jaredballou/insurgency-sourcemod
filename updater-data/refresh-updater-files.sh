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
FILES=$(ls update-*.txt)
#Base URL for these files
URLBASE="http://ins.jballou.com/sourcemod"

#Loop through all files
for FILE in $FILES
do
	#Get base plugin name and source script
	PLUGIN=$(echo $FILE | sed -e 's/^update-//' -e 's/\.txt$//')
	SCRIPT=../scripting/$PLUGIN.sp

	#Get version from script and update file
	CURVER=$(grep '"Latest".*"[0-9\.]*"' $FILE | cut -d'"' -f4)
	NEWVER=$(grep -i '^#define.*_version' $SCRIPT | cut -d'"' -f2)

	#Get URL from script and update file
	CURURL=$(grep -i '^#define.*UPDATE_URL' $SCRIPT | cut -d'"' -f2)
	NEWURL="$URLBASE/update-$PLUGIN.txt"

	#Get name from script and update file
	CURNAME=$(grep -i '"Notes".*"Name:' $FILE | cut -d'"' -f4)
	NEWNAME=$(grep -i '^#define.*PLUGIN_NAME' $SCRIPT | cut -d'"' -f2)
	if [ "$NEWNAME" == "" ]
	then
		NEWNAME=$(grep -m1 -P '^[\s]*name[\s]*=.*"' $SCRIPT | cut -d'"' -f2)
	fi
	NEWNAME="Name: $NEWNAME"

	#Get description from script and update file
	CURDESC=$(grep -i '"Notes".*"Description:' $FILE | cut -d'"' -f4)
	NEWDESC=$(grep -i '^#define.*PLUGIN_DESCRIPTION' $SCRIPT | cut -d'"' -f2)
	if [ "$NEWDESC" == "" ]
	then
		NEWDESC=$(grep -m1 -P '^[\s]*description[\s]*=.*"' $SCRIPT | cut -d'"' -f2)
	fi
	NEWDESC="Description: $NEWDESC"

	#Update URL in script if needed
	if [ "$CURURL" != "$NEWURL" ]
	then
		echo "Changing $PLUGIN UPDATE_URL from \"$CURURL\" to \"$NEWURL\""
		sed -e "s,$CURURL,$NEWURL," -i $SCRIPT
	fi

	#Update Name in update file
	if [ "$CURNAME" != "$NEWNAME" ]
	then
		echo "Changing $PLUGIN Name from \"$CURNAME\" to \"$NEWNAME\""
		sed -e "s\`$CURNAME\`$NEWNAME\`" -i $FILE
	fi

	#Update Description in update file
	if [ "$CURDESC" != "$NEWDESC" ]
	then
		echo "Changing $PLUGIN Description from \"$CURDESC\" to \"$NEWDESC\""
		sed -e "s\`$CURDESC\`$NEWDESC\`" -i $FILE
	fi

	#Update Version in update file
	if [ "$CURVER" != "$NEWVER" ]
	then
		echo "Bumping $PLUGIN from $CURVER to $NEWVER"
		sed -e "s/$CURVER/$NEWVER/" -i $FILE
	fi

	#Compile plugin if the script is newer than the compiled plugin. Only compile if it's already there, to avoid compiling unwanted plugins
	if [ -e "../plugins/$PLUGIN.smx" ]
	then
		if [ "$SCRIPT" -nt "../plugins/$PLUGIN.smx" ]
		then
			echo "Plugin $PLUGIN is out of date, compiling..."
			cd ../scripting
			./compile.sh $(basename $SCRIPT)
			cd ../updater-data
		fi
	fi
done

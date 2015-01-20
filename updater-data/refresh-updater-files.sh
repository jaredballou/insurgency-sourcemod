#!/bin/bash
FILES=$(ls update-*.txt)
URLBASE="http://ins.jballou.com/sourcemod"
for FILE in $FILES
do
	PLUGIN=$(echo $FILE | sed -e 's/^update-//' -e 's/\.txt$//')
	SCRIPT=../scripting/$PLUGIN.sp
	CURVER=$(grep '"Latest".*"[0-9\.]*"' $FILE | cut -d'"' -f4)
	NEWVER=$(grep -i '^#define.*_version' $SCRIPT | cut -d'"' -f2)
	CURURL=$(grep -i '^#define.*UPDATE_URL' $SCRIPT | cut -d'"' -f2)
	NEWURL="$URLBASE/update-$PLUGIN.txt"
	if [ "$CURURL" != "$NEWURL" ]
	then
		echo "Changing $PLUGIN UPDATE_URL from $CURURL to $NEWURL"
		perl -pi -e "s/$CURURL/$NEWURL/" $SCRIPT
	fi
	if [ "$CURVER" != "$NEWVER" ]
	then
		echo "Bumping $PLUGIN from $CURVER to $NEWVER"
	fi
done

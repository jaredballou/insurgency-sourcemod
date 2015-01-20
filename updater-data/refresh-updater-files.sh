#!/bin/bash
FILES=$(ls update-*.txt)
for FILE in $FILES
do
	PLUGIN=$(echo $FILE | sed -e 's/^update-//' -e 's/\.txt$//')

	CURVER=$(grep '"Latest".*"[0-9\.]*"' $FILE | cut -d'"' -f4)
	NEWVER=$(grep -i '^#define.*_version' ../scripting/$PLUGIN.sp | cut -d'"' -f2)
	if [ "$CURVER" != "$NEWVER" ]
	then
		echo "Bumping $PLUGIN from $CURVER to $NEWVER"
	fi
done

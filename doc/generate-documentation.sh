#!/bin/bash
################################################################################
#
# generate-documentation.sh
# 
# This script reads the two lists in this directory, my plugins and third party
# ones. This script pulls the information from the plugin source files and
# creates updater manifests and the Readme. Take a look in plugins for a better
# idea of how this works, note that dependencies and cvars are regenerated from
# scratch each run, so don't make any manual edits to those files.
# 
# (C) 2015, Jared Ballou <insurgency@jballou.com>
# Released under the GPLv2
#
################################################################################

#Files to update
DOC_PATH="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
SOURCEMOD_PATH="$(dirname "${DOC_PATH}")"

GITHUB_URL="https://github.com/jaredballou/insurgency-sourcemod/blob/master"

PLUGINS_FILE="${DOC_PATH}/plugins.jballou.txt"
PLUGINS_LIST=$(cat "${PLUGINS_FILE}")

TOC_FILE="${DOC_PATH}/include/TOC.md"

UPDATE_PATH="${SOURCEMOD_PATH}/updater-data"
UPDATE_URLBASE="http://ins.jballou.com/sourcemod"

LIBRARY_IGNORE="updater"

function add_file_to_update() {
	FILETYPE="${1}"
	FILEPATH="Path_SM/${2}"
	if [ $(grep -c -i "\"${FILETYPE}\"[^\"]*\"${FILEPATH}\"" "${DOC_UPDATER_FILE}") -eq 0 ]
	then
		echo "Adding ${2} to Files for ${ITEM}"
		echo -e "\t\t\"${FILETYPE}\"\t\"${FILEPATH}\"" >> "${DOC_UPDATER_FILE}"
	fi
}
#Loop through all files
echo > "${TOC_FILE}"
for ITEM in $PLUGINS_LIST
do
	echo "Processing ${ITEM}"

	# Get base plugin name and source script
	# These paths refer to their location relative to SourceMod root
	PLUGIN_PATH="plugins/${ITEM}.smx"
	SCRIPT_PATH="scripting/${ITEM}.sp"

	# These are the actual on-disk paths for the files themselves
	PLUGIN="${SOURCEMOD_PATH}/${PLUGIN_PATH}"
	SCRIPT="${SOURCEMOD_PATH}/${SCRIPT_PATH}"
	UPDATE="${UPDATE_PATH}/update-${ITEM}.txt"

	# And these are all the pieces that make up each plugin's documentation
	DOC_UPDATER_FILE="${DOC_PATH}/plugins/updater/${ITEM}.txt"
	DOC_DEPENDENCY_FILE="${DOC_PATH}/plugins/dependencies/${ITEM}.md"
	DOC_DESC_FILE="${DOC_PATH}/plugins/description/${ITEM}.md"
	DOC_TODO_FILE="${DOC_PATH}/plugins/todo/${ITEM}.md"
	DOC_CVAR_FILE="${DOC_PATH}/plugins/cvar/${ITEM}.md"
	DOC_PLUGIN_FILE="${DOC_PATH}/plugins/${ITEM}.md"

	# Create updater file if missing
	if [ ! -e "${UPDATE}" ]
	then
		echo "Creating update-${ITEM}.txt in updater-data..."
		sed -e "s/myplugin/${ITEM}/" "${UPDATE_PATH}/_template.txt" > "${UPDATE}"
	fi

	# Create all pieces of the documentation if files are missing
	for PIECE in "${DOC_UPDATER_FILE}" "${DOC_DESC_FILE}" "${DOC_TODO_FILE}"
	do
		if [ ! -e "${PIECE}" ]
		then
			echo "Creating ${PIECE}"
			touch "${PIECE}"
		fi
	done

	# Merge items in the updater file and anything we added manually to the plugins/updater text file
	egrep '"(Plugin|Source)"' "${UPDATE}" >> "${DOC_UPDATER_FILE}"

	# These are lists of the items that we need to put into the updater
	add_file_to_update "Plugin" "${PLUGIN_PATH}"
	add_file_to_update "Source" "${SCRIPT_PATH}"

	# Collect CVARs
	grep CreateConVar "${SCRIPT}" | grep -v '_version"' | sed -e 's/""/NULLSTRING/g' | awk -F'"' -v OFS='' '{ for (i=2; i<=NF; i+=2) gsub(",", ";;", $i) } 1' | cut -d'(' -f2 | sed -e 's/"//g' | awk -F',' '{print $1" "$2" "$3}' | sed -e 's/;;/,/g' | awk '{printf " * \""$1"\" \""$2"\" //"$3;for(i=4;i<=NF;i++){printf " %s", $i}printf "\n"}' | sed -e 's/NULLSTRING//g' > "${DOC_CVAR_FILE}"

	# Colelct dependencies
	echo -ne > "${DOC_DEPENDENCY_FILE}"
	INCLUDES=$(grep -o '^#include <[^>]\+' "${SCRIPT}" | cut -d'<' -f2)
	for INC in $INCLUDES
	do
		if [ $(grep "^$(basename "${INC}")\$" "${PLUGINS_FILE}" -c) -gt 0 ]
		then
			echo " * [Source Include - ${INC}.inc](${GITHUB_URL}/scripting/include/${INC}.inc?raw=true)" >> "${DOC_DEPENDENCY_FILE}"
			add_file_to_update "Source" "scripting/include/${INC}.inc"
		fi
	done
	for CFGFILE in $(grep -Po 'LoadGameConfigFile\([^\)]+\)' "${SCRIPT}" | cut -d'"' -f2)
	do
		echo " * [gamedata/${CFGFILE}.txt](${GITHUB_URL}/gamedata/${CFGFILE}.txt?raw=true)" >> "${DOC_DEPENDENCY_FILE}"
		add_file_to_update "Plugin" "gamedata/${CFGFILE}.txt"
	done
	for TRANSFILE in $(grep -Po 'LoadTranslations\([^\)]+\)' "${SCRIPT}" | cut -d'"' -f2)
	do
		echo " * [translations/${TRANSFILE}.txt](${GITHUB_URL}/translations/${TRANSFILE}.txt?raw=true)" >> "${DOC_DEPENDENCY_FILE}"
		add_file_to_update "Plugin" "translations/${TRANSFILE}.txt"
	done
	for LIBRARY in $(grep -Po 'LibraryExists\([^\)]+\)' "${SCRIPT}" | cut -d'"' -f2)
	do
		if [ "$(grep "${LIBRARY}" "${DOC_PATH}/plugins.jballou.txt")" == "${LIBRARY}" ]
		then
			echo " * [Plugin - ${LIBRARY}](#${LIBRARY})" >> "${DOC_DEPENDENCY_FILE}"
		else
			# TODO: Make this use the LIBRARY_IGNORE variable, for now just ignore updater
			if [ "${LIBRARY}" != "updater" ]
			then
				echo " * [Third-Party Plugin: ${LIBRARY}](${GITHUB_URL}/plugins/${LIBRARY}.smx?raw=true)" >> "${DOC_DEPENDENCY_FILE}"
			fi
		fi
	done

        CURURL=$(grep -i '^#define.*UPDATE_URL' "${SCRIPT}" | cut -d'"' -f2)
	NEWURL="${UPDATE_URLBASE}/update-${ITEM}.txt"

	CURVER=$(grep '"Latest".*"[0-9\.]*"' "${UPDATE}" | cut -d'"' -f4)
	NEWVER=$(grep -i '^#define.*_version' "${SCRIPT}" | cut -d'"' -f2)
        NEWNAME=$(grep -i '^#define.*PLUGIN_NAME' "${SCRIPT}" | cut -d'"' -f2)
        if [ "${NEWNAME}" == "" ]
        then
                NEWNAME=$(grep -m1 -P '^[\s]*name[\s]*=.*"' "${SCRIPT}" | cut -d'"' -f2)
        fi
	NEWNAME=$(echo "${NEWNAME}" | sed -e 's/\[INS\] //')
        NEWDESC=$(grep -i '^#define.*PLUGIN_DESCRIPTION' "${SCRIPT}" | cut -d'"' -f2)
        if [ "${NEWDESC}" == "" ]
        then
                NEWDESC=$(grep -m1 -P '^[\s]*description[\s]*=.*"' "${SCRIPT}" | cut -d'"' -f2)
        fi

	CURNOTES=$(grep -m1 -i '"Notes".*"' "${UPDATE}" | cut -d'"' -f4|sed -e 's/[]\/$*.^|[]/\\&/g')
	NEWNOTES=$(echo "${NEWNAME} - ${NEWDESC}" | sed -e 's/[]\/$*.^|[]/\\&/g')

        NEWTITLE="${NEWNAME} ${NEWVER}"
        NEWHREF=$(echo "${NEWTITLE}" | sed -e 's/ /-/g' -e 's/[^a-zA-Z0-9-]//g')

	# Update updater manifests
	if [ "${CURURL}" != "${NEWURL}" ]
	then
		echo "Changing ${ITEM} UPDATE_URL from \"${CURURL}\" to \"${NEWURL}\""
		sed -e "s,^\#define.*UPDATE_URL[\s].*\$,\#define UPDATE_URL \"${NEWURL}\"," -i "${SCRIPT}"
	fi

	#Update Name in update file
	if [ "${CURNOTES}" != "${NEWNOTES}" ]
	then
		echo "Changing ${ITEM} Title Note from \"${CURNOTES}\" to \"${NEWNOTES}\""
		sed -e "s\`\"Notes\".*\$\`\"Notes\"\t\t\"${NEWNOTES}\"\`" -i "${UPDATE}"
	fi

	#Update Version in update file
	if [ "${CURVER}" != "${NEWVER}" ]
	then
		echo "Bumping ${ITEM} from ${CURVER} to ${NEWVER}"
		sed -e "s,\"Latest\".*\$,\"Latest\"\t\t\"${NEWVER}\"," -i "${UPDATE}"
	fi

	# Update plugin documentation for readme
	echo -e " * <a href='#user-content-${ITEM}'>${NEWNAME} ${NEWVER}</a>" >> "${TOC_FILE}"

	echo -e "<a name='${ITEM}'>\n---\n### ${NEWTITLE}</a>" > "${DOC_PLUGIN_FILE}"
	echo "${NEWDESC}" >> "${DOC_PLUGIN_FILE}"
	echo "" >> "${DOC_PLUGIN_FILE}"
	echo " * [Plugin - ${ITEM}.smx](${GITHUB_URL}/plugins/${ITEM}.smx?raw=true)" >> "${DOC_PLUGIN_FILE}"
	echo " * [Source - ${ITEM}.sp](${GITHUB_URL}/scripting/${ITEM}.sp?raw=true)" >> "${DOC_PLUGIN_FILE}"
	echo "" >> "${DOC_PLUGIN_FILE}"
	cat "${DOC_DESC_FILE}" >> "${DOC_PLUGIN_FILE}"
	echo "" >> "${DOC_PLUGIN_FILE}"
	if [ $(wc "${DOC_DEPENDENCY_FILE}" | awk '{print $2}') -gt 0 ]
	then
		echo "#### Dependencies" >> "${DOC_PLUGIN_FILE}"
		cat "${DOC_DEPENDENCY_FILE}" >> "${DOC_PLUGIN_FILE}"
		echo "" >> "${DOC_PLUGIN_FILE}"
	fi
	if [ $(wc "${DOC_CVAR_FILE}" | awk '{print $2}') -gt 0 ]
	then
		echo "#### CVAR List" >> "${DOC_PLUGIN_FILE}"
		cat "${DOC_CVAR_FILE}" >> "${DOC_PLUGIN_FILE}"
		echo "" >> "${DOC_PLUGIN_FILE}"
	fi
	if [ $(wc "${DOC_TODO_FILE}" | awk '{print $2}') -gt 0 ]
	then
		echo "#### Todo" >> "${DOC_PLUGIN_FILE}"
		cat "${DOC_TODO_FILE}" >> "${DOC_PLUGIN_FILE}"
		echo "" >> "${DOC_PLUGIN_FILE}"
	fi

	# Update the updater files with the Plugin and Source items we have collected
	# TODO: Fix this hacky shitshow and do this a better way
	sed -e 's/#.*//' -e 's/[ ^I]*$//' -e '/^$/ d' "${DOC_UPDATER_FILE}" > /tmp/updater-cache
	awk '{print "\t\t"$1"\t"$2}' /tmp/updater-cache | sort -u > "${DOC_UPDATER_FILE}"
	perl -i -p0e 's/("Files"[^\{]*\{)[^\}]*\}/\1\nPUT_FILES_HERE\n\t\}/s' "${UPDATE}"
	sed -i -e "/PUT_FILES_HERE/{r ${DOC_UPDATER_FILE}" -e 'd}' "${UPDATE}"

done
echo >> "${TOC_FILE}"
cat "${DOC_PATH}/include/HEADER.md" "${DOC_PATH}/include/TOC.md" "${DOC_PATH}/plugins/"*.md "${DOC_PATH}/include/FOOTER.md" > "${SOURCEMOD_PATH}/README.md"

git add *

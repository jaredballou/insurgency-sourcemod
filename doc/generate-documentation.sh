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

# Temp path
TMP_PATH="${DOC_PATH}/tmp"

TMP_SUBDIRS="commands cvar dependencies description todo updater"

# Root SourceMod directory
SOURCEMOD_PATH="$(dirname "${DOC_PATH}")"

# GitHub URL to pull from
GITHUB_USER="jaredballou"
GITHUB_REPO="insurgency-sourcemod"
GITHUB_BRANCH="master"
GITHUB_URL="https://github.com/${GITHUB_USER}/${GITHUB_REPO}/blob/${GITHUB_BRANCH}"

# List of plugins
PLUGINS_FILE="${DOC_PATH}/plugins.jballou.txt"
PLUGINS_LIST=$(cat "${PLUGINS_FILE}")

# Table of Contents file
TOC_FILE="${TMP_PATH}/__TOC.md"

# Finished README file
README_FILE="${SOURCEMOD_PATH}/README.md"

# Directory for storing Updater manifests
UPDATE_PATH="${SOURCEMOD_PATH}/updater-data"

# URL base for Updater manifests
UPDATE_URLBASE="http://ins.jballou.com/sourcemod"

# Libraries to ignore when creating dependency lists
LIBRARY_IGNORE="updater"

# Add a file to the Updater manifest
function add_file_to_update() {
	LINE="${1}"
	if [ $(grep -c -i "^${LINE}\$" "${DOC_UPDATER_FILE}") -eq 0 ]
	then
		echo "Adding ${LINE} to Files for ${ITEM}"
		echo "${LINE}" >> "${DOC_UPDATER_FILE}"
	fi
}

# Create dirs
for DIR in $TMP_SUBDIRS
do
	DIR="${TMP_PATH}/${DIR}"
	if [ ! -e "${DIR}" ]; then
		mkdir -pv "${DIR}"
	fi
done

# Blank out TOC file
echo > "${TOC_FILE}"

#Loop through all files
for ITEM in $PLUGINS_LIST
do
	echo "Processing ${ITEM}"

	# Get base plugin name and source script
	# These paths refer to their location relative to SourceMod root
	PLUGIN_PATH="plugins/${ITEM}.smx"
	SCRIPT_PATH="scripting/${ITEM}.sp"

	# If the plugin doesn't exist, assume it is disabled
	if [ ! -e "../${PLUGIN_PATH}" ]; then
		PLUGIN_PATH="plugins/disabled/${ITEM}.smx"
	fi

	# If the plugin is still not present, or is older than the source script, compile
	if [ ! -e "../${PLUGIN_PATH}" ] || [ "../${PLUGIN_PATH}" -ot "../${SCRIPT_PATH}" ]; then
		echo "Compiling ${ITEM}"
		../scripting/spcomp "../${SCRIPT_PATH}" -o"../${PLUGIN_PATH}"
		if [ $? -gt 0 ]; then
			echo "ABORT: Compilation of \"../${SCRIPT_PATH}\" failed!"
			exit
		else
			git add "../${PLUGIN_PATH}"
		fi
	fi

	# These are the actual on-disk paths for the files themselves
	PLUGIN="${SOURCEMOD_PATH}/${PLUGIN_PATH}"
	SCRIPT="${SOURCEMOD_PATH}/${SCRIPT_PATH}"
	UPDATE="${UPDATE_PATH}/update-${ITEM}.txt"

	# And these are all the pieces that make up each plugin's documentation
	DOC_UPDATER_FILE="${TMP_PATH}/updater/${ITEM}.txt"
	DOC_DEPENDENCY_FILE="${TMP_PATH}/dependencies/${ITEM}.md"
	DOC_DESC_FILE="${TMP_PATH}/description/${ITEM}.md"
	DOC_TODO_FILE="${TMP_PATH}/todo/${ITEM}.md"
	DOC_COMMANDS_FILE="${TMP_PATH}/commands/${ITEM}.md"
	DOC_CVAR_FILE="${TMP_PATH}/cvar/${ITEM}.md"
	DOC_PLUGIN_FILE="${TMP_PATH}/${ITEM}.md"

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
	for LINE in $(egrep '(Plugin|Source)[":]' "${UPDATE}" | tr -d \" | awk '{print $1":"$2}'); do
		add_file_to_update "${LINE}"
	done
# >> "${DOC_UPDATER_FILE}"

	# These are lists of the items that we need to put into the updater
	add_file_to_update "Plugin:Path_SM/${PLUGIN_PATH/disabled\//}"
	add_file_to_update "Source:Path_SM/${SCRIPT_PATH}"

	# Collect CVARs
	grep CreateConVar "${SCRIPT}" | grep -v '_version"' | sed -e 's/""/NULLSTRING/g' | awk -F'"' -v OFS='' '{ for (i=2; i<=NF; i+=2) gsub(",", ";;", $i) } 1' | cut -d'(' -f2 | sed -e 's/"//g' | awk -F',' '{print $1" "$2" "$3}' | sed -e 's/;;/,/g' | awk '{printf " * \""$1"\" \""$2"\" //"$3;for(i=4;i<=NF;i++){printf " %s", $i}printf "\n"}' | sed -e 's/NULLSTRING//g' > "${DOC_CVAR_FILE}"

	# Collect commands
	grep RegConsoleCmd "${SCRIPT}" | sed -e 's/""/NULLSTRING/g' | awk -F'"' -v OFS='' '{ for (i=2; i<=NF; i+=2) gsub(",", ";;", $i) } 1' | cut -d'(' -f2 | cut -d')' -f1 | sed -e 's/"//g' | awk -F',' '{print $1" "$2" "$3}' | sed -e 's/;;/,/g' | awk '{printf " * \""$1"\" // "$2;for(i=4;i<=NF;i++){printf " %s", $i}printf "\n"}' | sed -e 's/NULLSTRING//g' > "${DOC_COMMANDS_FILE}"

	# Colelct dependencies
	echo -ne > "${DOC_DEPENDENCY_FILE}"

	# Included files
	for INCLUDE in $(grep -o '^#include <[^>]\+' "${SCRIPT}" | cut -d'<' -f2)
	do
		if [ $(grep "^$(basename "${INCLUDE}")\$" "${PLUGINS_FILE}" -c) -gt 0 ]
		then
			echo " * [Source Include - ${INCLUDE}.inc](${GITHUB_URL}/scripting/include/${INCLUDE}.inc?raw=true)" >> "${DOC_DEPENDENCY_FILE}"
			add_file_to_update "Source:Path_SM/scripting/include/${INCLUDE}.inc"
		fi
	done

	# Gamedata files
	for GAMEDATA in $(grep -Po 'LoadGameConfigFile\([^\)]+\)' "${SCRIPT}" | cut -d'"' -f2)
	do
		echo " * [gamedata/${GAMEDATA}.txt](${GITHUB_URL}/gamedata/${GAMEDATA}.txt?raw=true)" >> "${DOC_DEPENDENCY_FILE}"
		add_file_to_update "Plugin:Path_SM/gamedata/${GAMEDATA}.txt"
	done

	# Translations
	for TRANSLATION in $(grep -Po 'LoadTranslations\([^\)]+\)' "${SCRIPT}" | cut -d'"' -f2)
	do
		echo " * [translations/${TRANSLATION}.txt](${GITHUB_URL}/translations/${TRANSLATION}.txt?raw=true)" >> "${DOC_DEPENDENCY_FILE}"
		add_file_to_update "Plugin:Path_SM/translations/${TRANSLATION}.txt"
	done

	# Libraries
	for LIBRARY in $(grep -Po 'LibraryExists\([^\)]+\)' "${SCRIPT}" | cut -d'"' -f2)
	do
		if [ "$(grep "${LIBRARY}" "${PLUGINS_FILE}")" == "${LIBRARY}" ]
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

	# Make sure the Updater URL in the source script is correct
        CURURL=$(grep -i '^#define.*UPDATE_URL' "${SCRIPT}" | cut -d'"' -f2)
	NEWURL="${UPDATE_URLBASE}/update-${ITEM}.txt"

	# Make sure the version and name in the Updater file is correct
	CURVER=$(grep '"Latest".*"[0-9\.]*"' "${UPDATE}" | cut -d'"' -f4)
	NEWVER=$(grep -i '^#define.*_version' "${SCRIPT}" | cut -d'"' -f2)

	# Get name from source script
        NEWNAME=$(grep -i '^#define.*PLUGIN_NAME' "${SCRIPT}" | cut -d'"' -f2)
        if [ "${NEWNAME}" == "" ]
        then
                NEWNAME=$(grep -m1 -P '^[\s]*name[\s]*=.*"' "${SCRIPT}" | cut -d'"' -f2)
        fi
	# Remove "[INS] " prefix from name
	NEWNAME=$(echo "${NEWNAME}" | sed -e 's/\[INS\] //')

	# Get the description from the source script
        NEWDESC=$(grep -i '^#define.*PLUGIN_DESCRIPTION' "${SCRIPT}" | cut -d'"' -f2)
        if [ "${NEWDESC}" == "" ]
        then
                NEWDESC=$(grep -m1 -P '^[\s]*description[\s]*=.*"' "${SCRIPT}" | cut -d'"' -f2)
        fi

	# Update Notes line with name of plugin and description
	CURNOTES=$(grep -m1 -i '"Notes".*"' "${UPDATE}" | cut -d'"' -f4|sed -e 's/[]\/$*.^|[]/\\&/g')
	NEWNOTES=$(echo "${NEWNAME} - ${NEWDESC}" | sed -e 's/[]\/$*.^|[]/\\&/g')

	# Create GitHub friendly title and link name for anchor
        NEWTITLE="${NEWNAME} ${NEWVER}"
        NEWHREF=$(echo "${NEWTITLE}" | sed -e 's/ /-/g' -e 's/[^a-zA-Z0-9-]//g')

	# Update URL in script to point to Updater file
	if [ "${CURURL}" != "${NEWURL}" ]
	then
		echo "Changing ${ITEM} UPDATE_URL from \"${CURURL}\" to \"${NEWURL}\""
		sed -e "s,^\#define.*UPDATE_URL[\s].*\$,\#define UPDATE_URL \"${NEWURL}\"," -i "${SCRIPT}"
	fi

	# Update Name in Updater file
	if [ "${CURNOTES}" != "${NEWNOTES}" ]
	then
		echo "Changing ${ITEM} Title Note from \"${CURNOTES}\" to \"${NEWNOTES}\""
		sed -e "s\`\"Notes\".*\$\`\"Notes\"\t\t\"${NEWNOTES}\"\`" -i "${UPDATE}"
	fi

	# Update Version in Updater file
	if [ "${CURVER}" != "${NEWVER}" ]
	then
		echo "Bumping ${ITEM} from ${CURVER} to ${NEWVER}"
		sed -e "s,\"Latest\".*\$,\"Latest\"\t\t\"${NEWVER}\"," -i "${UPDATE}"
	fi

	# Update plugin documentation for readme

	# Add entry to Table of Contents
	echo -e " * <a href='#user-content-${ITEM}'>${NEWNAME} ${NEWVER}</a>" >> "${TOC_FILE}"

	# Create plugin document file
	echo -e "<a name='${ITEM}'>\n---\n### ${NEWTITLE}</a>" > "${DOC_PLUGIN_FILE}"

	# Short description
	echo "${NEWDESC}" >> "${DOC_PLUGIN_FILE}"
	echo "" >> "${DOC_PLUGIN_FILE}"

	# Download links
	echo " * [Plugin - ${ITEM}.smx](${GITHUB_URL}/${PLUGIN_PATH}?raw=true)" >> "${DOC_PLUGIN_FILE}"
	echo " * [Source - ${ITEM}.sp](${GITHUB_URL}/${SCRIPT_PATH}?raw=true)" >> "${DOC_PLUGIN_FILE}"
	echo "" >> "${DOC_PLUGIN_FILE}"

	# Include longer Description document if available
	cat "${DOC_DESC_FILE}" >> "${DOC_PLUGIN_FILE}"
	echo "" >> "${DOC_PLUGIN_FILE}"

	# Include dependency information
	if [ $(wc "${DOC_DEPENDENCY_FILE}" | awk '{print $2}') -gt 0 ]
	then
		echo "#### Dependencies" >> "${DOC_PLUGIN_FILE}"
		cat "${DOC_DEPENDENCY_FILE}" >> "${DOC_PLUGIN_FILE}"
		echo "" >> "${DOC_PLUGIN_FILE}"
	fi

	# Include CVAR listing
	if [ $(wc "${DOC_CVAR_FILE}" | awk '{print $2}') -gt 0 ]
	then
		echo "#### CVAR List" >> "${DOC_PLUGIN_FILE}"
		cat "${DOC_CVAR_FILE}" >> "${DOC_PLUGIN_FILE}"
		echo "" >> "${DOC_PLUGIN_FILE}"
	fi

	# Include command listing
	if [ $(wc "${DOC_COMMANDS_FILE}" | awk '{print $2}') -gt 0 ]
	then
		echo "#### Command List" >> "${DOC_PLUGIN_FILE}"
		cat "${DOC_COMMANDS_FILE}" >> "${DOC_PLUGIN_FILE}"
		echo "" >> "${DOC_PLUGIN_FILE}"
	fi

	# Include TODO file
	if [ $(wc "${DOC_TODO_FILE}" | awk '{print $2}') -gt 0 ]
	then
		echo "#### Todo" >> "${DOC_PLUGIN_FILE}"
		cat "${DOC_TODO_FILE}" >> "${DOC_PLUGIN_FILE}"
		echo "" >> "${DOC_PLUGIN_FILE}"
	fi

	# Update the updater files with the Plugin and Source items we have collected
	# TODO: Fix this hacky shitshow and do this a better way
	perl -i -p0e 's/("Files"[^\{]*\{)[^\}]*\}/\1\nPUT_FILES_HERE\n\t\}/s' "${UPDATE}"
	sed -i -e "/PUT_FILES_HERE/{r ${DOC_UPDATER_FILE}" -e 'd}' "${UPDATE}"
	sed -i -e 's/\(Plugin\|Source\):\(.*\)$/\t\t"\1"\t"\2"/g' "${UPDATE}"

#	UPDATER_FILES=$(sort -u "${DOC_UPDATER_FILE}" | sed -e 's/#.*//' -e 's/[ ^I]*$//' -e '/^$/ d')
#	sed -i -e "/PUT_FILES_HERE/{r ${DOC_UPDATER_FILE}" -e 'd}' "${UPDATE}"
#	sed -i -e "#PUT_FILES_HERE#$(echo $UPDATER_FILES | sed -e 's/[ \t]\+/\n/g' | 
#	echo $UPDATER_FILES | sed -e 's/[ \t]\+/\n/g' | sed -e "s/^\([^:]*\):\(.*\)$/\t\t'\1'\t'\2'/g"

done
echo >> "${TOC_FILE}"
# Create finished README
cat "${DOC_PATH}/include/HEADER.md" "${TMP_PATH}/"*.md "${DOC_PATH}/include/FOOTER.md" > "${README_FILE}"

git add *

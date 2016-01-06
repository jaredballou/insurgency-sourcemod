#!/bin/bash
################################################################################
#
# download-plugin.sh
# 
# This script handles download and installation of SourceMod plugins. It will 
# download the plugin, source, and all required files. Eventually it will handle
# dependencies and updates.
# 
# (C) 2016, Jared Ballou <insurgency@jballou.com>
# Released under the GPLv2
#
################################################################################

echo "Insurgency Sourcemod Plugin Installer"
echo "(c) 2016, Jared Ballou <insurgency@jballou.com>"

# Get paths. This should be executed from inside the SourceMod directory tree. Probably could be done better.
TOOLS_PATH="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
SOURCEMOD_PATH="$(pwd | sed -e 's/\(\/sourcemod\)\($\|\/.*$\)/\1/g')"
TMP_PATH="/tmp/sourcemod"

# GitHub settings
GITHUB_USER="jaredballou"
GITHUB_REPO="insurgency-sourcemod"
GITHUB_URL="https://github.com/${GITHUB_USER}/${GITHUB_REPO}/blob/master"

# Load the last commit hash, and get the latest one from the Github Web interface. Since their API locks me out... Grumble
# TODO: Use this: https://api.github.com/repos/jaredballou/insurgency-sourcemod/commits/master
GITHUB_COMMIT_FILE="${TMP_PATH}/last-commit"
GITHUB_LOCAL_COMMIT=$(cat $GITHUB_COMMIT_FILE)

# Get the latest commit hash
curl -s "https://github.com/${GITHUB_USER}/${GITHUB_REPO}" | grep 'commit-tease-sha' | sed -e 's/^.*commit\/\([^"]*\).*/\1/g' > $GITHUB_COMMIT_FILE
GITHUB_REMOTE_COMMIT=$(cat $GITHUB_COMMIT_FILE)

# List of plugins
PLUGINS_SOURCE="doc/plugins.jballou.txt"
PLUGINS_LIST="${TMP_PATH}/plugins.txt"

# Location of updater files. These are used to get a list of files that are required.
UPDATE_PATH="${GITHUB_URL}/updater-data"

# Display commit hashes
echo "Local Git commit: ${GITHUB_LOCAL_COMMIT}"
echo "Latest Remote Git commit: ${GITHUB_REMOTE_COMMIT}"

# Create temp dir if not created
if [ ! -e $TMP_PATH ]
then
	mkdir -p $TMP_PATH
fi

# Doenload a file from GitHub
get_github_file() {
	filename=$1
	filepath="${2:-${SOURCEMOD_PATH}/${filename}}"
	fileurl="${GITHUB_URL}/${filename}?raw=true"
	download=${3:-0}
	# If file is missing, then download
	if [ ! -f "${filepath}" ]
	then
		download=1
	fi

	# If we aren't forcing download, compare SHA1 sum of local and remote file. Only do this if the remote repo is newer.
	if [ $download -lt 1 ] && [ "${GITHUB_LOCAL_COMMIT}" != "${GITHUB_REMOTE_COMMIT}" ]
	then
		SHA1_URL="https://api.github.com/repos/${GITHUB_USER}/${GITHUB_REPO}/contents/${filename}"
		if [ -x /usr/bin/git ]
		then
			SHA1_LOCAL=$(/usr/bin/git hash-object "${filepath}")
		else
			SHA1_LOCAL=$(echo -e "blob $(stat --printf="%s" "${filepath}")\0$(cat "${filepath}")" | sha1sum | awk '{print $1}')
		fi
		SHA1_REMOTE=$(curl $SHA1_URL 2>/dev/null | grep '"sha"' | cut -d'"' -f4)

		# If the SHA doesn't match, download the file
		if [ "${SHA1_LOCAL}" != "${SHA1_REMOTE}" ]
		then
			echo ">> SHA sums do not match!"
			echo "${filepath}:${SHA1_LOCAL}"
			echo "${fileurl}:${SHA1_REMOTE}"
			download=1
		fi
	fi

	# If needed, download file
	if [ $download -gt 0 ]
	then
		echo ">> Fetching ${filename}..."
		curl -L "${fileurl}" 2>/dev/null 1> "${filepath}"
	else
		echo ">> ${filename} is up to date, skipping"
	fi
}

get_github_file "${PLUGINS_SOURCE}" "${PLUGINS_LIST}"

if [ $# -lt 1 ]
then
	# No arguments, list all and exit
	echo "================================================================================"
	echo "Plugin Listing"
	echo "================================================================================"
	for PLUGIN in $(cat "${PLUGINS_LIST}")
	do
		if [ -e "${SOURCEMOD_PATH}/plugins/${PLUGIN}.smx" ]
		then
			echo -n "[X] "
		else
			echo -n "[ ] "
		fi
		echo $PLUGIN
	done
	exit 1
elif [ $# -lt 2 ]
then
	# One argument, just the plugin name
	ACTION="install"
	PLUGIN=$1
else
	# More than one argument, for now get ACTION PLUGIN
	ACTION=$1
	PLUGIN=$2
fi

# Only install right now, later may add update or checks?
if [ $(grep -c "^${PLUGIN}\$" "${PLUGINS_LIST}") -gt 0 ]
then
	echo "> Installing ${PLUGIN}"

	# Get the updater file
	UPDATE_FILE="${TMP_PATH}/update-${PLUGIN}.txt"
	get_github_file "updater-data/update-${PLUGIN}.txt" "${UPDATE_FILE}" 1

	# Pull all Plugin and Source items from the file
	FILE_LIST=$(egrep '"(Plugin|Source)"' "${UPDATE_FILE}" | cut -d'"' -f4 | sed -e 's/^Path_SM\///g')

	# Get all files. The function will check for file existence and checksums, so this is safe.
	for FILE in $FILE_LIST
	do
		get_github_file "${FILE}" "${SOURCEMOD_PATH}/${FILE}"
	done
else
	# Could not find the plugin in the list
	echo "ERROR: Cannot find plugin \"${PLUGIN}\""
	exit 2
fi

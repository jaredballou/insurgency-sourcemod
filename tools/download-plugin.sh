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

#Files to update
TOOLS_PATH="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
SOURCEMOD_PATH="$(pwd | sed -e 's/\(\/sourcemod\)\($\|\/.*$\)/\1/g')"
TMP_PATH="/tmp/sourcemod"

GITHUB_USER="jaredballou"
GITHUB_REPO="insurgency-sourcemod"

GITHUB_URL="https://github.com/${GITHUB_USER}/${GITHUB_REPO}/blob/master"

PLUGINS_SOURCE="doc/plugins.jballou.txt"
PLUGINS_LIST="${TMP_PATH}/plugins.txt"

UPDATE_PATH="${GITHUB_URL}/updater-data"

if [ ! -e $TMP_PATH ]
then
	mkdir -p $TMP_PATH
fi

get_github_file() {
	filename=$1
	filepath="${2:-${SOURCEMOD_PATH}/${filename}}"
	download=${3:-0}
	# If file is missing, then download
	if [ ! -f "${filepath}" ]
	then
		download=1
	else
		URL="https://api.github.com/repos/${GITHUB_USER}/${GITHUB_REPO}/contents/${filename}"
		SHA1=$(echo -en "blob ${#filepath}\0${filepath}" | sha1sum)
		curl $URL > "${TMP_PATH}/contents"
		echo $URL
		echo $SHA1
	fi
	if [ $download -gt 0 ]
	then
		url="${GITHUB_URL}/${filename}?raw=true"
		echo ">> fetching ${filename}..."
		curl -L "${url}" 2>/dev/null 1> "${filepath}"
	fi
}
echo "Insurgency Sourcemod Plugin Installer"
echo "(c) 2016, Jared Ballou <insurgency@jballou.com>"

get_github_file "${PLUGINS_SOURCE}" "${PLUGINS_LIST}"

if [ $# -lt 1 ]
then
	echo "================================================================================"
	echo "Plugin Listing"
	echo "================================================================================"
	# No arguments, list all and exit
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

if [ $(grep -c "^${PLUGIN}\$" "${PLUGINS_LIST}") -gt 0 ]
then
	echo "Installing ${PLUGIN}"
	UPDATE_FILE="${TMP_PATH}/update-${PLUGIN}.txt"
	get_github_file "updater-data/update-${PLUGIN}.txt" "${UPDATE_FILE}" 1
	FILE_LIST=$(egrep '"(Plugin|Source)"' "${UPDATE_FILE}" | cut -d'"' -f4 | sed -e 's/^Path_SM\///g')
	for FILE in $FILE_LIST
	do
		get_github_file "${FILE}" "${SOURCEMOD_PATH}/${FILE}" 1
	done
else
	echo "ERROR: Cannot find plugin \"${PLUGIN}\""
	exit 2
fi

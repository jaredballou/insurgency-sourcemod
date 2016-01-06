#!/bin/bash
# This script downloads the latest SourceMod distributions and merges it into
# this tree.

DELETEFILES="plugins/basebans.smx plugins/nextmap.smx scripting/compile.sh"
REPO="http://www.sourcemod.net/smdrop/1.7"

SCRIPT=$(readlink -f "${BASH_SOURCE[0]}")
PWD="$(dirname "${SCRIPT}")"
SMDIR="$(dirname "${PWD}")"
PKGDIR="${SMDIR}/packages"
LINUX=$(curl "${REPO}/sourcemod-latest-linux" 2> /dev/null)
WINDOWS=$(curl "${REPO}/sourcemod-latest-windows" 2> /dev/null)

update_sm(){
	for FILE in $DELETEFILES
	do
		if [ -e "${PKGDIR}/addons/sourcemod/${FILE}" ]
		then
			rm "${PKGDIR}/addons/sourcemod/${FILE}"
		fi
	done
	rsync -av "${PKGDIR}/addons/sourcemod/" "${SMDIR}/"
	for FILE in $(git ls-files --others --exclude-standard)
	do
		if [ -e "${PKGDIR}/addons/sourcemod/${FILE}" ]
		then
			echo "Adding $FILE"
			git add "${FILE}"
		fi
	done
}
if [ ! -d "${PKGDIR}" ]
then
	mkdir -p "${PKGDIR}"
fi
if [ ! -e "${PKGDIR}/${LINUX}" ]
then
	wget "${REPO}/${LINUX}" -O "${PKGDIR}/${LINUX}"
	cd "${PKGDIR}"
	tar xzvpf "${LINUX}"
	cd "${SMDIR}
	update_sm
fi
if [ ! -e "${PKGDIR}/${WINDOWS}" ]
then
	wget "${REPO}/${WINDOWS}" -O "${PKGDIR}/${WINDOWS}"
	cd "${PKGDIR}"
	unzip -of "${WINDOWS}"
	cd "${SMDIR}
	update_sm
fi

#!/bin/bash
rootdir="$(cd "$(dirname "${BASH_SOURCE[0]}" )" && pwd )"
outdir="$(dirname $rootdir)/plugins"
compile()
{
	i=$1
	smxfile="`basename $i | sed -e 's/\.sp$/\.smx/'`";
	echo -e "Compiling $i...";
	./spcomp $i -o${outdir}/$smxfile
	RETVAL=$?
	if [ $RETVAL -ne 0 ]; then
		exit 1;
	fi
}
if [[ $# -ne 0 ]]; then
	list="$@"
else
	list=$(ls *.sp)
fi

for sourcefile in $list; do
	compile $sourcefile
done

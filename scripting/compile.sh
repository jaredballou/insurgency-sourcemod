#!/bin/bash
OUTDIR=../plugins
cd "$(dirname "$0")"

test -e $OUTDIR || mkdir -p $OUTDIR

if [[ $# -ne 0 ]]; then
	for i in "$@"; 
	do
		smxfile="`echo $i | sed -e 's/\.sp$/\.smx/'`";
		echo -e "Compiling $i...";
		./spcomp $i -o$OUTDIR/$smxfile
		RETVAL=$?
		if [ $RETVAL -ne 0 ]; then
			exit 1;
		fi
	done
else
	for sourcefile in *.sp
	do
		smxfile="`echo $sourcefile | sed -e 's/\.sp$/\.smx/'`"
		echo -e "Compiling $sourcefile ..."
		./spcomp $sourcefile -o$OUTDIR/$smxfile
		RETVAL=$?
		if [ $RETVAL -ne 0 ]; then
			exit 1;
		fi
	done
fi

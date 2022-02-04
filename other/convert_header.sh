#!/bin/bash

# Used to generate the include file of both watchdog-specific and system error codes.
#
# Typically called like this:
# ./convert_header.sh include/watch_err.h /usr/include/asm-generic/errno-base.h /usr/include/asm-generic/errno.h > error-codes.inc
#
# The .sh file extension is not a good choice, but then a syntax-highlighting editor will
# show you it looking correct as if it was a bash script.
#
# NOTE: Some of the error codes are < 0 which is a problem for scripting. The 'exit' call
# is OK, but returns it as unsigned 8 LSB (so -1 >= 255) but the 'return' from a function
# is not happy, so you need to do something like return $(($err & 255)) to emulate the exit
# call behaviour.
#
# (c) Paul S Crawford 2013, released under GPLv2 licence.
# Absolutely no warranty! Use at your own risk.
#
# See also:
# http://www.sat.dundee.ac.uk/~psc/watchdog/Linux-Watchdog.html


if [ -z "$1" ] ; then
	echo "Must supply file name to read"
	exit 1
fi

	# Use '\n' as string separator.
	IFS=$'\012'

	# Some comments for the resulting file.
	echo "# This file should be read-only and NOT executable."
	echo "# Intended as include file in /etc/watchdog.d"

# Loop through all command line file names.
for fname in "$@"
	do
	if [ ! -f "$fname" ] ; then
		echo "Appears that $fname is not a file"
		exit 1
	else
		# Report which file the error codes come from.
		echo ""
		echo "# Converted from $fname"
		echo ""

		# We are only looking at entries such as "#define ENOERR 0" so we look for
		# it starting with '#define' then any number of spaces, then 'E'
		for str in $(grep '^#define[[:space:]]*E' "$fname")
			do
			# Check to see if there is a trailing C-style comment
			chk=$(echo $str | grep '/')
			if [ -z "$chk" ] ; then
				# No comment
				comment=""
			else
				# Get text after '/*' (actually replace that match to this point with just the '/*').
				comment=$(echo $str | sed 's/^#.*\/\*/\/\*/g')
			fi

			# Extract the name and its value.
			mnemonic=$(echo $str | awk '{print $2}')
			var=$(echo $str | awk '{print $3}')

			# See if the value is one of the other error codes, or a number.
			chk=$(echo $var | grep '^E')
			if [ -z "$chk" ] ; then
				comb="$mnemonic=$var"
			else
				comb="$mnemonic=\$$var"
			fi

			# Generate a constant-width ECODE=NN string.
			st=$(echo "$comb" | awk '{printf "%-20s", $1 }')

			# Output that as result.
			echo "readonly $st # $comment"
			done
	fi
	done

exit 0

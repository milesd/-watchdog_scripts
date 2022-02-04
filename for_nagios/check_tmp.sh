#!/bin/bash
#
# Bash script that can be run as either a V0 'test binary' or as
# a 'V1' test/repair binary to make sure that /tmp still has the
# ability to have a temporary directory created.
#
# (c) Paul S Crawford 2015, released under GPLv2 licence.
# Absolutely no warranty! Use at your own risk.
#
# See also:
# http://www.sat.dundee.ac.uk/~psc/watchdog/Linux-Watchdog.html

# Some watchdog-specific constants (converted from watch_err.h and
# /usr/include/asm-generic/errno-base.h)

readonly ENOERR=0             # /* no error */
readonly ENOTDIR=20           # /* Not a directory */

# Start by assuming failure
rv=$ENOTDIR

tdir=$(mktemp --directory)
if [ -n "$tdir" ] && [ -d "$tdir" ] ; then
	#echo "Removing $tdir"
	rmdir "$tdir"
	if [ $? -ne 0 ] ; then
		echo "Failed to remove temp directory"
	else
		# Success, so clear our error type.
		rv=$ENOERR
		# Sleep for 20 seconds to reduce disk I/O load. The
		# watchdog should be set for more than this as time-out.
		sleep 20
	fi
else
	echo "Failed to create directory"
fi

exit $rv

#!/bin/bash
#
# Script to stop the watchdog daemon brutally (with SIGKILL = 9) to
# verify the hardware timer kicks in and resets the machine. Most
# of the other commands (in particular the 'sync' calls) are there
# to minimise the risk of a corrupted machine afterwards.
#
# Make sure others are not logged in when testing, and that any
# database-like applications are closed first (e.g. email clients).
#
# Also wise to check there is not a MD rebuild or scrub taking
# place either (e.g. using 'more /proc/mdstat')
#
# (c) Paul S Crawford 2013, released under GPLv2 licence.
# Absolutely no warranty! Use at your own risk.
#
# See also:
# http://www.sat.dundee.ac.uk/~psc/watchdog/Linux-Watchdog.html


	if [ $(id -u) -ne 0 ] ; then
		echo "Sorry, you need to be root"
		exit 1
	fi

	who

	echo "Check the above to see who is logged in, if any"
	echo "others users are, then use Ctrl+C to kill this script."
	echo "Otherwise press the 'return' key to proceed..."

	read junk

	# Make sure file systems care fully checked on reboot.
	touch /forcefsck

	# Sync file systems first so less risk of inconsistencies.
	sync

	# Stop the watchdog daemon 'brutally' to leave the driver
	# open and so it should keep counting down.
	pkill -9 watchdog

	# Print a count of roughly number of seconds that have passed
	# while also syncing the file systems. Typically we should be
	# reset by ~60.
	for n in $(seq 1 250)
		do
			echo $n
			sleep 1
			sync
		done

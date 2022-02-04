#!/bin/bash
#
# Bash script that can be run as either a V0 'test binary' or as
# a 'V1' test/repair binary to allow a user to trigger one of the
# Linux watchdog daemon's actions.
#
# To initiate an action, the user would do something like:
#
# $sudo touch /var/log/watchdog/reboot
#
# This would cause this test script to find that zero-length file, remove
# it (so no reboot loop!), and return -1 to trigger an unconditional reboot.
#
# (c) Paul S Crawford 2013, released under GPLv2 licence.
# Absolutely no warranty! Use at your own risk.
#
# See also:
# http://www.sat.dundee.ac.uk/~psc/watchdog/Linux-Watchdog.html


# Some watchdog-specific constants (converted from watch_err.h)

readonly ENOERR=0             # /* no error */
readonly EREBOOT=255          # /* unconditional reboot */
readonly ERESET=254           # /* unconditional hard reset */

readonly ETOOHOT=252          # /* too hot inside */

readonly EPERM=1              # /* Operation not permitted */

# Name to report to 'stdout'

bname=$(basename $0)

# Configure the directory to look for the files. Should only be writeable
# by users with appropriate authority. That can be achieved by changing the
# group ownership & access values, or allowing those users to 'sudo' (maybe
# having a root-owned script for that which is explicitly in the sudoers file).

chkdir="/var/log/watchdog"

# Function to check for a zero-length file, remove it and return accordingly.

check_action()
{
	local pname="$chkdir/$1"
	local ecode="$2"

	if [ -f "$pname" ] && [ ! -s "$pname" ] ; then
		# We have a file, and it is zero-length, so remove it and
		# tell the watchdog what is needed.
		echo "Found file $pname so exiting $ecode"
		rm -f "$pname"
		exit $ecode
	fi
}

# Actual code is run here...

	# Can use the 'sleep' function to test handling of test time-outs, etc.
	#sleep 5

	# Check the unconditional actions.
	check_action "reboot"		$EREBOOT
	check_action "hardreset"	$ERESET
	check_action "overheat"		$ETOOHOT

	# Check the 'typical' error, can test retry action along with rapid
	# re-application of the touched file.
	check_action "nopermit"		$EPERM

	echo "$bname found no action needed"

exit $ENOERR

#!/bin/bash

# Example script for testing the watchdog error-repair/recovery process.
# This is intended for the auto-loaded "V1" style of operation so it
# should be put in /etc/watchdog.d/ and it also assumes the include
# file with all of the error codes is located there.
#
# (c) Paul S Crawford 2013, released under GPLv2 licence.
# Absolutely no warranty! Use at your own risk.
#
# See also:
# http://www.sat.dundee.ac.uk/~psc/watchdog/Linux-Watchdog.html
#

# Include the table of exit codes.
errcodes="/etc/watchdog.d/error-codes.inc"
[ -f "$errcodes" ] && . $errcodes

# Get the name of this script
	bname=$(basename $0)

run_test ()
{
	local err=$ENOERR
	echo "Running test"

	# Do something...set err...

	return $err
} # End of run_test


run_repair ()
{
	local param="$1"
	local object="$2"
	local err=$ENOERR

	if [ -z "$param" ] ; then
		echo "Missing error code (parameter) for repair"
		return $EINVAL
	fi

	if [ -z "$object" ] ; then
		echo "Missing script name for repair"
		return $EINVAL
	fi

	echo "Running repair $param $object"

	case "$param" in
        $EPERM) # Operation not permitted...
            ;;

        *)	# Unknown error codes for our attempt.
        	err=$EINVAL
        	;;
 	esac

	return $err
} # End of run_repair


err=$ENOERR

	# Process the command line.
	case "$1" in
        test)
        	run_test
        	err=$? # Get function return value.
            ;;

        repair)
            run_repair "$2" "$3"
        	err=$? # Get function return value.
            ;;

        *)
            echo "Usage: $bname {test|repair errcode scriptname}"
            err=$EINVAL
 	esac

echo "Exiting with value=$err"
exit $err

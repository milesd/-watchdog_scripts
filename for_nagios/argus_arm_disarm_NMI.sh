#!/bin/bash

# Used to toggle the script that issues an NIM-based reboot of the
# active Argus storage head.
#
# Assumes that argus_nmi.sh should be a symbolic link to either:
# argus_nmi.sh.real
# argus_nmi.sh.safe (as above but the NMI issuing command deleted)
#
# 1.00 psc Sun Dec 13 15:03:48 GMT 2015 - First version

# The locations and scripts expected

sdir=/opr
sname=argus_nmi.sh
sname_safe=$sname.safe
sname_real=$sname.real

# Compare files, return is 0=same, 1=different, 2=error
compare_files()
{
	local rv=2
	if [ ! -e "$1" ] ; then
		echo "File "$1" not found"
	elif [ ! -e "$2" ] ; then
		echo "File "$2" not found"
	else
		diff -w "$1" "$2" > /dev/null
		rv=$?
		if [ $rv -eq 0 ] ; then
			echo "Files $1 and $2 are the same"
		fi
	fi
	return $rv
}

# First check that real & safe exist and are actually different

	compare_files "$sdir/$sname_real" "$sdir/$sname_safe"
	if [ $? -ne 1 ] ; then
		exit 1
	fi

# Get command line option to say what we want to do

pushd "$sdir" > /dev/null

case $1 in
	"safe")
		rm "$sname"
		ln -s "$sname_safe" "$sname"
		logger -s "Made $sname safe for test"
	;;

	"real")
		rm "$sname"
		ln -s "$sname_real" "$sname"
		logger -s "Made $sname real use again"
	;;

	"status")
		# Report current status
		compare_files "$sname" "$sname_real"
		if [ $? -eq 0 ] ; then
			echo "Currently set to 'real' NMI script"
		else
			compare_files "$sname" "$sname_safe"
			if [ $? -eq 0 ] ; then
				echo "Currently set to 'safe' NMI script"
			else
				echo "Unknown setting for NMI script! BAD!"
			fi
		fi
	;;

	*)
		echo "Usage is $0 safe|real|status"
	;;
esac

popd > /dev/null
exit 0

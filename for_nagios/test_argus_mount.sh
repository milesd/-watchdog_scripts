#!/bin/bash
# This is intended for the V0 style of test-only watchdog script.
#
# 1.00 psc Tue Dec 08 17:49:30 GMT 2015
#
# Designed to check if the main server argus is alive or hung. general
# logic is this:
#
#	Can I ping argus?
#		If so can I mount a directory from argus and see any files?
#
#	If not, is it just argus or a more general problem. so try the same
#	for oscar & adeos, if any respond OK then presume the fault is with
#	argus, and not a network problem, nagios NFS fault, etc.
#
# However, this script might occasionally fail due to temporary bugs (e.g.
# no ping for 4 in a row) or during an expected event, such as a deliberate
# fail-over of argus 1&2 during maintenance, etc. Also it might hang
# indefinitely on NFS faults, etc, so it has to be run by something that
# can do a process-tree kill after a reasonable time-out, and can apply
# some additional logic to wait for a certain time of successive failures
# before acting upon it.
#
# The watchdog daemon can do this, but we DON'T want to reboot nagios as
# a result of this script failing. but we DO want to reboot nagios if there
# is some problems. One we might expect is running out of space for temp
# directories under odd fault cases, so that should be tested by the usual
# daemon's configuration (see check_tmp.sh)
#
# Hence the plan is to run this as a V0 test script with a 2nd instance of
# the watchdog daemon that is configured to ignore the PID lock file and
# to not attempt a reboot on failure.

# =========================================================================

# Define a sleep time for 'sucess' so we have liss disk I/O on nagios. This
# must be less than the time-out (default 60) minus the polling interval
# (probably 5 seconds).
readonly stime=25

# Our mount/un-mount programs with their full path.
mnt=/bin/mount
umnt=/bin/umount

# Converted from /usr/include/asm-generic/errno-base.h

readonly ENOERR=0             # /* no error */

readonly ENOENT=2             # /* No such file or directory */
readonly EINVAL=22            # /* Invalid argument */

readonly ENOTDIR=20           # /* Not a directory */
readonly ENONET=64            # /* Machine is not on the network */

# =========================================================================

is_host_alive()
{
	local host="$1"
	local err=0
	local count=1

	while [ $count -lt 5 ]
	do
		ping -c 1 -w 1 $host > /dev/null
		err=$?
		# If we have a zero return then host alive, otherwise loop again
		if [ $err -eq 0 ] ; then
			break
		else
			echo "Ping $count of host '$host' failed (returned $err)"
			err=$ENONET
		fi
		count=$(($count + 1))
	done

	return $err
} # End of is_host_alive()

# =========================================================================

check_nfs_mount ()
{
	local err=$ENOERR
	local nfs_path="$1"
	# From "server:/path" we want just "server"
	local server=$(echo "$nfs_path" | sed 's/:.*$//g')

	# First ping the server to see if any hope of mounting it
	is_host_alive $server
	err=$?
	if [ $err -ne 0 ] ; then
		return $err
	fi

	# Create temporary mount-point
	local mountpoint=$(mktemp --directory)

	if [ ! -d "$mountpoint" ] ; then
		echo "Failed to create temporary directory"
		return $ENOTDIR
	fi

	# Success, try mounting server and see if any files present
	$mnt -t nfs4 --read-only "$nfs_path" "$mountpoint"
	nfiles=$(ls -l "$mountpoint" | wc -l)
	# Remove the ls -l line "total 40" or similar
	nfiles=$(($nfiles - 1))
	echo "Found $nfiles files"
	if [ "$nfiles" -gt 0 ] ; then
		echo "Server $server appears to be mounted OK"
		err=$ENOERR
	else
		echo "No sign of mounted files"
		err=$ENOENT
	fi

	# Done, so unmount and remove temporary directory. This might
	# fail if we can't unmount though. Also previous failures can
	# leave the mount in place so loop round unmounting until we
	# fail.
	local rv=0
	while [ "$rv" -eq 0 ]
	do
		#echo "Unmounting $server"
		$umnt -f "$nfs_path" 2> /dev/null
		rv=$?
	done

	# When we remove note any errors, could be result of above
	# failing to properly unmount the NSF share so report this.
	rmdir "$mountpoint"
	rv=$?
	if [ $rv -ne 0 ] ; then
		err=$rv
	fi

	return $err
} # End of check_nfs_mount()

# =========================================================================

run_test ()
{
	local err=$ENOERR
	# Address of the server and file system to mount. This should have
	# at least ONE file in it so the mount is seen to succeed. Ideally
	# we should have a nagios user account just for this.
	check_nfs_mount "argus:/export/userdata/psc"
	err=$?

	if [ $err -ne 0 ] ; then
		local others_ok=0
		echo "Failed main check, trying others..."
		# We failed to mount the main server, so check it is (probably)
		# that machine and not an issue with networking or this machine's
		# own NFS stack (something for the watchdog to address?)
		for check in "adeos:/opt/DSSingest/logs" "oscar:/opt/DSSingest/logs"
			do
			check_nfs_mount $check
			if [ $? -eq 0 ] ; then
				others_ok=1
				break
			fi
		done
		# Did anyone else respond OK? If not assume main server is down
		# for same reason so not its fault.
		if [ $others_ok -eq 0 ] ; then
			err=0
		fi
	fi

	return $err
} # End of run_test()

# =========================================================================

# First thing is make sure only one instance is running, so we don't
# unmount another test mount, etc.

s=$(pidof -x "$0")

if [ -n "$s" ] && [ "$s" != "$$" ] ; then
    echo "This script is already running, exiting"
    exit 0
fi

# Next check we are root, otherwise we can't run tests.
if [ `id -u` != 0 ]; then
	echo "Must be root to mount NFS directly, exiting"
	exit 0
fi

	run_test
	err=$?

	if [ $err -eq 0 ] ; then
		echo "All OK, sleeping for $stime seconds to reduce activity..."
		sleep $stime
	fi

echo "Exiting with value = $err"
exit $err

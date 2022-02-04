#!/bin/bash
#
# This is a V0 style repair script for the watchdog only to check
# for problems with the argus NFS mount.
#
# 1.00 psc Tue Dec 08 17:49:30 GMT 2015
# 1.01 psc Tue Dec 08 19:02:25 GMT 2015 - Fixed putting actual date in lock file.
# 1.02 psc Sun Dec 13 15:45:00 GMT 2015 - Moved time-lock to the NMI script so it
#	won't get confused by a separate manual web-based attempt.


# The script we expect to respond to.
readonly testbin="/etc/argus_watchdog/test_argus_mount.sh"

# The script we call to do the dirty work of issuing the NMI
readonly NMIscript="/opr/argus_nmi.sh"

# What we expect the command line to be
err="$1"
proc="$2"

# First check this is the error we are looking to fix
if [ "$proc" == "$testbin" ] ; then
	if [ -x $NMIscript ] ; then
		echo "Trying NMI..."
		$NMIscript -f
		# Set err to zero if we think it worked (which we probably will
		# always do).
		err=0
	else
		echo "Error! Missing NMI script $NMIscript"
	fi
fi

exit $err

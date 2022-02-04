#!/bin/bash
#
# This script constantly monitors which argus head is active
# and writes the hostname to /opr/argus_active.log
# When you need to operate on the active host's LOM you can
# simply read the last line from this file (and check date?!).
# Requires /opr/argus_id_dsa ssh key to login without password.
#
# 1.02 psc Wed Dec 09 12:01:16 GMT 2015 - Added check/backup on log file becomming too big.
# 1.01 arb Wed Dec  9 11:35:29 GMT 2015 - changed comments. added more vars.

activeheadlog="/opr/argus_active.log"
sshkeyfile="/opr/argus_id_dsa"
akshusername="script@argus"
maxlogsize=100000

# First determine which head is active by asking aksh
# Use a timeout in case argus is hung
# Append to log with date,
# eg. argus2 Fri Dec  4 11:01:46 GMT 2015

touch $activeheadlog
activehead=`echo 'configuration version show' | ssh -q -o ConnectTimeout=10 -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -i $sshkeyfile -T $akshusername | awk '/Appliance Name:/{print$NF}'`
if [ "$activehead" != "" ]; then
	# First check for log file becoming too big
	if [ -f $activeheadlog ] ; then
		logsize=`ls -l $activeheadlog | awk '{print $5}'`
		if [ $logsize -gt $maxlogsize ] ; then
			mv $activeheadlog $activeheadlog.bak
		fi
	fi
	# Then report head & date
	echo $activehead `date` >> $activeheadlog
fi

# Find the hostname of the LOM of the most recently active head
activehead=`tail -1 $activeheadlog | awk '{print$1}'`
activeheadlom="${activehead}-lom"

# echo to stdout only if running interactive from a console
# so that running this from cron is silent
if tty -s; then
	echo $activeheadlom
fi

exit 0

#!/bin/bash
# Script to automate the installation of the argus monitor stuff.
# 1.00 psc Tue Dec 08 17:49:30 GMT 2015

# Some good scripting checks.
set +o errexit
set +o nounset

function print_usage () {
	printf "Usage: %s [options]\n" $( basename $0) >&2
	echo "Options are from the following:" >&2
	echo "-I 0|1   0 = Don't install any files (leave unchanged)." >&2
	echo "         1 = Install the automated checks" >&2
	echo "" >&2
	echo "-X      Remove the script completely, delete ALL installed!" >&2

return 0
}

# Must be root to do this?

if [ ! `id -u` = 0 ]; then
	echo "Sorry, you have to be 'root' (or use 'sudo') to"
	echo "have any chance of running this set-up script."
	echo ""
	echo "Did you read the README file or check to see what"
	echo "this script did before running it?"
	echo ""
	print_usage
	exit 1
fi

WATCHDOG=/usr/sbin/watchdog

if [ ! -x $WATCHDOG ] ; then
	echo "The watchdog daemon $WATCHDOG is not installed"
	exit 1
fi

# Parse the command line for suitable options. Start by clearing everything set here.

OPT_LIST='I:X'

doinstall=1
doremove=0

# Parse command line 1st time for lock-override, etc.
while getopts $OPT_LIST OPTION
	do
		case $OPTION in
		X)	doremove=1
			doinstall=0
			;;

		I)	doinstall="$OPTARG"
			;;

		?)	print_usage
			exit 1
			;;
	  esac
	done

# The configuration stuff first.

CFG_DEST=/etc/argus_watchdog

if [ $doremove -eq 1 ] && [ -d "$CFG_DEST" ] ; then
	# Remove ALL old stuff.
	echo "Removing all of $CFG_DEST"
	rm -rf $CFG_DEST
fi

if [ $doinstall -eq 1 ] ; then
	# First create the configuration directory and copy the
	# configuration file to it.
	if [ ! -d "$CFG_DEST" ] ; then
		echo "Creating $CFG_DEST"
		mkdir $CFG_DEST
	else
		echo "Archiving current configuration files"
		pushd $CFG_DEST > /dev/null
		tar -czf archive-$(date +%Y%m%d-%H.%M.%S).tgz --exclude='*.tgz' *
		popd  > /dev/null
	fi

	echo "Copying configuration files to $CFG_DEST"

	cp --preserve=timestamps argus_watchdog.conf repair_argus_NMI.sh test_argus_mount.sh $CFG_DEST

	# Now change the settings so only root can modify things.
	# This is VERY important for system security!

	chown root:root $CFG_DEST
	chmod 755 $CFG_DEST
	chown root:root $CFG_DEST/*
	chmod 644 $CFG_DEST/*.conf
	chmod 755 $CFG_DEST/*.sh

	# Lastly check that the watchdog has the temp file check in place
	autoload=/etc/watchdog.d
	if [ ! -d "$autoload" ] ; then
		mkdir "$autoload"
	fi
	cp --preserve=timestamps check_tmp.sh $autoload

	# Create the watchdog binary. We can't use symlinks as the
	# utility start-stop-daemon seems to see them as the original
	# process (or that they are all the same on-disk), so we make a
	# copy here.
	abin=$CFG_DEST/argus_watchdog
	if [ -e $abin ] ; then
		rm "$abin"
	fi
	cp --preserve=timestamps $WATCHDOG $abin
fi

# Now for the background stuff.

DAEMON='argus_watchdog'
RUNDIR='/etc/init.d'

if [ $doremove -eq 1 ] && [ -e "$RUNDIR/$DAEMON" ] ; then
	echo "Removing $RUNDIR/$DAEMON"
	rm -f "$RUNDIR/$DAEMON"
fi

if [ $doinstall -eq 1 ] ; then
	echo "Installing $DAEMON to $RUNDIR"
	cp --preserve=timestamps $DAEMON $RUNDIR
	chown root:root $RUNDIR/$DAEMON
	chmod 755 $RUNDIR/$DAEMON
fi

# Remove current settings (if any)
update-rc.d -f $DAEMON remove

# Set to run on shut down (level 0 = system halt). Note we have 'stop' actually doing the backup!
# Also restart? (run level 6) Can be tedious after update.

if [ $doinstall -eq 1 ] ; then
	[ -x "$RUNDIR/$DAEMON" ] && update-rc.d $DAEMON start 98 2 3 4 5 . stop 02 0 1 6 .
fi

exit 0

# End of script.

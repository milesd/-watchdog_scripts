INTRODUCTION
------------

This archive has a collection of scripts used for the testing of
the Linux watchdog daemon, both for code development and for
setting up a machine to use the daemon's protection.

They are all distributed as non-executable as a precaution. You
need to check each one is reasonable for the job you want first,
and then make it executable. You don't run scripts downloaded
from the internet without checking, do you?

(c) Paul S Crawford 2013, released under GPLv2 licence.
Absolutely no warranty! Use at your own risk.

See also:
http://www.sat.dundee.ac.uk/~psc/watchdog/Linux-Watchdog.html

CONTENTS
--------

There are two sub-directories, one called "test-repair" with stuff
intended to be used by the Linux watchdog daemon, and "other" that
has stuff intended for development and testing of the system.

(1.1) other/test_watchdog_reset.sh

Used to kill the watchdog and verify the hardware timer kicks in
and resets/reboots the machine. Use with case as there is a risk
of file system corruption.

(1.2) other/convert_header.sh

This converts the C include files with the #define's error codes into
a bash-style file for inclusion (or copy/paste) to make it easier to
manage the meaning of the error/return codes. Typically it is run from
the main directory of the watchdog source code (i.e. above 'include')
with a call such as:

./convert_header.sh include/watch_err.h /usr/include/asm-generic/errno-base.h /usr/include/asm-generic/errno.h > error-codes.inc

NOTE: Typically this include file is in copied to /etc/watchdog.d/ but
it should _NOT_ be executable.

(1.3) other/check_proc.sh

This is an example of using 'watch' and 'ps' to monitor the various
processes associated with a user called "test". Simple open another
terminal window and run it as:

./check_proc.sh

You then see what is happening with that user refreshed every 0.5s, for example:

USER       PID  PPID  PGID   SID COMMAND
test     11533  7044 11533  7044 su test
test     11560 11533 11560  7044 -csh

This can be useful for watching the running of scripts (and their children) by
the watchdog daemon.

(1.4) other/fork_bomb.sh

This is exactly what is says: a bash "fork bomb" that will use up all of the
system resources (unless the user's account has 'ulimit' used to limit the number
of processes they can start).

Typically this is used to see how well (or otherwise) the machine can be stopped
and rebooted following this sort of system overload. Note that the OOM Killer
is not very good at dealing with the bomb, so really you have to reboot as
important stuff usually ends up trashed.

WARNING: USE AT YOUR OWN RISK!

(1.5) other/wd_syslog.sh

This just picks out watchdog-related entries from the previous & current syslog.

NOTE: only last 50 lines are printed, edit it if you want to see more.

(1.6) other/plot_syslog.sh

This uses the gnuplot program to generate graphs of certain parameters in syslog
that are recorded if 'verbose' operation is used. Currently these are:

	memory check (plots both 'free' memory & swap space).

	load averages (plots 1-minute auto-scaled, and all three with 0-10 range).

	ping times (unable to separate out multiple ping targets though).

Usage is something like:

cat /var/log/syslog.1 /var/log/syslog > /tmp/$(hostname).log
./plot_syslog.sh /tmp/$(hostname).log

You might want to reduce the check interval from 1 second to 2-5 seconds
to reduce the volume of syslog messages though.

----------------------------------------------------------------------

(2.1) test-repair/error-codes.inc

This is intended as an "include file" with all of the watchdog-specific and
standard system error codes available as constant (read-only) bash variables.

(2.2) test-repair/wd_test_action.sh

This script checks for certain zero-length files in the default log directory
used by watchdog daemon: /var/log/watchdog

If they appear it deletes them and returns the appropriate error code:

reboot		=> 255 (-1)
hardreset	=> 254 (-2)
overheat	=> 252 (-4)
nopermit	=> 1

This can be used to test the watchdog daemon's reaction to those errors
for testing, and also if you want to remotely reset the machine by this
route, etc.

To test the reaction, for example a reboot, you execute a command such as:

touch /var/log/watchdog/reboot

The return value of 1 (system error for "Operation not permitted") will
normally be tolerated by the retry-counter, so if testing that feature you
will need a small script to keep re-applying the touch command.

(2.3) test-repair/wd_sensors.sh

This script uses the 'sensors' command from the lm-sensors package to get
the system health and to check for overheating using the limits configured
per-sensor by that package.

After installing lm-sensors, running the sensors-detect script and making sure
you have the appropriate module(s) loaded (e.g. editing /etc/modules) you can
put your machine-specific settings in a file in /etc/sensors.d/ and then run
the 'sensors --set' command (as root) to configure the limits in there. Then
anyone can run 'sensors' to get the voltages, fan speeds, temperature, etc.

This could be modified to check for the 'ALARM' output when the sensors
package itself checks things. For example, as seen here:

+12V:        +12.39 V  (min = +11.38 V, max = +12.62 V)
Vstandby:     +3.46 V  (min =  +2.98 V, max =  +3.63 V)
VBAT:         +3.38 V  (min =  +2.70 V, max =  +3.30 V)  ALARM
System Fan:  1339 RPM  (min =  502 RPM, div = 16)
CPU Fan:     1757 RPM  (min =  502 RPM, div = 16)
2nd Fan:        0 RPM  (min =    0 RPM, div = 128)
System Temp:  +28.0°C  (high = +65.0°C, hyst = +55.0°C)  sensor = thermistor
CPU Temp:     +23.0°C  (high = +80.0°C, hyst = +75.0°C)  sensor = thermistor

Also it could trigger the watchdog at a lower or higher limit than the
sensors settings by doing a bit of arithmetic, etc.

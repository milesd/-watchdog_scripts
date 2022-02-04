#!/bin/bash

# Used to see all of the 'test' user's processes (-u option to ps) when
# testing watchdog with that log-in. Typically you log in as another
# (dummy) user so if the watchdog is triggered it only hoses that user's
# processes and your own log-in is not taken down.

# (c) Paul S Crawford 2013, released under GPLv2 licence.
# Absolutely no warranty! Use at your own risk.
#
# See also:
# http://www.sat.dundee.ac.uk/~psc/watchdog/Linux-Watchdog.html

watch -n 0.5 'ps -u test -o user,pid,ppid,pgid,sid,args'

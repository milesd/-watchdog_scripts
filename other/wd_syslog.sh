#!/bin/bash

# Simple script to look at the last 50 lines of watchdog-related stuff in
# syslog. This scans both the previous and current files so you don't
# just miss something when rsyslod gets HUP'd.
#
# (c) Paul S Crawford 2013, released under GPLv2 licence.
# Absolutely no warranty! Use at your own risk.
#
# See also:
# http://www.sat.dundee.ac.uk/~psc/watchdog/Linux-Watchdog.html

grep -h 'watchdog' /var/log/syslog.1 /var/log/syslog | tail -n 50

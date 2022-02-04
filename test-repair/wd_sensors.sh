#!/bin/bash
#
# Bash script that can be run as either a V0 'test binary' or as
# a 'V1' test/repair binary to allow a user to shut the machine
# down if the 'sensors' package reports overheating.
#
# (c) Paul S Crawford 2013, released under GPLv2 licence.
# Absolutely no warranty! Use at your own risk.
#
# See also:
# http://www.sat.dundee.ac.uk/~psc/watchdog/Linux-Watchdog.html

# Some watchdog-specific constants (converted from watch_err.h)

readonly ENOERR=0             # /* no error */
readonly ETOOHOT=252          # /* too hot inside */

# Name to report to 'stdout'

bname=$(basename $0)

sensors="/usr/bin/sensors"

	if [ ! -x "$sensors" ] ; then
		echo "Program $sensors not installed"
		exit 0
	fi

# Typical result of the "sensors" package looks like:
#
# $ sensors
# atk0110-acpi-0
# Adapter: ACPI interface
# Vcore Voltage:      +0.86 V  (min =  +0.80 V, max =  +1.60 V)
# +3.3V Voltage:      +3.33 V  (min =  +2.97 V, max =  +3.63 V)
# +5V Voltage:        +4.97 V  (min =  +4.50 V, max =  +5.50 V)
# +12V Voltage:      +11.98 V  (min = +10.20 V, max = +13.80 V)
# CPU Fan Speed:     1794 RPM  (min =  600 RPM)
# Chassis1 Fan Speed:   0 RPM  (min =  600 RPM)
# Chassis2 Fan Speed:   0 RPM  (min =  600 RPM)
# Power Fan Speed:      0 RPM  (min =    0 RPM)
# CPU Temperature:    +33.5°C  (high = +45.0°C, crit = +45.5°C)
# MB Temperature:     +33.0°C  (high = +45.0°C, crit = +46.0°C)
#
# So we look for 'high =' to locate the temperature specific tests,
# then we strip out the name to ':' and get just the integer values
# of each temperature (cut out '.' and '+') for the comparison by
# the bash tests.

	rv=$ENOERR

	# Configure the 'separator' for line feeds '\n'
	IFS=$'\012'

	for t in $($sensors | grep 'high =' | sed 's/.*://g;s/\./ /g;s/+//g' | awk '{print $1, $5}')
		do
		# Split each string '$t' in to reported value and the high-limit.
		value=$(echo $t | awk '{print $1}')
		limit=$(echo $t | awk '{print $2}')

		# Test this and set return value if any fail.
		if [ "$value" -gt "$limit" ] ; then
			echo "$bname found temperature $value > $limit so too hot"
			rv=$ETOOHOT
		else
			echo "$bname found temperature $value <= $limit so OK"
		fi
		done

exit $rv

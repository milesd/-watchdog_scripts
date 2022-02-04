#!/bin/bash

# Script to generate graphs of watchdog daemon's "verbose" messages about memory use
# and load averages. Input files should be the syslog files, typically concatenated
# from the past+current files, for example:
#
# cat /var/log/syslog.1 /var/log/syslog > /tmp/$(hostname).log
#
# NOTE: You need gnuplot installed.

for ipfile in $*
do
	if [ -f "$ipfile" ]; then
		echo "Plotting memory usage from $ipfile"
	else
		echo "Input $ipfile is not a (readable) file!"
		exit 1
	fi

	# Generate a template name for output.
	pname=$(pwd)/$(basename "$ipfile" '.log')

	# Dump all our files in temporary directory.

	TMP="/tmp/plot-$$"
	mkdir "$TMP"

	# Parse the input (syslog files) for the 'verbose' watchdog daemon's messages.
	# Convert any memory use from kB in to MB for easier plotting.

	grep 'memory+swap available' "$ipfile" | awk '{print $1, $2, $3, $9/1024, $11/1024}' > $TMP/memory
	grep 'current load is'       "$ipfile" | awk '{print $1, $2, $3, $9, $10, $11}'      > $TMP/load
	grep 'got answer on ping'    "$ipfile" | sed 's/time=/ /g;s/ms/ /g;' | awk '{print $1, $2, $3, $13}' > $TMP/ptime

	# Now go to temp location (not earlier as input files might have been relative
	# path) and plot as found.

	pushd $TMP > /dev/null

	size=1024,768

	if [ -s "memory" ] ; then
		echo "Creating $pname-memory.png"

		echo "reset;\
		 set terminal png size $size;\
		 set output \"$pname-memory.png\";\
		 set xdata time;\
		 set timefmt \"%b %d %H:%M:%S\";\
		 set format x \"%H:%M\";\
		 set xlabel \"Time (HH:MM)\";\
		 set ylabel \"free (MB)\";\
		 set key below;\
		 set grid ;\
		 plot \"memory\" using 1:4 with lines title \"memory\";" | gnuplot

		echo "Creating $pname-swap.png"

		echo "reset;\
		 set terminal png size $size;\
		 set output \"$pname-swap.png\";\
		 set xdata time;\
		 set timefmt \"%b %d %H:%M:%S\";\
		 set format x \"%H:%M\";\
		 set xlabel \"Time (HH:MM)\";\
		 set ylabel \"free (MB)\";\
		 set key below;\
		 set grid ;\
		 plot \"memory\" using 1:5 with lines title \"swap\";" | gnuplot
	fi

	if [ -s "load" ] ; then
		echo "Creating $pname-load.png"

		echo "reset;\
		 set terminal png size $size;\
		 set output \"$pname-load.png\";\
		 set xdata time;\
		 set timefmt \"%b %d %H:%M:%S\";\
		 set format x \"%H:%M\";\
		 set xlabel \"Time (HH:MM)\";\
		 set ylabel \"Load averages\";\
		 set key below;\
		 set grid ;\
		 plot \"load\" using 1:4 with lines title \"1-min\";" | gnuplot

		echo "Creating $pname-load-3.png"

		echo "reset;\
		 set terminal png size $size;\
		 set output \"$pname-load-3.png\";\
		 set xdata time;\
		 set timefmt \"%b %d %H:%M:%S\";\
		 set format x \"%H:%M\";\
		 set xlabel \"Time (HH:MM)\";\
		 set ylabel \"Load averages\";\
		 set yrange [0:8];\
		 set key below;\
		 set grid ;\
		 plot\
		 \"load\" using 1:4 with lines title \"1-min\",\
		 \"load\" using 1:5 with lines title \"5-min\",\
		 \"load\" using 1:6 with lines title \"15-min\";" | gnuplot
	fi

	if [ -s "ptime" ] ; then
		echo "Creating $pname-ping.png"

		echo "reset;\
		 set terminal png size $size;\
		 set output \"$pname-ping.png\";\
		 set xdata time;\
		 set timefmt \"%b %d %H:%M:%S\";\
		 set format x \"%H:%M\";\
		 set xlabel \"Time (HH:MM)\";\
		 set ylabel \"Ping time (ms)\";\
		 set key below;\
		 set grid ;\
		 plot \"ptime\" using 1:4 with lines title \"ping\";" | gnuplot
	fi

	# Clean up temporary location.
	popd > /dev/null
	rm -rf "$TMP"

done

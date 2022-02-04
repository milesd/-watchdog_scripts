Some scripts and configuration for use on nagios to check up
on argus. They are:

check_tmp.sh      - Should be used with regular watchdog daemon
                    to check that /tmp can support the creation of
                    temporary directories.

test_argus_mount.sh - Used with a 2nd watchdog that can't reboot
                    the nagios machine to see if argus is still
                    serving files via NFS (at least, listing them
                    in a mounted directory).

repair_argus_NMI.sh - Used when a fault is uncovered to trigger the
                    LOM based issuing of an NMI to force the heads to
                    fail-over and (hopefully) recover the operation.

argus_watchdog.conf - This is a separate configuration file for the
                    watchdog daemon's 2nd instance that is used just
                    to run the above in a time-tested manner and to
                    use the time-out features.

argus_watchdog    - This runs a 2nd instance of the watchdog but
                    only to run the above. Assumes that files are all
                    in the /etc/argus_watchdog/ directory. Intented as
                    an entry in /etc/init.d

install.sh        - This script is run in this directory on the target
                    machine (i.e. nagios) and it sets up the /etc
                    sub-directory and the init scripts.

psc Tue Dec 08 16:27:33 GMT 2015

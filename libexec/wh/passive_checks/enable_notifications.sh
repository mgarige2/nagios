#!/bin/bash

now=`date +%s`
commandfile='/usr/local/nagios/var/rw/nagios.cmd'

/usr/bin/printf "[%lu] ENABLE_NOTIFICATIONS\n" $now > $commandfile



#!/bin/sh

echo $(date) > /usr/local/nagios/share/checknagios.html
echo $(hostname) >> /usr/local/nagios/share/checknagios.html
/usr/local/bin/checknagios | sed 's/$/<br>/' >> /usr/local/nagios/share/checknagios.html


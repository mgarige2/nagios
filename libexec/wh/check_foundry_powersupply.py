#!/usr/bin/env python
# check_foundry_powersupply - nagios plugin
#
# Copyright (C) 2008 S. Barbereau
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
#
#
# Report bugs to: nagios@barbich.net
#
# Description:
#  This module checks the state of the power supploes on a Foundry Sw/Rt
#
# Nagios command:
#   define command {
#       command_name        check_foundry_powersupply
#       command_line        $USER1$/check_foundry_powersupply.py -H $HOSTNAME$ -C $ARG1$
#   }
# Nagios usage;
#    define service {
#        host_name                           sx-switch,rx-switch
#        service_description                 Foundry Power Supply
#        normal_check_interval               5
#        notification_period                 24x7
#        check_command                       check_foundry_powersupply!SNMPCOMMUNITY
#    }
# CLI usage:
# bash~: /usr/local/nagios/libexec # ./check_foundry_powersupply.py -H rx-switch -C PUBLIC
# Power supply : OK:7 , (Total slots: 7)


from pysnmp.entity.rfc3413.oneliner import cmdgen
import sys,re,os
from optparse import OptionParser

def arg_parse():
    usage="%prog [options] arg"
    parser = OptionParser(usage)
    parser.add_option("-H", "--hostname", dest="hostname",help="device to query",default='localhost')
    parser.add_option("-C", "--community", dest="community",help="snmp community",default='public')
    (options, args) = parser.parse_args(args=sys.argv[1:])
    if len(args)!=0:
	parser.error("Error in command line options")
    if options.hostname=='localhost':
	parser.error("Please specify a hostname.")
    return options

if __name__=="__main__":
    try:
        import psyco
        psyco.full()
    except ImportError:
        pass
    my_options=arg_parse()
    my_oid=(1,3,6,1,4,1,1991,1,1,1,2,1,1,3)
    my_community=my_options.community
    my_router=my_options.hostname
    nagios_states={'OK':0,'WARNING':1,'CRITICAL':2,'UNKNOWN':3,'DEPENDENT':4}
    my_state='UNKNOWN'
    errorIndication, errorStatus, errorIndex, varBinds = cmdgen.CommandGenerator().nextCmd(
	cmdgen.CommunityData('my-agent', my_community, 1),
	cmdgen.UdpTransportTarget((my_router, 161)),
	my_oid
	)
    if errorIndication:
	print "Error setting up context : %s." % errorIndication
	sys.exit(3)
    my_status={'Empty':0,'OK':0,'Problem':0,'total':0}
    for varBindTableRow in varBinds:
        my_status['total']=my_status['total']+1
	if varBindTableRow[0][1]==1:
	    my_status['Empty']=my_status['Empty']+1
	    continue
	if varBindTableRow[0][1]==2:
	    my_status['OK']=my_status['OK']+1
	    continue
	if varBindTableRow[0][1]==3:
	    my_status['Problem']=my_status['Problem']+1
	    continue
    response_text= "Power supply : "
    for k in my_status:
	if my_status[k]>0 and k!='total':
    	    response_text = response_text + "%s:%s ," % (k,my_status[k])
    response_text = response_text + " (Total slots: %s)" % my_status['total']
    my_state='WARNING'
    if my_status['Problem']==0:
	my_state='OK'
    if (my_status['Problem']+my_status['OK']+my_status['Empty']) != my_status['total']:
	my_state='UNKNOWN'
    print response_text
    sys.exit(nagios_states[my_state])

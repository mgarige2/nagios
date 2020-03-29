#!/usr/bin/python
# 
from SOAPpy import SOAPProxy
import sys
import re
import getopt

def usage():
	print "-I --impact, -U --urgency, -P --priority, -l --location, -u --user, -g --group, -t --to, -s --shortdesc *MUST HAVE*, -d --description, -c --comment, -i --configitem"

def createincident(params_dict):
 
        # instance to send to
        instance='reachlocaldev'
 
        # username/password

        username='cmdbservice'
        password='!mp0rtCI'
 
        # proxy - NOTE: ALWAYS use https://INSTANCE.service-now.com, not https://www.service-now.com/INSTANCE for web services URL from now on!
        proxy = 'https://%s:%s@%s.service-now.com/incident.do?SOAP' % (username, password, instance)
        namespace = 'http://www.service-now.com/'
        server = SOAPProxy(proxy, namespace)
 
        # uncomment these for LOTS of debugging output
        server.config.dumpHeadersIn = 1
        server.config.dumpHeadersOut = 1
        server.config.dumpSOAPOut = 1
        server.config.dumpSOAPIn = 1

	long_description = re.sub(r'\\n', r'\n', params_dict['description'])
 
        response = server.insert(impact=int(params_dict['impact']), urgency=int(params_dict['urgency']), priority=int(params_dict['priority']), u_locations_impacted=params_dict['u_locations_impacted'], caller_id=params_dict['user'], assignment_group=params_dict['assignment_group'], assigned_to=params_dict['assigned_to'], short_description=params_dict['short_description'], description=long_description, comments=params_dict['comments'], u_configuration_item=params_dict['u_configuration_item'])
 
        return response
try:
	opts, args = getopt.getopt(sys.argv[1:], "I:U:P:l:u:g:t:s:d:c:i:h", ["impact", "urgency", "priority", "u_locations_impacted", "user", "assignment_group", "assigned_to", "short_description", "description", "comment", "u_configuration_item", "help"])
except getopt.GetoptError, err:
	print str(err)

impact = "3"
urgency = "3"
priority = "5"
location = "All Datacenters"
user = None
assignment_group = "SRE"
assigned_to = ""
short_description = None
description = "description"
comment = "comment"
configitem = None

for o, a in opts:
	if o in ("-I", "--impact"):
		impact = a
        if o in ("-U", "--urgency"):
                urgency = a
        if o in ("-P", "--priority"):
                priority = a
        if o in ("-l", "--location"):
                location = a
        if o in ("-u", "--user"):
                user = a
        if o in ("-g", "--group"):
                assignment_group = a
        if o in ("-t", "--to"):
                assigned_to = a
        if o in ("-s", "--shortdesc"):
                short_description = a
        if o in ("-d", "--description"):
                description = a
        if o in ("-c", "--comment"):
                comment = a
        if o in ("-i", "--configitem"):
                configitem = a
	elif o in ("-h", "--help"):
		usage()
		sys.exit()

if not short_description:
	usage()
	sys.exit()

values = {'impact': impact, 'urgency': urgency, 'priority': priority, 'u_locations_impacted': location, 'user': user, 'assignment_group': assignment_group, 'assigned_to': assigned_to, 'short_description': short_description, 'description': description, 'comments': comment, 'u_configuration_item': configitem }

new_incident_sysid=createincident(values)
 
print "Returned sysid: "+repr(new_incident_sysid)

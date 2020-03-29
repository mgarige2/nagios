#!/usr/bin/env python
#
# Check XenServer SR utilization
# (c) copyright Pekka Panula / Sofor oy
# Licence: GPLv2 or later
# Author: Pekka Panula, e-mail: pekka.panula@sofor.fi
# Contact if bugs, etc.
#
# Usage: ./check_sr.py <XenServer IP or FQDN> <username> <password> <sr name> <warning level %> <critical level %>
#
# - Uses https to connect to XenServer, if you have a pool, use a poolmaster IP/FQDN
# - <sr name> is a case sensitive
# - Uses (python) XenAPI, download it from Citrix, http://community.citrix.com/display/xs/Download+SDKs
# - tested on CentOS 5.8 / python 2.x, should work on any modern distro/python AFAIK
#
# example: ./check_sr.py 192.168.0.1 root password MySR 90 95
#
#
# Dated: 15.11.2012
# Version: 1.0
#
# Version history:
# - v1.0: Initial release
# 
# nagios command defination: 
#
# define command{
#        command_name    check_xenserver_sr
#        command_line    $USER1$/check_sr.py $ARG1$ "$USER15$" "$USER16$" "$ARG2$" $ARG3$ $ARG4$
# }
#
# USER16 and USER15 are username and password in resource.cfg


from __future__ import division
import sys, time, atexit
import XenAPI

def logout():
    try:
        session.xenapi.session.logout()
    except:
        pass

atexit.register(logout)

def humanize_bytes(bytes, precision=2):
    abbrevs = (
        (1<<50L, 'Pb'),
        (1<<40L, 'Tb'),
        (1<<30L, 'Gb'),
        (1<<20L, 'Mb'),
        (1<<10L, 'kb'),
        (1, 'bytes')
    )
    if bytes == 1:
        return '1 byte'
    for factor, suffix in abbrevs:
        if bytes >= factor:
            break
    return '%.*f%s' % (precision, bytes / factor, suffix)

def humanize_bytes_nosuffix(bytes, precision=2):
    abbrevs = (
        (1<<50L, 'Pb'),
        (1<<40L, 'Tb'),
        (1<<30L, 'Gb'),
        (1<<20L, 'Mb'),
        (1<<10L, 'kb'),
        (1, 'bytes')
    )
    if bytes == 1:
        return '1 byte'
    for factor, suffix in abbrevs:
        if bytes >= factor:
            break
    return '%.*f' % (precision, bytes / factor)


def performancedata(sr_name,total,alloc,warning,critical):

	performance_line = "'"+sr_name + "_used_space'=" + str(alloc).replace(".",",") + ";" + str(warning).replace(".",",") + ";" + str(critical).replace(".",",") + ";0.00;" + str(total).replace(".",",") +""
	return(performance_line)

def main(session, sr_name, warning, critical):

        gb_factor=1073741824
	mb_factor=1024*1024

	sr = session.xenapi.SR.get_by_name_label(sr_name)
	if sr:
		sr_size          = session.xenapi.SR.get_physical_size(sr[0])
		sr_phys_util     = session.xenapi.SR.get_physical_utilisation(sr[0])
		sr_virtual_alloc = session.xenapi.SR.get_virtual_allocation(sr[0])

		total_bytes_gb   = int(sr_size)      / gb_factor
		total_bytes_mb   = int(sr_size)      / mb_factor
		total_bytes_b    = int(sr_size)
		total_alloc_gb   = int(sr_phys_util) / gb_factor
		total_alloc_mb   = int(sr_phys_util) / mb_factor
		total_alloc_b    = int(sr_phys_util)
		virtual_alloc_gb = int(sr_virtual_alloc) / gb_factor
		virtual_alloc_mb = int(sr_virtual_alloc) / mb_factor
		free_space       = int(total_bytes_gb) - int(total_alloc_gb)
		used_percent     = 100*float(total_alloc_gb)/float(total_bytes_gb)
		warning_gb       = (float(total_bytes_gb) / 100) * float(warning)
		warning_mb       = (float(total_bytes_mb) / 100) * float(warning)
		warning_b        = (float(total_bytes_b)  / 100) * float(warning)
		critical_gb      = (float(total_bytes_gb) / 100) * float(critical)
		critical_mb      = (float(total_bytes_mb) / 100) * float(critical)
		critical_b       = (float(total_bytes_b)  / 100) * float(critical)

		if float(used_percent) >= float(critical):
			print "CRITICAL: SR", sr_name, "utilization =", str(round(used_percent,2)), "%, size =", str(round(total_bytes_gb,2)), "GB, used =", str(round(total_alloc_gb,2)), "GB, free =", str(round(free_space,2)), "GB"," | " + performancedata(sr_name,humanize_bytes_nosuffix(total_bytes_b),humanize_bytes(total_alloc_b),humanize_bytes_nosuffix(warning_b),humanize_bytes_nosuffix(critical_b))
			exitcode = 2
		elif float(used_percent) >= float(warning):
			print "WARNING: SR", sr_name, "utilization =", str(round(used_percent,2)), "%, size =", str(round(total_bytes_gb,2)), "GB, used =", str(round(total_alloc_gb,2)), "GB, free =", str(round(free_space,2)), "GB", " | " + performancedata(sr_name,humanize_bytes_nosuffix(total_bytes_b),humanize_bytes(total_alloc_b),humanize_bytes_nosuffix(warning_b),humanize_bytes_nosuffix(critical_b))
			exitcode = 1
		else:
			print "OK: SR", sr_name, "utilization =", str(round(used_percent,2)), "%, size =", str(round(total_bytes_gb,2)), "GB, used =", str(round(total_alloc_gb,2)), "GB, free =", str(round(free_space,2)), "GB", " | " + performancedata(sr_name,humanize_bytes_nosuffix(total_bytes_b),humanize_bytes(total_alloc_b),humanize_bytes_nosuffix(warning_b),humanize_bytes_nosuffix(critical_b))
			exitcode = 0

		print "SR Physical size, bytes:" , str(total_bytes_b), "B"
		print "SR Virtual allocation:" , str(sr_virtual_alloc), "B, ", str(virtual_alloc_mb), "MB, ", str(virtual_alloc_gb), "GB"
		print "SR Physical Utilization, bytes:" , str(total_alloc_b), "B"
		print "SR Free space:", str(free_space), "GB"
		print "SR Space used %:", str(round(used_percent,2)), "%"
		print "SR Warning  level, MB:", str(warning_mb), "MB"
		print "SR Critical level, MB:", str(critical_mb), "MB"

		sys.exit(exitcode)
		

	else:
		print "CRITICAL: Cant get SR, check SR name! SR =", sr_name
		sys.exit(2)



if __name__ == "__main__":
	if len(sys.argv) <> 7:
		print "Usage:"
		print sys.argv[0], " <XenServer poolmaster ip or fqdn> <username> <password> <sr name> <warning %> <critical %>"
		sys.exit(1)
	url = sys.argv[1]
	username = sys.argv[2]
	password = sys.argv[3]
	sr_name  = sys.argv[4]
	warning  = sys.argv[5]
	critical = sys.argv[6]

	# First acquire a valid session by logging in:
	try:
		session = XenAPI.Session("https://"+url)
	except Exception, e:
		print "CRITICAL: Cant get XenServer session, error: ", str(e)
		sys.exit(2)
	try:
		session.xenapi.login_with_password(username, password)
	except Exception, e:
		print "CRITICAL: Cant login to XenServer, error: ", str(e)
		sys.exit(2)

	main(session, sr_name, warning, critical)

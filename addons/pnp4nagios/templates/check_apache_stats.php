<?php
#   This program is free software; you can redistribute it and/or modify
#   it under the terms of the GNU General Public License as published by
#   the Free Software Foundation; either version 2 of the License, or
#   (at your option) any later version.
#
#   This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License
#   along with this program; if not, write to the Free Software
#   Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA

#   PNP Template for check_bind.sh
#   Author: Mike Adolphs (http://www.matejunkie.com/)

$opt[1] = "--vertical-label \"Workers \" -l 0 -r --title \"Apache Process Metrics for $hostname\" --right-axis 1:0 --right-axis-label \"Requests/sec\" ";
#$def[1] = "DEF:cpu=$rrdfile:$DS[1]:AVERAGE " ;
$def[1] = "DEF:reqpsec=$rrdfile:$DS[2]:AVERAGE " ;
$def[1] .= "DEF:wbusy=$rrdfile:$DS[5]:AVERAGE " ;
$def[1] .= "DEF:widle=$rrdfile:$DS[6]:AVERAGE " ;

$ds_name[1] = "process_stats" ;
$def[1] .= "COMMENT:\"\\t\\t\\t\\tLAST\\t\\tAVERAGE\\tMAX\\n\" " ;

#$def[1] .= "LINE2:cpu#008000:\"CPU usage [%]\\t \" " ;
#$def[1] .= "GPRINT:cpu:LAST:\"%6.0lf\\t\" " ;
#$def[1] .= "GPRINT:cpu:AVERAGE:\" %6.0lf\\t\" " ;
#$def[1] .= "GPRINT:cpu:MAX:\" %6.0lf\\n\" " ;

$def[1] .= "LINE2:reqpsec#0C64E8:\"Requests/sec\\t \" " ;
$def[1] .= "GPRINT:reqpsec:LAST:\"%6.0lf\\t\" " ;
$def[1] .= "GPRINT:reqpsec:AVERAGE:\" %6.0lf\\t\" " ;
$def[1] .= "GPRINT:reqpsec:MAX:\" %6.0lf\\n\" " ;

$def[1] .= "LINE2:wbusy#1CC8E8:\"Busy workers\\t \" " ;
$def[1] .= "GPRINT:wbusy:LAST:\"%6.0lf\\t\" " ;
$def[1] .= "GPRINT:wbusy:AVERAGE:\" %6.0lf\\t\" " ;
$def[1] .= "GPRINT:wbusy:MAX:\" %6.0lf\\n\" " ;

$def[1] .= "LINE2:widle#E80C8C:\"Idle workers\\t \" " ;
$def[1] .= "GPRINT:widle:LAST:\"%6.0lf\\t\" " ;
$def[1] .= "GPRINT:widle:AVERAGE:\" %6.0lf\\t\" " ;
$def[1] .= "GPRINT:widle:MAX:\" %6.0lf\\n\" " ;

$opt[2] = "--vertical-label \"Bytes/sec \" -l 0 -r --title \"Apache Network Metrics for $hostname\" --right-axis .1:0 --right-axis-label \"Bytes/req \" ";
$def[2] = "DEF:bytepreq=$rrdfile:$DS[4]:AVERAGE " ;
$def[2] .= "DEF:bytepsec=$rrdfile:$DS[3]:AVERAGE " ;

$ds_name[2] = "network_stats" ;
$def[2] .= "COMMENT:\"\\t\\t\\t\\tLAST\\t\\tAVERAGE\\t\\tMAX\\n\" " ;
$def[2] .= "CDEF:bytepreqadj=bytepreq,10,* " ;

$def[2] .= "LINE2:bytepsec#E80C3E:\"Byte/sec\\t\\t \" " ;
$def[2] .= "GPRINT:bytepsec:LAST:\"%6.0lf\\t\" " ;
$def[2] .= "GPRINT:bytepsec:AVERAGE:\" %6.0lf\\t\\t\" " ;
$def[2] .= "GPRINT:bytepsec:MAX:\" %6.0lf\\n\" " ;

$def[2] .= "LINE2:bytepreqadj#FFA500:\"Byte/req\\t\\t \" " ;
$def[2] .= "GPRINT:bytepreq:LAST:\"%6.0lf\\t\" " ;
$def[2] .= "GPRINT:bytepreq:AVERAGE:\" %6.0lf\\t\\t\" " ;
$def[2] .= "GPRINT:bytepreq:MAX:\" %6.0lf\\n\" " ;

?>


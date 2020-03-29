<?php
# Plugin: check_snmp_netint_sales
#
$ds_name[1] = "Interface Traffic (bps)";
$max=$MAX[1] ;
$opt[1] = "--vertical-label \"Traffic\" -b 1024 --title \"$servicedesc ($hostname)\" ";
$def[1] = "DEF:var1=$rrdfile:$DS[1]:AVERAGE " ;
$max=$MAX[1] ;
$def[1] .= "DEF:var2=$rrdfile:$DS[2]:AVERAGE " ;
$def[1] .= "AREA:var1#003300:\"RX\" " ;
#$def[1] .= "HRULE:$max#0000FF " ;
$def[1] .= "GPRINT:var1:LAST:\"%7.2lf %Sb/s last\" " ;
$def[1] .= "GPRINT:var1:AVERAGE:\"%7.2lf %Sb/s avg\" " ;
$def[1] .= "GPRINT:var1:MAX:\"%7.2lf %Sb/s max\\n\" " ;
$def[1] .= "AREA:var2#00ff00:\"TX\" " ;
$def[1] .= "GPRINT:var2:LAST:\"%7.2lf %Sb/s last\" " ;
$def[1] .= "GPRINT:var2:AVERAGE:\"%7.2lf %Sb/s avg\" " ;
$def[1] .= "GPRINT:var2:MAX:\"%7.2lf %Sb/s max\" ";
?>



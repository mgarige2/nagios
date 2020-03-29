<?php
#
# Copyright (c) 2006-2010 Joerg Linge (http://www.pnp4nagios.org)
# Plugin: check_nt -v CPULOAD
#        
$opt[1] = "--vertical-label \"$UNIT[1]\" -u $MAX[1] --logarithmic --units=si --units-length 5  --title \"CPU Load for $hostname / $servicedesc\" ";
$ds_name[1] = "System Load" ;
#
#
#
$def[1] =  "DEF:var1=$RRDFILE[1]:$DS[1]:AVERAGE " ;

if ($WARN[1] != "") {
        $def[1] .= "HRULE:$WARN[1]#FFFF00 ";
}
if ($CRIT[1] != "") {
        $def[1] .= "HRULE:$CRIT[1]#FF0000 ";
}
$def[1] .= "AREA:var1#808080:\"$NAME[1] \" " ;
$def[1] .= "LINE1:var1#303030 " ;
$def[1] .= "GPRINT:var1:LAST:\"%6.2lf$UNIT[1] last\" " ;
$def[1] .= "GPRINT:var1:AVERAGE:\"%6.2lf$UNIT[1] avg\" " ;
$def[1] .= "GPRINT:var1:MAX:\"%6.2lf$UNIT[1] max\\n\" ";

$def[1] .=  "DEF:var2=$RRDFILE[1]:$DS[2]:AVERAGE " ;
$def[1] .= "LINE2:var2#000080:\"$NAME[2] \" " ;
#$def[1] .= "LINE1:var1#000000 " ;
$def[1] .= "GPRINT:var1:LAST:\"%6.2lf$UNIT[2] last\" " ;
$def[1] .= "GPRINT:var1:AVERAGE:\"%6.2lf$UNIT[2] avg\" " ;
$def[1] .= "GPRINT:var1:MAX:\"%6.2lf$UNIT[2] max\\n\" ";

?>


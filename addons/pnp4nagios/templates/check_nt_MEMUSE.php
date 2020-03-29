<?php
#
# Plugin: check_mem
#
$ds_name[1] = "$NAGIOS_AUTH_SERVICEDESC";
$halfmax = $MAX[1]/2 ;
$max = $MAX[1]-$halfmax ;
$upper = $max+.5 ;
$opt[1] = "--vertical-label \"$UNIT[1]\" -l 0 -u $upper --title \"$hostname / $servicedesc\" ";
$def[1]  = rrd::def("var1", $RRDFILE[1], $DS[1], "AVERAGE");
#$def[1] =  "DEF:var1=$MAX[1] " ;
#$def[1] .= rrd::def("var2", $RRDFILE[1], $DS[1], "AVERAGE");
#$def[1] .= rrd::def("var3", $RRDFILE[3], $DS[3], "AVERAGE");
#$def[1] .= rrd::def("var4", $RRDFILE[4], $DS[4], "AVERAGE");

#if ($WARN[1] != "") {
#    $def[1] .= "HRULE:$WARN[1]#FFFF00 ";
#}
#if ($CRIT[1] != "") {
#    $def[1] .= "HRULE:$CRIT[1]#FF0000 ";       
#}
$def[1] .= rrd::area("var1", "#00FF00", "USED MEMORY ") ;
$def[1] .= rrd::gprint("var1", array("LAST", "AVERAGE", "MAX"), "%6.2lfMb");
#$def[1] .= "LINE1:var1#00000c" ;
$def[1] .= rrd::hrule( $max, "#FF0000", "TOTAL PHYSICAL RAM $max Mb \\n");
#$def[1] .= rrd::hrule( $MAX[1], "#FF0000", "TOTAL $MAX[1] Mb \\n");
#$def[1] .= rrd::gprint($MAX[1], array("MAX"), "%6.2lf");
#$def[1] .= rrd::line2("var2", "#000000", "Total") ;
#$def[1] .= rrd::gprint("var2", array("LAST", "AVERAGE", "MAX"), "%6.2lf");
#$def[1] .= rrd::area("var3", "#5a3d99", "Free") ;
#$def[1] .= rrd::gprint("var3", array("LAST", "AVERAGE", "MAX"), "%6.2lf");
#$def[1] .= rrd::area("var4", "#e5ca44", "Cache") ;
#$def[1] .= rrd::gprint("var4", array("LAST", "AVERAGE", "MAX"), "%6.2lf");
?>


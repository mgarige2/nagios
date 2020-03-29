<?php
#
# Copyright (c) 2006-2010 Joerg Linge (http://www.pnp4nagios.org)
# Plugin: check_load
#

$opt[1] = "--vertical-label Load -l 0 --alt-autoscale-max --title \"CPU Load for $hostname / $servicedesc\" ";
#
#
#
$def[1]  = rrd::def("var1", $RRDFILE[1], $DS[1], "AVERAGE");
$def[1] .= rrd::def("var2", $RRDFILE[2], $DS[2], "AVERAGE");
$def[1] .= rrd::def("var3", $RRDFILE[3], $DS[3], "AVERAGE");

if ($WARN[1] != "") {
    $def[1] .= "HRULE:$WARN[1]#FFFF00 ";
}
if ($CRIT[1] != "") {
    $def[1] .= "HRULE:$CRIT[1]#FF0000 ";       
}

$def[1] .= rrd::area("var1", "#808080", "Load 1 " ) ;
$def[1] .= rrd::line1("var1", "#303030" ) ;
$def[1] .= rrd::gprint("var1", array("LAST", "AVERAGE", "MAX"), "%6.2lf");
$def[1] .= rrd::line2("var2", "#800000", "Load 5 " ) ;
$def[1] .= rrd::gprint("var2", array("LAST", "AVERAGE", "MAX"), "%6.2lf");
$def[1] .= rrd::line2("var3", "#000080", "Load 15 " ) ;
$def[1] .= rrd::gprint("var3", array("LAST", "AVERAGE", "MAX"), "%6.2lf");

try {
   require_once('Builds.class.php');
   $releases = Builds::fetchReleaseData($hostname);
   $i=0;
   foreach ($releases as $release) {
      $temptime=$release['time'];
      $tempbname=$release['buildname'];
      $tempcolor=$release['color'];
      if ($i % 2 == 0) {
         $def[1] .= "VRULE:" . $temptime . "#" . $tempcolor . ":\"" . $tempbname . "\\t\\t\\t\" " ;
      }
      else {
         $def[1] .= "VRULE:" . $temptime . "#" . $tempcolor . ":\"" . $tempbname . "\\n\" " ;
      }
      $i++;
   }
} catch (Exception $e) {
      echo "Error: " . $e;
}

?>

<?php
#
# Copyright (c) 2006-2010 Joerg Linge (http://www.pnp4nagios.org)
# Plugin: check_icmp [Multigraph]
#
# RTA
#
$ds_name[1] = "Memory Usage";
$max = $MAX[1]+($MAX[1]*.1) ;
$max = $max/1024 ;
$maxmem = round($MAX[1]/1024) ;
$unit = "Mb" ;
$opt[1]  = "--vertical-label \"Memory Used\" -l 0 -u $max -r --title \"Memory Usage\" ";

$def[1]  =  rrd::def("var1", $RRDFILE[1], $DS[1], "AVERAGE") ;
$def[1] .=  rrd::cdef("var1mb", "var1,1024,/");
$def[1] .=  rrd::gradient("var1mb", "#00cc00", "#aa0000", "Mb Used", 20) ;
$def[1] .=  rrd::gprint("var1mb", array("LAST", "MAX", "AVERAGE"), "%3.0lf $unit") ;
$def[1] .=  rrd::line1("var1mb", "#000000") ;
$def[1] .=  rrd::hrule( $maxmem, "#000000", "TOTAL PHYSICAL RAM $maxmem Mb \\n") ;

if($WARN[1] != ""){
	$warning = round($WARN[1]/1024) ;
	if($UNIT[1] == "%%"){ $UNIT[1] = "%"; };
	$UNIT[1] = "Mb";
  	$def[1] .= rrd::hrule($warning, "#FFFF00", "Warning  ".$warning.$UNIT[1]."\\n");
}
if($CRIT[1] != ""){
	$critical = round($CRIT[1]/1024) ;
	if($UNIT[1] == "%%"){ $UNIT[1] = "%"; };
	$UNIT[1] = "Mb";
  	$def[1] .= rrd::hrule($critical, "#FF0000", "Critical ".$critical.$UNIT[1]."\\n");
}


#
# Packets Lost

$ds_name[2] = "Swap Usage";
$max1 = $MAX[2]+($MAX[2]*.1) ;
$max1 = round($max1/1024) ;
$maxswap = round($MAX[2]/1024) ;
$unit = "Mb" ;

$opt[2] = "--vertical-label \"Swap Used\" -l 0 -u $max1 -r --title \"Swap Usage\" ";

$def[2]  =  rrd::def("var2", $RRDFILE[2], $DS[2], "AVERAGE");
$def[2]	.=  rrd::cdef("var2mb", "var2,1024,/");
$def[2] .=  rrd::gradient("var2mb", "#00cc00", "#aa0000", "Swap Used Mb", 20 ) ;
$def[2] .=  rrd::gprint("var2mb", array("LAST", "MAX", "AVERAGE"), "%3.0lf $unit") ;
$def[2] .=  rrd::line1("var2mb", "#000000") ;
$def[2] .=  rrd::hrule( $maxswap, "#000000", "TOTAL SWAP $maxswap Mb \\n") ;

if($WARN[2] != ""){
	$warning = round($WARN[2]/1024) ;
	if($UNIT[2] == "%%"){ $UNIT[2] = "%"; };
	$UNIT[2]="Mb";
  	$def[2] .= rrd::hrule($warning, "#FFFF00", "Warning  ".$warning.$UNIT[2]."\\n");
}
if($CRIT[2] != ""){
	$critical = round($CRIT[2]/1024) ;
	if($UNIT[2] == "%%"){ $UNIT[2] = "%"; };
	$UNIT[2]="Mb";
  	$def[2] .= rrd::hrule($critical, "#FF0000", "Critical ".$critical.$UNIT[2]."\\n");
}

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
         $def[2] .= "VRULE:" . $temptime . "#" . $tempcolor . ":\"" . $tempbname . "\\t\\t\\t\" " ;
      }
      else {
         $def[1] .= "VRULE:" . $temptime . "#" . $tempcolor . ":\"" . $tempbname . "\\n\" " ;
         $def[2] .= "VRULE:" . $temptime . "#" . $tempcolor . ":\"" . $tempbname . "\\t\\t\\t\" " ;
      }
      $i++;
   }
} catch (Exception $e) {
      echo "Error: " . $e;
}


?>

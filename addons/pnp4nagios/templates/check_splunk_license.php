<?php
#
# Copyright (c) 2006-2010 Joerg Linge (http://www.pnp4nagios.org)
# Template for integer values 
#
$def[1] = "";
$opt[1] = "";
$colors = array('#000000', '#ff0000', '#000000', '#f00', '#f0f', '#00f', '#0ff');
foreach ( $DS as $KEY => $VAL ){
	$opt[1] .= "--alt-y-grid -l 0 --vertical-label \"Mb\"  --title \"Splunk License\" ";
	$def[1] .= "DEF:var_float$KEY=$RRDFILE[$KEY]:$DS[$KEY]:MAX " ;
	
	$def[1] .= "CDEF:var$KEY=var_float$KEY,FLOOR " ;
	$def[1] .= "CDEF:var1$KEY=var_float$KEY,1048576,/ " ;
	if ($KEY==1) { $def[1] .= "AREA:var1$KEY$colors[$KEY]:\"$LABEL[$KEY]\" " ; }
	else { $def[1] .= "LINE2:var1$KEY$colors[$KEY]:\"$LABEL[$KEY]\" " ; }

	if ($WARN[$KEY] != "") {
	    $def[1] .= "HRULE:$WARN[$KEY]#FFFF00 ";
	}
	if ($CRIT[$KEY] != "") {
	    $def[1] .= "HRULE:$CRIT[$KEY]#FF0000 ";
	}

	#$unit = pnp::adjust_unit( $UNIT[0],1048576, '%7.31f' );
	$def[1] .= "GPRINT:var1$KEY:LAST:\"%.0lf Mb LAST \" "; 
	$def[1] .= "GPRINT:var1$KEY:MIN:\"%.0lf Mb MIN \" ";
	$def[1] .= "GPRINT:var1$KEY:MAX:\"%.0lf Mb MAX \" "; 
	$def[1] .= "GPRINT:var1$KEY:AVERAGE:\"%.0lf Mb AVERAGE \\n\" "; 
}
?>

<?php
#
# Copyright (c) 2006-2010 Joerg Linge (http://www.pnp4nagios.org)
# Template for integer values 
#
#$def[1] = "";
#$opt[1] = "";
$colors = array('#000000', '#0f0', '#ff0', '#f00', '#f0f', '#00f', '#0ff', '#0f0', '#ff0', '#f00', '#f0f', '#00f', '#0ff', '#0f0', '#ff0', '#f00', '#f0f', '#00f', '#0ff', '#0f0', '#ff0', '#f00', '#f0f', '#00f', '#0ff','#0f0', '#ff0', '#f00', '#f0f', '#00f', '#0ff','#0f0', '#ff0', '#f00', '#f0f', '#00f', '#0ff','#0f0', '#ff0', '#f00', '#f0f', '#00f', '#0ff','#0f0', '#ff0', '#f00', '#f0f', '#00f', '#0ff');
foreach ( $DS as $KEY => $VAL ){
	$def[$KEY] = "";
	$opt[$KEY] = "";
	$ds_name[$KEY] = "$LABEL[$KEY]";	
	$opt[$KEY] .= "--alt-y-grid -l 0 --vertical-label \"$UNIT[$KEY]\"  --title \"$LABEL[$KEY]\" ";
	$def[$KEY] .= "DEF:var_float$KEY=$RRDFILE[$KEY]:$DS[$KEY]:MAX " ;
	$def[$KEY] .= "CDEF:var$KEY=var_float$KEY,FLOOR " ;
	$def[$KEY] .= "LINE2:var$KEY$colors[$KEY]:\"$LABEL[$KEY]\" " ;

	if ($WARN[$KEY] != "") {
	    $def[$KEY] .= "HRULE:$WARN[$KEY]#FFFF00 ";
	}
	if ($CRIT[$KEY] != "") {
	    $def[1] .= "HRULE:$CRIT[$KEY]#FF0000 ";
	}

	$def[$KEY] .= "GPRINT:var$KEY:LAST:\"%.0lf $UNIT[$KEY] LAST \" "; 
	$def[$KEY] .= "GPRINT:var$KEY:MAX:\"%.0lf $UNIT[$KEY] MAX \" "; 
	$def[$KEY] .= "GPRINT:var$KEY:AVERAGE:\"%.0lf $UNIT[$KEY] AVERAGE \\n\" "; 
}
?>

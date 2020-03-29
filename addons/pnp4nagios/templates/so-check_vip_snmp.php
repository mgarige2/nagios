<?php
#
###############################
# Copyright (c) 2006-2010 Joerg Linge (http://www.pnp4nagios.org)
# Template for integer values
#
$i = 0;
$def[1] = "";
$opt[1] = "--title \"$servicedesc for $hostname\" --alt-y-grid -l 0";
$colors = array('#32CD32', '#0000CD', '#00f', '#f0f', '#f0f', '#00f', '#0ff');
foreach ( $DS as $KEY => $VAL ){
        $def[1] .= "DEF:var_float$KEY=$RRDFILE[$KEY]:$DS[$KEY]:AVERAGE " ;
        if(($KEY == 2)) {
		$i++;
                $def[1] .= "CDEF:var$KEY=var_float$KEY,-1,* " ;
		if(($servicedesc == "VIP_Bandwidth")) {
	       		$def[1] .= "AREA:var$KEY$colors[$i]:\"$LABEL[$KEY]\" " ;
	        }
		$def[1] .= "LINE2:var$KEY$colors[$i]:\"$LABEL[$KEY]\" " ;

        } else {
		$def[1] .= "CDEF:var$KEY=var_float$KEY,1,* " ;
       	        if(($servicedesc == "VIP_Bandwidth")) {
			$def[1] .= "AREA:var$KEY$colors[$i]:\"$LABEL[$KEY]\" " ;
		}
	        $def[1] .= "LINE2:var$KEY$colors[$i]:\"$LABEL[$KEY]\" " ;
	}

        $def[1] .= "GPRINT:var$KEY:LAST:\"%.0lf $UNIT[$KEY] LAST \" ";
        $def[1] .= "GPRINT:var$KEY:MAX:\"%.0lf $UNIT[$KEY] MAX \" ";
        $def[1] .= "GPRINT:var$KEY:AVERAGE:\"%.0lf $UNIT[$KEY] AVERAGE \\n\" ";
}
?>


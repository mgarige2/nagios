<?php
#
# Copyright (c) 2006-2010 Joerg Linge (http://www.pnp4nagios.org)
# Default Template used if no other template is found.
# Don`t delete this file ! 
#
# Define some colors ..
#
$_WARNRULE = '#FFFF00';
$_CRITRULE = '#FF0000';
$_AREA     = '#256aef';
$_LINE     = '#000000';
#
# Initial Logic ...
#

foreach ($this->DS as $KEY=>$VAL) {

	$maximum  = "";
	$minimum  = "";
	$critical = "";
	$crit_min = "";
	$crit_max = "";
	$warning  = "";
	$warn_max = "";
	$warn_min = "";
	$vlabel   = " ";
	$lower    = "";
	$upper    = "";
	
	if ($VAL['WARN'] != "" && is_numeric($VAL['WARN']) ){
		$warning = $VAL['WARN'];
	}
	if ($VAL['WARN_MAX'] != "" && is_numeric($VAL['WARN_MAX']) ) {
		$warn_max = $VAL['WARN_MAX'];
	}
	if ( $VAL['WARN_MIN'] != "" && is_numeric($VAL['WARN_MIN']) ) {
		$warn_min = $VAL['WARN_MIN'];
	}
	if ( $VAL['CRIT'] != "" && is_numeric($VAL['CRIT']) ) {
		$critical = $VAL['CRIT'];
	}
	if ( $VAL['CRIT_MAX'] != "" && is_numeric($VAL['CRIT_MAX']) ) {
		$crit_max = $VAL['CRIT_MAX'];
	}
	if ( $VAL['CRIT_MIN'] != "" && is_numeric($VAL['CRIT_MIN']) ) {
		$crit_min = $VAL['CRIT_MIN'];
	}
	if ( $VAL['MIN'] != "" && is_numeric($VAL['MIN']) ) {
		$lower = " --lower=" . $VAL['MIN'];
		$minimum = $VAL['MIN'];
	}
	if ( $VAL['MAX'] != "" && is_numeric($VAL['MAX']) ) {
		$maximum = $VAL['MAX'];
	}
	if ($VAL['UNIT'] == "%%") {
		$vlabel = "%";
		$upper = " --upper=101 ";
		$lower = " --lower=0 ";
	}
	else {
		$vlabel = $VAL['UNIT'];
	}

	if($VAL['UNIT'] == 's') {
	$vlabel = "seconds";
	$unit = "s";
	$opt[$KEY] = '--vertical-label "' . $vlabel . '" --title "' . $this->MACRO['DISP_HOSTNAME'] . ' / Time Since Last Puppet Run"';
	$ds_name[$KEY] = "Time Since Last Puppet Run";
	$def[$KEY]  = rrd::def     ("var1", $VAL['RRDFILE'], $VAL['DS'], "AVERAGE");
	$def[$KEY] .= rrd::line2("var1", "#000000","time since last run");
	$def[$KEY] .= rrd::gprint  ("var1", array("LAST","MAX","AVERAGE"), "%3.0lf $unit");
	
        if ($warning != "") {
		$def[$KEY] .= rrd::hrule($warning, $_WARNRULE, "Warning  $warning \\n");
	}
	if ($warn_min != "") {
		$def[$KEY] .= rrd::hrule($warn_min, $_WARNRULE, "Warning  (min)  $warn_min \\n");
	}
	if ($warn_max != "") {
		$def[$KEY] .= rrd::hrule($warn_max, $_WARNRULE, "Warning  (max)  $warn_max \\n");
	}
	if ($critical != "") {
		$def[$KEY] .= rrd::hrule($critical, $_CRITRULE, "Critical $critical \\n");
	}
	if ($crit_min != "") {
		$def[$KEY] .= rrd::hrule($crit_min, $_CRITRULE, "Critical (min)  $crit_min \\n");
	}
	if ($crit_max != "") {
		$def[$KEY] .= rrd::hrule($crit_max, $_CRITRULE, "Critical (max)  $crit_max \\n");
	}
	}

	if($VAL['UNIT'] != 's' || $VAL['UNIT'] != 'sec') {
	$ds_name[2] = "Run Stats";

	$opt[2] = "--vertical-label \"Events\" -l 0 --title \"Success, Change, and Failure Events\" ";

	$def[2]  =  rrd::def("var2", $RRDFILE[2], $DS[2], "AVERAGE");
	$def[2] .=  rrd::line3("var2", "#00cc00","successes") ;
	$def[2] .=  rrd::gprint("var2", array("LAST", "MAX", "AVERAGE"), "%3.0lf success") ;
	$def[2] .=  rrd::def("var3", $RRDFILE[3], $DS[2], "AVERAGE");
	$def[2] .=  rrd::line2("var3", "#aa0000", "failures") ;
	$def[2] .=  rrd::gprint("var3", array("LAST", "MAX", "AVERAGE"), "%3.0lf failure") ;
	$def[2] .=  rrd::def("var5", $RRDFILE[5], $DS[2], "AVERAGE");
	$def[2] .=  rrd::line2("var5", "#0000aa", "changes");
	$def[2] .=  rrd::gprint("var5", array("LAST", "MAX", "AVERAGE"), "%3.0lf changes") ;
	}

	if($VAL['UNIT'] == 'sec') {
        $vlabel = "seconds";
        $unit = "s";
        $opt[$KEY] = '--vertical-label "' . $vlabel . '" --title "' . $this->MACRO['DISP_HOSTNAME'] . ' / Puppet Agent Runtime"';
        $ds_name[$KEY] = "Puppet Agent Runtime";
        $def[$KEY]  = rrd::def     ("var1", $VAL['RRDFILE'], $VAL['DS'], "AVERAGE");
        $def[$KEY] .= rrd::line2("var1", "#000000","runtime");
        $def[$KEY] .= rrd::gprint  ("var1", array("LAST","MAX","AVERAGE"), "%3.0lf $unit");
	}
	#$def[$KEY] .= rrd::comment("Default Template\\r");
	#$def[$KEY] .= rrd::comment("Command " . $VAL['TEMPLATE'] . "\\r");
}
?>

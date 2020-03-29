<?php

$num_graph = 0;

$ds_name[$num_graph] = 'Reads/Writes per Second';
$opt[$num_graph] = " --vertical-label \"read|writes/s\" --slope-mode  --title \"$hostname / $servicedesc\" ";
$def[$num_graph] = "";
$def[$num_graph] .= rrd::def     ("rps", $RRDFILE[1], $DS[1], "AVERAGE");
$def[$num_graph] .= rrd::def     ("wps", $RRDFILE[2], $DS[1], "AVERAGE");
$def[$num_graph] .= rrd::line2    ("rps",  '#32CD32', 'reads/s' );
$def[$num_graph] .= rrd::gprint  ("rps",  array("LAST","MAX","AVERAGE"), "%8.2lf%S");
$def[$num_graph] .= rrd::line2   ("wps", '#0000CD', 'writes/s' ) ;
$def[$num_graph] .= rrd::gprint  ("wps",  array("LAST","MAX","AVERAGE"), "%8.2lf%S");

try {
   require_once('Builds.class.php');
   $releases = Builds::fetchReleaseData($hostname);
   $i=0;
   foreach ($releases as $release) {
      $temptime=$release['time'];
      $tempbname=$release['buildname'];
      $tempcolor=$release['color'];
      if ($i % 2 == 0) {
         $def[$num_graph] .= "VRULE:" . $temptime . "#" . $tempcolor . ":\"" . $tempbname . "\\t\\t\\t\" " ;
      }
      else {
         $def[$num_graph] .= "VRULE:" . $temptime . "#" . $tempcolor . ":\"" . $tempbname . "\\n\" " ;
      }
      $i++;
   }
} catch (Exception $e) {
      echo "Error: " . $e;
}

$num_graph++;

$ds_name[$num_graph] = 'Read/Writes Kb per Second';
$opt[$num_graph] = " --vertical-label \"read|writes Kb/s\" --slope-mode  --title \"$hostname / $servicedesc\" ";
$def[$num_graph] = "";
$def[$num_graph] .= rrd::def     ("rkbps", $RRDFILE[3], $DS[1], "AVERAGE");
$def[$num_graph] .= rrd::def     ("wkbps", $RRDFILE[4], $DS[1], "AVERAGE");
$def[$num_graph] .= rrd::line2    ("rkbps",  '#32CD32', 'read Kb/s' );
$def[$num_graph] .= rrd::gprint  ("rkbps",  array("LAST","MAX","AVERAGE"), "%8.2lf%S");
$def[$num_graph] .= rrd::line2   ("wkbps", '#0000CD', 'write Kb/s' ) ;
$def[$num_graph] .= rrd::gprint  ("wkbps",  array("LAST","MAX","AVERAGE"), "%8.2lf%S");

try {
   require_once('Builds.class.php');
   $releases = Builds::fetchReleaseData($hostname);
   $i=0;
   foreach ($releases as $release) {
      $temptime=$release['time'];
      $tempbname=$release['buildname'];
      $tempcolor=$release['color'];
      if ($i % 2 == 0) {
         $def[$num_graph] .= "VRULE:" . $temptime . "#" . $tempcolor . ":\"" . $tempbname . "\\t\\t\\t\" " ;
      }
      else {
         $def[$num_graph] .= "VRULE:" . $temptime . "#" . $tempcolor . ":\"" . $tempbname . "\\n\" " ;
      }
      $i++;
   }
} catch (Exception $e) {
      echo "Error: " . $e;
}


$num_graph++;

$ds_name[$num_graph] = 'Average Wait';
$opt[$num_graph] = " --vertical-label \"wait (ms)\" --slope-mode --title \"$hostname / $servicedesc\" ";
$def[$num_graph] = "";
$def[$num_graph] .= rrd::def     ("await", $RRDFILE[5], $DS[1], "AVERAGE");
$def[$num_graph] .= rrd::line2    ("await",  '#000000', 'ms' );
$def[$num_graph] .= rrd::gprint  ("await",  array("LAST","MAX","AVERAGE"), "%8.2lf%Sms avg wait");

try {
   require_once('Builds.class.php');
   $releases = Builds::fetchReleaseData($hostname);
   $i=0;
   foreach ($releases as $release) {
      $temptime=$release['time'];
      $tempbname=$release['buildname'];
      $tempcolor=$release['color'];
      if ($i % 2 == 0) {
         $def[$num_graph] .= "VRULE:" . $temptime . "#" . $tempcolor . ":\"" . $tempbname . "\\t\\t\\t\" " ;
      }
      else {
         $def[$num_graph] .= "VRULE:" . $temptime . "#" . $tempcolor . ":\"" . $tempbname . "\\n\" " ;
      }
      $i++;
   }
} catch (Exception $e) {
      echo "Error: " . $e;
}


?>

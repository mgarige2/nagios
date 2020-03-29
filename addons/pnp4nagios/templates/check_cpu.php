<?php

#   This program is free software; you can redistribute it and/or modify
#   it under the terms of the GNU General Public License as published by
#   the Free Software Foundation; either version 2 of the License, or
#   (at your option) any later version.
# 
#   This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License
#   along with this program; if not, write to the Free Software
#   Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA

#   PNP Template for check_cpu.sh
#   Author: Mike Adolphs (http://www.matejunkie.com/

$opt[1] = " --height=250 --vertical-label \"CPU [%]\" --logarithmic --units=si --units-length 5 --title \"CPU Usage for $hostname / $servicedesc\" ";

$def[1] =  "DEF:used=$rrdfile:$DS[1]:AVERAGE " ;
$def[1] .=  "DEF:nice=$rrdfile:$DS[2]:AVERAGE " ;
$def[1] .=  "DEF:sys=$rrdfile:$DS[3]:AVERAGE " ;
$def[1] .=  "DEF:iowait=$rrdfile:$DS[5]:AVERAGE " ;
$def[1] .=  "DEF:irq=$rrdfile:$DS[6]:AVERAGE " ;
$def[1] .=  "DEF:softirq=$rrdfile:$DS[4]:AVERAGE " ;
$def[1] .=  "DEF:idle=$rrdfile:$DS[7]:AVERAGE " ;

$def[1] .= "COMMENT:\"\\t\\t\\tLAST\\t\\t\\tAVERAGE\\t\\t\\tMAX\\n\" " ;

$def[1] .= "AREA:used#E80C3E:\"user\\t\\t\":STACK " ; 
$def[1] .= "GPRINT:used:LAST:\"%6.2lf %%\\t\\t\" " ;
$def[1] .= "GPRINT:used:AVERAGE:\"%6.2lf \\t\\t\" " ;
$def[1] .= "GPRINT:used:MAX:\"%6.2lf \\n\" " ;

$def[1] .= "AREA:nice#E8630C:\"nice\\t\\t\":STACK " ; 
$def[1] .= "GPRINT:nice:LAST:\"%6.2lf %%\\t\\t\" " ;
$def[1] .= "GPRINT:nice:AVERAGE:\"%6.2lf \\t\\t\" " ;
$def[1] .= "GPRINT:nice:MAX:\"%6.2lf \\n\" " ;

$def[1] .= "AREA:sys#008000:\"sys\\t\t\":STACK " ;
$def[1] .= "GPRINT:sys:LAST:\"%6.2lf %%\\t\\t\" " ;
$def[1] .= "GPRINT:sys:AVERAGE:\"%6.2lf \\t\\t\" " ;
$def[1] .= "GPRINT:sys:MAX:\"%6.2lf \\n\" " ;

$def[1] .= "AREA:iowait#0CE84D:\"iowait\\t\":STACK " ;
$def[1] .= "GPRINT:iowait:LAST:\"%6.2lf %%\\t\\t\" " ;
$def[1] .= "GPRINT:iowait:AVERAGE:\"%6.2lf \\t\\t\" " ;
$def[1] .= "GPRINT:iowait:MAX:\"%6.2lf \\n\" " ;

$def[1] .= "AREA:irq#3E00FF:\"irq\\t\t\":STACK " ;
$def[1] .= "GPRINT:irq:LAST:\"%6.2lf %%\\t\\t\" " ;
$def[1] .= "GPRINT:irq:AVERAGE:\"%6.2lf \\t\\t\" " ;
$def[1] .= "GPRINT:irq:MAX:\"%6.2lf \\n\" " ;

$def[1] .= "AREA:softirq#1CC8E8:\"softirq\\t\":STACK " ;
$def[1] .= "GPRINT:softirq:LAST:\"%6.2lf %%\\t\\t\" " ;
$def[1] .= "GPRINT:softirq:AVERAGE:\"%6.2lf \\t\\t\" " ;
$def[1] .= "GPRINT:softirq:MAX:\"%6.2lf \\n\" " ;

$def[1] .= "AREA:idle#FFFF00:\"idle\\t\\t\":STACK " ; 
$def[1] .= "GPRINT:idle:LAST:\"%6.2lf %%\\t\\t\" " ;
$def[1] .= "GPRINT:idle:AVERAGE:\"%6.2lf \\t\\t\" " ;
$def[1] .= "GPRINT:idle:MAX:\"%6.2lf \\n\" " ;

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


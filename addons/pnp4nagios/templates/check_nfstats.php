<?php

$ds_name[1] = "NFS Stats";
$opt[1]  = "--height=300 --vertical-label \"operations\" --title \"NFS Stats on $hostname\" ";

$def[1]  = "DEF:getattr=$RRDFILE[1]:$DS[1]:AVERAGE " ;
$def[1] .= "DEF:setattr=$RRDFILE[1]:$DS[2]:AVERAGE " ;
$def[1] .= "DEF:lookup=$RRDFILE[1]:$DS[3]:AVERAGE ";
$def[1] .= "DEF:access=$RRDFILE[1]:$DS[4]:AVERAGE ";
$def[1] .= "DEF:readlink=$RRDFILE[1]:$DS[5]:AVERAGE ";
$def[1] .= "DEF:read=$RRDFILE[1]:$DS[6]:AVERAGE ";
$def[1] .= "DEF:write=$RRDFILE[1]:$DS[7]:AVERAGE ";
$def[1] .= "DEF:create=$RRDFILE[1]:$DS[8]:AVERAGE ";	
$def[1] .= "DEF:mkdir=$RRDFILE[1]:$DS[9]:AVERAGE ";	
$def[1] .= "DEF:symlink=$RRDFILE[1]:$DS[10]:AVERAGE ";	
$def[1] .= "DEF:mknod=$RRDFILE[1]:$DS[11]:AVERAGE ";
$def[1] .= "DEF:remove=$RRDFILE[1]:$DS[12]:AVERAGE ";
$def[1] .= "DEF:rmdir=$RRDFILE[1]:$DS[13]:AVERAGE ";
$def[1] .= "DEF:rename=$RRDFILE[1]:$DS[14]:AVERAGE ";
$def[1] .= "DEF:link=$RRDFILE[1]:$DS[15]:AVERAGE ";
$def[1] .= "DEF:readdir=$RRDFILE[1]:$DS[16]:AVERAGE ";
$def[1] .= "DEF:readdirplus=$RRDFILE[1]:$DS[17]:AVERAGE ";
$def[1] .= "DEF:fsstat=$RRDFILE[1]:$DS[18]:AVERAGE ";
$def[1] .= "DEF:fsinfo=$RRDFILE[1]:$DS[19]:AVERAGE ";
$def[1] .= "DEF:pathconf=$RRDFILE[1]:$DS[20]:AVERAGE ";
$def[1] .= "DEF:commit=$RRDFILE[1]:$DS[21]:AVERAGE ";


$def[1] .= "AREA:getattr#DDA0DD:\"Getattr Ops\: \g\" " ;
$def[1] .= "GPRINT:getattr:LAST:\"%6.1lf last\" " ;
$def[1] .= "GPRINT:getattr:AVERAGE:\"%6.1lf avg\" " ;
$def[1] .= "GPRINT:getattr:MAX:\"%6.1lf max\\n\" " ;

$def[1] .= "AREA:setattr#FF8C00:\"Setattr Ops\: \g\":STACK " ;
$def[1] .= "GPRINT:setattr:LAST:\"%6.1lf last\" " ;
$def[1] .= "GPRINT:setattr:AVERAGE:\"%6.1lf avg\" " ;
$def[1] .= "GPRINT:setattr:MAX:\"%6.1lf max\\n\" " ;

$def[1] .= "AREA:lookup#8B4513:\"Lookup Ops\: \g\":STACK " ;
$def[1] .= "GPRINT:lookup:LAST:\"%6.1lf last\" " ;
$def[1] .= "GPRINT:lookup:AVERAGE:\"%6.1lf avg\" " ;
$def[1] .= "GPRINT:lookup:MAX:\"%6.1lf max\\n\" " ;

$def[1] .= "AREA:access#FF1493:\"Access Ops\: \g\":STACK " ;
$def[1] .= "GPRINT:access:LAST:\"%6.1lf last\" " ;
$def[1] .= "GPRINT:access:AVERAGE:\"%6.1lf avg\" " ;
$def[1] .= "GPRINT:access:MAX:\"%6.1lf max\\n\" " ;

$def[1] .= "AREA:readlink#1E90FF:\"Readlink Ops\: \g\":STACK " ;
$def[1] .= "GPRINT:readlink:LAST:\"%6.1lf last\" " ;
$def[1] .= "GPRINT:readlink:AVERAGE:\"%6.1lf avg\" " ;
$def[1] .= "GPRINT:readlink:MAX:\"%6.1lf max\\n\" " ;

$def[1] .= "AREA:read#00FFFF:\"Read Ops\: \g\":STACK " ;
$def[1] .= "GPRINT:read:LAST:\"%6.1lf last\" " ;
$def[1] .= "GPRINT:read:AVERAGE:\"%6.1lf avg\" " ;
$def[1] .= "GPRINT:read:MAX:\"%6.1lf max\\n\" " ;

$def[1] .= "AREA:write#00FFFF:\"Write Ops\: \g\":STACK " ;
$def[1] .= "GPRINT:write:LAST:\"%6.1lf last\" " ;
$def[1] .= "GPRINT:write:AVERAGE:\"%6.1lf avg\" " ;
$def[1] .= "GPRINT:write:MAX:\"%6.1lf max\\n\" " ;

$def[1] .= "AREA:create#7FFF00:\"Create Ops\: \g\":STACK " ;
$def[1] .= "GPRINT:create:LAST:\"%6.1lf last\" " ;
$def[1] .= "GPRINT:create:AVERAGE:\"%6.1lf avg\" " ;
$def[1] .= "GPRINT:create:MAX:\"%6.1lf max\\n\" " ;

$def[1] .= "AREA:mkdir#32CD32:\"Mkdir Ops\: \g\":STACK " ;
$def[1] .= "GPRINT:mkdir:LAST:\"%6.1lf last\" " ;
$def[1] .= "GPRINT:mkdir:AVERAGE:\"%6.1lf avg\" " ;
$def[1] .= "GPRINT:mkdir:MAX:\"%6.1lf max\\n\" " ;

$def[1] .= "AREA:symlink#98FB98:\"Symlink Ops\: \g\":STACK " ;
$def[1] .= "GPRINT:symlink:LAST:\"%6.1lf last\" " ;
$def[1] .= "GPRINT:symlink:AVERAGE:\"%6.1lf avg\" " ;
$def[1] .= "GPRINT:symlink:MAX:\"%6.1lf max\\n\" " ;

$def[1] .= "AREA:mknod#F0E68C:\"Mknod Ops\: \g\":STACK " ;
$def[1] .= "GPRINT:mknod:LAST:\"%6.1lf last\" " ;
$def[1] .= "GPRINT:mknod:AVERAGE:\"%6.1lf avg\" " ;
$def[1] .= "GPRINT:mknod:MAX:\"%6.1lf max\\n\" " ;

$def[1] .= "AREA:remove#5C005C:\"Remove Ops\: \g\":STACK " ;
$def[1] .= "GPRINT:remove:LAST:\"%6.1lf last\" " ;
$def[1] .= "GPRINT:remove:AVERAGE:\"%6.1lf avg\" " ;
$def[1] .= "GPRINT:remove:MAX:\"%6.1lf max\\n\" " ;

$def[1] .= "AREA:rmdir#003300:\"Rmdir Ops\: \g\":STACK " ;
$def[1] .= "GPRINT:rmdir:LAST:\"%6.1lf last\" " ;
$def[1] .= "GPRINT:rmdir:AVERAGE:\"%6.1lf avg\" " ;
$def[1] .= "GPRINT:rmdir:MAX:\"%6.1lf max\\n\" " ;

$def[1] .= "AREA:rename#FFCC00:\"Rename Ops\: \g\":STACK " ;
$def[1] .= "GPRINT:rename:LAST:\"%6.1lf last\" " ;
$def[1] .= "GPRINT:rename:AVERAGE:\"%6.1lf avg\" " ;
$def[1] .= "GPRINT:rename:MAX:\"%6.1lf max\\n\" " ;

$def[1] .= "AREA:link#CCCCFF:\"Link Ops\: \g\":STACK " ;
$def[1] .= "GPRINT:link:LAST:\"%6.1lf last\" " ;
$def[1] .= "GPRINT:link:AVERAGE:\"%6.1lf avg\" " ;
$def[1] .= "GPRINT:link:MAX:\"%6.1lf max\\n\" " ;

$def[1] .= "AREA:readdir#FF0000:\"Readdir Ops\: \g\":STACK " ;
$def[1] .= "GPRINT:readdir:LAST:\"%6.1lf last\" " ;
$def[1] .= "GPRINT:readdir:AVERAGE:\"%6.1lf avg\" " ;
$def[1] .= "GPRINT:readdir:MAX:\"%6.1lf max\\n\" " ;

$def[1] .= "AREA:readdirplus#999966:\"Readdirplus Ops\: \g\":STACK " ;
$def[1] .= "GPRINT:readdirplus:LAST:\"%6.1lf last\" " ;
$def[1] .= "GPRINT:readdirplus:AVERAGE:\"%6.1lf avg\" " ;
$def[1] .= "GPRINT:readdirplus:MAX:\"%6.1lf max\\n\" " ;

$def[1] .= "AREA:fsstat#0000CC:\"Fsstat Ops\: \g\":STACK " ;
$def[1] .= "GPRINT:fsstat:LAST:\"%6.1lf last\" " ;
$def[1] .= "GPRINT:fsstat:AVERAGE:\"%6.1lf avg\" " ;
$def[1] .= "GPRINT:fsstat:MAX:\"%6.1lf max\\n\" "

?>


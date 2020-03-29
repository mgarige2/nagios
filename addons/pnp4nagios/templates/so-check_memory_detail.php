<?php

$ds_name[1] = "Memory Stats";
$opt[1]  = " --height=250 --vertical-label \"Memory (MB)\" -b 1024 --title \"Memory Stats on $hostname\" ";

$def[1]  = "DEF:tot_swap=$RRDFILE[1]:$DS[1]:AVERAGE ";
$def[1] .= "CDEF:total_swap=tot_swap,1024,/ ";
$def[1] .= "DEF:avl_swap=$RRDFILE[1]:$DS[2]:AVERAGE ";
$def[1] .= "CDEF:avail_swap=avl_swap,1024,/ ";
$def[1] .= "DEF:tot_real=$RRDFILE[1]:$DS[3]:AVERAGE ";
$def[1] .= "CDEF:total_real=tot_real,1024,/ ";
$def[1] .= "DEF:avl_real=$RRDFILE[1]:$DS[4]:AVERAGE ";
$def[1] .= "CDEF:avail_real=avl_real,1024,/ ";
$def[1] .= "DEF:minswap=$RRDFILE[1]:$DS[6]:AVERAGE ";
$def[1] .= "CDEF:min_swap=minswap,1024,/ ";
$def[1] .= "DEF:buff=$RRDFILE[1]:$DS[8]:AVERAGE ";
$def[1] .= "CDEF:buffer=buff,1024,/ ";
$def[1] .= "DEF:cach=$RRDFILE[1]:$DS[9]:AVERAGE ";
$def[1] .= "CDEF:cached=cach,1024,/ ";
$def[1] .= "CDEF:perc_avail_real=avail_real,total_real,/,100,* ";
$def[1] .= "CDEF:perc_avail_swap=avail_swap,total_swap,/,100,* ";
$def[1] .= "CDEF:perc_buffer_real=buffer,total_real,/,100,* ";
$def[1] .= "CDEF:user=total_real,avail_real,-,total_swap,+,avail_swap,-,buffer,-,cached,- ";
$def[1] .= "CDEF:perc_user_real=user,total_real,/,100,* ";
$def[1] .= "CDEF:perc_used_real=total_real,avail_real,-,total_real,/,100,* ";
$def[1] .= "CDEF:used_swap=total_swap,avail_swap,- ";
$def[1] .= "CDEF:total=total_real,total_swap,+ ";
$def[1] .= "CDEF:perc_cached_real=cached,total_real,/,100,* ";
$def[1] .= "CDEF:perc_used_swap=total_swap,avail_swap,-,total_swap,/,100,* ";

$def[1] .= "AREA:user#FFF200:\"Used\:\t\g\" " ;
$def[1] .= "GPRINT:user:LAST:\"%6.1lfMB \g\" " ;
$def[1] .= "GPRINT:perc_user_real:LAST:\"(%2.1lf%% of RAM)\" " ;
$def[1] .= "GPRINT:user:MAX:\"Max\: %6.1lfMB \g\" " ;
$def[1] .= "GPRINT:perc_user_real:MAX:\"(%2.1lf%%)\" " ;
$def[1] .= "GPRINT:user:AVERAGE:\"Average\: %6.1lfMB \g\" " ;
$def[1] .= "GPRINT:perc_user_real:AVERAGE:\"(%2.1lf%%)\\n\" " ;

$def[1] .= "AREA:buffer#6EA100:\"Buffers\:\t\g\":STACK " ;
$def[1] .= "GPRINT:buffer:LAST:\"%6.1lfMB \g\" " ;
$def[1] .= "GPRINT:perc_buffer_real:LAST:\"(%2.1lf%% of RAM)\" " ;
$def[1] .= "GPRINT:buffer:MAX:\"Max\: %6.1lfMB \g\" " ;
$def[1] .= "GPRINT:perc_buffer_real:MAX:\"(%2.1lf%%)\" " ;
$def[1] .= "GPRINT:buffer:AVERAGE:\"Average\: %6.1lfMB \g\" " ;
$def[1] .= "GPRINT:perc_buffer_real:AVERAGE:\"(%2.1lf%%)\\n\" " ;

$def[1] .= "AREA:cached#00CF00:\"Cached\:\t\g\":STACK " ;
$def[1] .= "GPRINT:cached:LAST:\"%6.1lfMB \g\" " ;
$def[1] .= "GPRINT:perc_cached_real:LAST:\"(%2.1lf%% of RAM)\" " ;
$def[1] .= "GPRINT:cached:MAX:\"Max\: %6.1lfMB \g\" " ;
$def[1] .= "GPRINT:perc_cached_real:MAX:\"(%2.1lf%%)\" " ;
$def[1] .= "GPRINT:cached:AVERAGE:\"Average\: %6.1lfMB \g\" " ;
$def[1] .= "GPRINT:perc_cached_real:AVERAGE:\"(%2.1lf%%)\\n\" " ;

$def[1] .= "AREA:avail_real#00FF00:\"Free\:\t\g\":STACK " ;
$def[1] .= "GPRINT:avail_real:LAST:\"%6.1lfMB \g\" " ;
$def[1] .= "GPRINT:perc_avail_real:LAST:\"(%2.1lf%% of RAM)\" " ;
$def[1] .= "GPRINT:avail_real:MAX:\"Max\: %6.1lfMB \g\" " ;
$def[1] .= "GPRINT:perc_avail_real:MAX:\"(%2.1lf%%)\" " ;
$def[1] .= "GPRINT:avail_real:AVERAGE:\"Average\: %6.1lfMB \g\" " ;
$def[1] .= "GPRINT:perc_avail_real:AVERAGE:\"(%2.1lf%%)\\n\" " ;

$def[1] .= "CDEF:linewidth4=total_real,total_real,-,4,+ ";
$def[1] .= "AREA:linewidth4#000000:\"Total RAM\: \":STACK ";
$def[1] .= "GPRINT:total_real:LAST:\"%6.1lf MB \\n\" ";

$def[1] .= "AREA:used_swap#FF8C00:\"Swap Used\: \g\":STACK " ;
$def[1] .= "GPRINT:used_swap:LAST:\"%6.1lfMB \g\" " ;
$def[1] .= "GPRINT:perc_used_swap:LAST:\"(%2.1lf%% of RAM)\" " ;
$def[1] .= "GPRINT:used_swap:MAX:\"Max\: %6.1lfMB \g\" " ;
$def[1] .= "GPRINT:perc_used_swap:MAX:\"(%2.1lf%%)\" " ;
$def[1] .= "GPRINT:used_swap:AVERAGE:\"Average\: %6.1lf MB \g\" " ;
$def[1] .= "GPRINT:perc_used_swap:AVERAGE:\"(%2.1lf%%)\\n\" " ;

$def[1] .= "CDEF:swap_plus_real=total_swap,total_real,+ ";
$def[1] .= "LINE1:swap_plus_real#FF0000:\"Swap Total\: \" ";
$def[1] .= "GPRINT:total_swap:LAST:\"%6.1lf MB \" ";
$def[1] .= "LINE2:total_real#000000 ";

?>


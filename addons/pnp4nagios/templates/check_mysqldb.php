<?php
# ================================ SUMMARY ====================================
#
# File    : check_mysqld.php
# Version : 0.3
# Date    : Mar 10, 2012
# Author  : William Leibzon - william@leibzon.org
# Summary : PNP4Nagios template for mysql database check done with check_mysqld.pl
# Licence : GPL - summary below, full text at http://www.fsf.org/licenses/gpl.txt
#
# This is considered a supplemental file to check_mysqld.pl plugin and though
# not distributed in unified package it is distributed under same licencing
# terms (GNU 2.0 license). Any redisribution of this file in modified form must
# reproduce this summary (modified if appropriate) and must either include
# entire GNU license in a package or list URL where it can be found if
# distributed as single file.
#
# ===================== INFORMATION ABOUT THIS TEMPLATE =======================
#
# This is a pnp4nagios template for mysql database check done with check_mysqld.pl
#
# The template tries to graph number of MYSQL variables returned with "SHOW STATUS"
# (for mysql 5.x - "SHOW GLOBAL STATUS") which are described at:
# http://dev.mysql.com/doc/refman/4.1/en/server-status-variables.html
#
# The template was originally created for ngrapher and is in process being ported
# to pnp4nagios. Below metrics are available with check_mysqld.ncfg template,
# while not all may not be available with this version, these would eventually
# all be available with PNP4Nagios too:
#
# 1. Queries (rate of queries being processed)
#  This is shows how many DELETE, INSERT, UPDATE and SELECT queries are processed.
#  For select it also tries to show how many queries are being answered with data
#  from cache and for those that are causing db read it shows if query causes
#  cache to be updated or not. This mysql documentation page explains a little
#  about qcache variables and totals for SELECT queries:
#    http://dev.mysql.com/doc/refman/4.1/en/query-cache-status-and-maintenance.html
# 2. Data Traffic (in MB/sec)
#  No explantion needed - just your typical network traffic graph.
# 3. Connections and Threads
#  Current number of connections to the server, maximum number of connections
#  and number threads in use.
# 4. Tables and Files
#  Number of open files, open tables. Number of temp files & tables created.
#  Also Number of table locks per second.
# 5. Errors and Issues
#  Various parameters (far from all possible to be retrieved) that indicate a problem -
#  all should be 0 or close to it. Rate of slow queries are one of the probably most
#  well known and tracked of the variables graphed.
# 6. Key Cache Efficiency
#  This is based on key_ variables and supposed to indicate percent of key requests
#  queries that are answered from memory. For more info see comment under 'key_reads'
#  variable from mysql documentation page on how to calculate "cache miss rate".
#  Efficiency percent I show is just 100%-cache_miss%.
# 7. Key Cache Data
#  Raw data used in calculating efficiency. This is graphed separately to track total
#  number of requests.
# 8. Handler Row Requests
#  This tracks requests for next row, previous row and associated update/delete/insert
#  row requests that you do when keeping open handle. This is probably very interesting data,
#  but I do not entirely understand it and I also have a feeling numbers shown are too high
# 9. Query Cache Memory
#  This will show used and free blocks and total number of queries in cache.
# 10. Query Cache Hits
#  Number of hits and update of query cache. Most of these numbers are already shown as part
# 11. Binlog Cache Transactions
#  Graphed are binlog_cache_use and binlog_cache_disk_use variables. 
#
# ============================= SETUP NOTES ====================================
# 
# 1. Copy this template pnp4nagios's templates directory
# 2. Make sure you specify all attributes as below listed under
#    '$USER21$' as a '-A' parameter to check_mysqld.pl plugin
# 3. Make sure you have copy of nagios that accepts without being
#    cut performance data of up to 1500 bytes (best 2k) in size
#    ('threads_running=??' should be the last performance variable seen
#    under 'Performance Data:" in nagios 'Service State Information')
#
# For reference the following is how I defined mysql check in nagios commands config:
#   define command{
#        command_name    check_mysql
#        command_line    $USER1$/check_mysqld.pl -H $HOSTADDRESS$ -u nagios -p $USER7$ -a uptime,threads_connected,questions,slow_queries,open_tables -w ',,,,' -c ',,,,' -A $USER21$
#        }
# This service definition is just:
#   define  service{
#        use                             db-service
#        servicegroups                   dbservices
#        hostgroup_name                  mysql
#        service_description             MySQL
#        check_command                   check_mysql
#        }
# And most important (for the graphing) my resource.cfg has the following:
#   # Mysql 'nagios' user password
#   $USER7$=public_example
#
#   # List of variables to be retrieved for mysqld (here mostly for convinience so as not to put in commmands.cfg)
#   $USER21$='com_commit,com_rollback,com_delete,com_update,com_insert,com_insert_select,com_select,qcache_hits,qcache_inserts,qcache_not_cached,questions,bytes_sent,bytes_received,aborted_clients,aborted_connects,binlog_cache_disk_use,binlog_cache_use,connections,created_tmp_disk_tables,created_tmp_files,created_tmp_tables,delayed_errors,delayed_insert_threads,delayed_writes,handler_update,handler_write,handler_delete,handler_read_first,handler_read_key,handler_read_next,handler_read_prev,handler_read_rnd,handler_read_rnd_next,key_blocks_not_flushed,key_blocks_unused,key_blocks_used,key_read_requests,key_reads,key_write_requests,key_writes,max_used_connections,not_flushed_delayed_rows,open_files,open_streams,open_tables,opened_tables,prepared_stmt_count,qcache_free_blocks,qcache_free_memory,qcache_lowmem_prunes,qcache_queries_in_cache,qcache_total_blocks,select_full_join,select_rangle_check,slow_launch_threads,slow_queries,table_locks_immediate,table_locks_waited,threads_cached,threads_connected,threads_created,threads_running'
#
# -----------------------------------------------------------------------------
# 
# You will need nagios with larger buffers (as compared to usual 2.x distrubutions)
# for storing performance variables in order to fully utilize this template. 
# Doing so requires recompile after modifying MAX_INPUT_BUFFER, MAX_COMMAND_BUFFER,
# MAX_PLUGINOUTPUT_LENGTH which are defined in objects.h and common.h.
# Patches for some versions of nagios is available at
#   http://william.leibzon.org/nagios/
#
# ========================= VERSION HISTORY and TODO ==========================
#
# v0.2  - 01/02/2008 : This is initial public release of nagiosgrapher template
# v0.21 - 01/03/2008 : Fixed bug in calculation of total number of queries
# v0.22 - 12/19/2011 : Changed so that first STACK is an AREA.
# v0.3  - 03/10/2012 : The first version of template for PNP4Nagios
# v0.31 - 03/20/2012 : Updated network traffic to be Mb/sec
# 
# TODO: a. Testing under newest 5.x and 6.0 alpha versions of mysql
#       b. Better documentation of what graphed data means.
#       c. Information from mysql developers about 'handler' data 
#          and confirmation that it is being displayed properly
#
# =============================== END OF HEADER ===============================

$ds_name[1] = "SQL Queries";
$opt[1]  = "--height=250 --vertical-label \"commands/sec\" -b 1000 --title \"SQL Queries on $hostname\" ";

$def[1]  = "DEF:com_commit=$RRDFILE[1]:$DS[6]:AVERAGE " ;
$def[1] .= "DEF:com_rollback=$RRDFILE[1]:$DS[7]:AVERAGE " ;
$def[1] .= "DEF:com_delete=$RRDFILE[1]:$DS[8]:AVERAGE ";
$def[1] .= "DEF:com_update=$RRDFILE[1]:$DS[9]:AVERAGE ";
$def[1] .= "DEF:com_insert=$RRDFILE[1]:$DS[10]:AVERAGE ";
$def[1] .= "DEF:com_insert_select=$RRDFILE[1]:$DS[11]:AVERAGE ";
$def[1] .= "DEF:com_select=$RRDFILE[1]:$DS[12]:AVERAGE ";
$def[1] .= "DEF:qc_hits=$RRDFILE[1]:$DS[13]:AVERAGE ";		# qcache_hits
$def[1] .= "DEF:qc_inserts=$RRDFILE[1]:$DS[14]:AVERAGE ";	# qcache_inserts
$def[1] .= "DEF:qc_not_cached=$RRDFILE[1]:$DS[15]:AVERAGE ";	# qcache_not_cached
$def[1] .= "DEF:questions=$RRDFILE[1]:$DS[3]:AVERAGE ";


$def[1] .= "AREA:com_commit#DDA0DD:\"Commit Commands\: \t\t\g\" " ;
$def[1] .= "GPRINT:com_commit:LAST:\"%6.1lf last\" " ;
$def[1] .= "GPRINT:com_commit:AVERAGE:\"%6.1lf avg\" " ;
$def[1] .= "GPRINT:com_commit:MAX:\"%6.1lf max\\n\" " ;

$def[1] .= "AREA:com_rollback#FF8C00:\"Rollback Commands\: \t\t\g\":STACK " ;
$def[1] .= "GPRINT:com_rollback:LAST:\"%6.1lf last\" " ;
$def[1] .= "GPRINT:com_rollback:AVERAGE:\"%6.1lf avg\" " ;
$def[1] .= "GPRINT:com_rollback:MAX:\"%6.1lf max\\n\" " ;

$def[1] .= "AREA:com_delete#8B4513:\"Delete Commands\: \t\t\g\":STACK " ;
$def[1] .= "GPRINT:com_delete:LAST:\"%6.1lf last\" " ;
$def[1] .= "GPRINT:com_delete:AVERAGE:\"%6.1lf avg\" " ;
$def[1] .= "GPRINT:com_delete:MAX:\"%6.1lf max\\n\" " ;

$def[1] .= "AREA:com_update#FF1493:\"Update Commands\: \t\t\g\":STACK " ;
$def[1] .= "GPRINT:com_update:LAST:\"%6.1lf last\" " ;
$def[1] .= "GPRINT:com_update:AVERAGE:\"%6.1lf avg\" " ;
$def[1] .= "GPRINT:com_update:MAX:\"%6.1lf max\\n\" " ;

$def[1] .= "AREA:com_insert#1E90FF:\"Insert Commands\: \t\t\g\":STACK " ;
$def[1] .= "GPRINT:com_insert:LAST:\"%6.1lf last\" " ;
$def[1] .= "GPRINT:com_insert:AVERAGE:\"%6.1lf avg\" " ;
$def[1] .= "GPRINT:com_insert:MAX:\"%6.1lf max\\n\" " ;

$def[1] .= "AREA:com_insert_select#00FFFF:\"Insert_Select Commands\: \t\g\":STACK " ;
$def[1] .= "GPRINT:com_insert_select:LAST:\"%6.1lf last\" " ;
$def[1] .= "GPRINT:com_insert_select:AVERAGE:\"%6.1lf avg\" " ;
$def[1] .= "GPRINT:com_insert_select:MAX:\"%6.1lf max\\n\" " ;
$def[1] .= "COMMENT:\"\s\" ";

$def[1] .= "CDEF:select_graph=com_select,qc_inserts,-,qc_not_cached,- ";
$def[1] .= "AREA:select_graph#7FFF00:\"Select - from DB\: \t\t\g\":STACK " ;
$def[1] .= "GPRINT:com_select:LAST:\"%6.1lf last\" " ;
$def[1] .= "GPRINT:com_select:AVERAGE:\"%6.1lf avg\" " ;
$def[1] .= "GPRINT:com_select:MAX:\"%6.1lf max\\n\" " ;

$def[1] .= "AREA:qc_not_cached#32CD32:\"- of that not cached\: \t\g\":STACK " ;
$def[1] .= "GPRINT:qc_not_cached:LAST:\"%6.1lf last\" " ;
$def[1] .= "GPRINT:qc_not_cached:AVERAGE:\"%6.1lf avg\" " ;
$def[1] .= "GPRINT:qc_not_cached:MAX:\"%6.1lf max\\n\" " ;

$def[1] .= "AREA:qc_inserts#98FB98:\"- of that added to cache\: \t\g\":STACK " ;
$def[1] .= "GPRINT:qc_inserts:LAST:\"%6.1lf last\" " ;
$def[1] .= "GPRINT:qc_inserts:AVERAGE:\"%6.1lf avg\" " ;
$def[1] .= "GPRINT:qc_inserts:MAX:\"%6.1lf max\\n\" " ;

$def[1] .= "AREA:qc_hits#F0E68C:\"Select - from Cache\: \t\g\":STACK " ;
$def[1] .= "GPRINT:qc_hits:LAST:\"%6.1lf last\" " ;
$def[1] .= "GPRINT:qc_hits:AVERAGE:\"%6.1lf avg\" " ;
$def[1] .= "GPRINT:qc_hits:MAX:\"%6.1lf max\\n\" " ;

$def[1] .= "CDEF:com_select_total=com_select,qc_hits,+ ";
$def[1] .= "GPRINT:com_select_total:LAST:\"= Total Select Queries\: \t%6.1lf last\" " ;
$def[1] .= "GPRINT:com_select_total:AVERAGE:\"%6.1lf avg\" " ;
$def[1] .= "GPRINT:com_select_total:MAX:\"%6.1lf max\\n\" " ;
$def[1] .= "COMMENT:\"\s\" ";

$def[1] .= "CDEF:queries_nocache=questions,qc_hits,- ";
$def[1] .= "LINE1:queries_nocache#696969:\"All DB Queries (except cache hits)\: \t\g\" " ;
$def[1] .= "GPRINT:queries_nocache:LAST:\"%6.1lf last\" " ;
$def[1] .= "GPRINT:queries_nocache:AVERAGE:\"%6.1lf avg\" " ;
$def[1] .= "GPRINT:queries_nocache:MAX:\"%6.1lf max\\n\" " ;

$def[1] .= "LINE1:questions#000000:\"All Questions (counting cache hits)\: \t\g\" " ;
$def[1] .= "GPRINT:questions:LAST:\"%6.1lf last\" " ;
$def[1] .= "GPRINT:questions:AVERAGE:\"%6.1lf avg\" " ;
$def[1] .= "GPRINT:questions:MAX:\"%6.1lf max\\n\" " ;

$ds_name[2] = "Data Traffic";
$opt[2]  = " --vertical-label \"bits/sec\" -b 1000 --title \"DB Net Traffic on $hostname\" ";

$def[2]  = "DEF:bytes_sent=$RRDFILE[1]:$DS[16]:AVERAGE ";
$def[2] .= "DEF:bytes_received=$RRDFILE[1]:$DS[17]:AVERAGE ";

$def[2] .= "CDEF:out_bits=bytes_sent,8,* ";
$def[2] .= "AREA:out_bits#00ff00:\"out \" " ;
$def[2] .= "GPRINT:out_bits:LAST:\"%7.2lf %Sbit/s last\" " ;
$def[2] .= "GPRINT:out_bits:AVERAGE:\"%7.2lf %Sbit/s avg\" " ;
$def[2] .= "GPRINT:out_bits:MAX:\"%7.2lf %Sbit/s max\\n\" ";

$def[2] .= "CDEF:in_bits=bytes_received,8,* ";
$def[2] .= "LINE1:in_bits#0000ff:\"in  \" " ;
$def[2] .= "GPRINT:in_bits:LAST:\"%7.2lf %Sbit/s last\" " ;
$def[2] .= "GPRINT:in_bits:AVERAGE:\"%7.2lf %Sbit/s avg\" " ;
$def[2] .= "GPRINT:in_bits:MAX:\"%7.2lf %Sbit/s max\\n\" " ;

$orange    = '#FF9933';
$blue      = '#3E9ADE';
$red       = '#FF3300';
$darkred   = '#990000';
$paleblue  = '#80B4C1';
$yellow    = '#FFCC00';

$num = 3;

$ds_name[$num] = 'Database Activity';
$opt[$num] = "--title  \"$hostname - Database Activity\" --vertical-label \"avg statements/sec\" --units-exponent 0 --lower-limit 0";
$def[$num] = rrd::def('sel', $RRDFILE[1], $DS[12], 'AVERAGE');
$def[$num] .= rrd::def('ins', $RRDFILE[1], $DS[10], 'AVERAGE');
$def[$num] .= rrd::def('upd', $RRDFILE[1], $DS[9], 'AVERAGE');
$def[$num] .= rrd::def('rep', $RRDFILE[1], $DS[64], 'AVERAGE');
$def[$num] .= rrd::def('del', $RRDFILE[1], $DS[8], 'AVERAGE');
$def[$num] .= rrd::def('cal', $RRDFILE[1], $DS[63], 'AVERAGE');
$def[$num] .= rrd::line1('sel',"$orange", rrd::cut('Select', 8));
$def[$num] .= rrd::gprint('sel', 'LAST', '%5.0lf');
$def[$num] .= rrd::line1('ins',"$blue", rrd::cut('Insert', 8));
$def[$num] .= rrd::gprint('ins', 'LAST', '%5.0lf');
$def[$num] .= rrd::line1('upd',"$red", rrd::cut('Update', 8));
$def[$num] .= rrd::gprint('upd', 'LAST', '%5.0lf\l');
$def[$num] .= rrd::line1('cal',"$yellow", rrd::cut('Call', 8));
$def[$num] .= rrd::gprint('cal', 'LAST', '%5.0lf');
$def[$num] .= rrd::line1('del',"$darkred", rrd::cut('Delete', 8));
$def[$num] .= rrd::gprint('del', 'LAST', '%5.0lf');
$def[$num] .= rrd::line1('rep',"$paleblue", rrd::cut('Replace', 8));
$def[$num] .= rrd::gprint('rep', 'LAST', '%5.0lf\l');

++$num;

$ds_name[$num] = 'Connections';
$opt[$num] = "--title \"$hostname - Connections\"";
#$def[$num] = rrd::def('max_connections', $RRDFILE[1], $DS[65], 'AVERAGE');
$def[$num] = rrd::def('max_used', $RRDFILE[1], $DS[45], 'MAX');
$def[$num] .= rrd::def('aborted_clients', $RRDFILE[1], $DS[18], 'AVERAGE');
$def[$num] .= rrd::def('aborted_connects', $RRDFILE[1], $DS[19], 'AVERAGE');
$def[$num] .= rrd::def('threads_connected', $RRDFILE[1], $DS[2], 'AVERAGE');
$def[$num] .= rrd::def('new_connections', $RRDFILE[1], $DS[22], 'AVERAGE');
#$label = rrd::cut('Connections',23);
#$def[$num] .= rrd::area('max_connections','#C0C0C0',$label,0);
#$def[$num] .= rrd::gprint('max_connections','AVERAGE',"%4.0lf \\n");
$label = rrd::cut('Max Used',23);
$def[$num] .= rrd::area('max_used','#FFD660',$label,0);
$def[$num] .= rrd::gprint('max_used','AVERAGE',"%4.0lf \\n");
$label = rrd::cut('Aborted Clients',23);
$def[$num] .= rrd::line1('aborted_clients','#FF3932',$label,0);
$def[$num] .= rrd::gprint('aborted_clients',array('LAST','AVERAGE','MAX'),"%4.0lf");
$label = rrd::cut('Aborted Connects',23);
$def[$num] .= rrd::line1('aborted_connects','#00FF00',$label,0);
$def[$num] .= rrd::gprint('aborted_connects',array('LAST','AVERAGE','MAX'),"%4.0lf");
$label = rrd::cut('Threads Connected',23);
$def[$num] .= rrd::line1('threads_connected','#FF7D00',$label,0);
$def[$num] .= rrd::gprint('threads_connected',array('LAST','AVERAGE','MAX'),"%4.0lf");
$label = rrd::cut('New Connections',23);
$def[$num] .= rrd::line1('new_connections','#4444ff',$label,0);
$def[$num] .= rrd::gprint('new_connections',array('LAST','AVERAGE','MAX'),"%4.0lf");

++$num;

$ds_name[$num] = 'Slow Queries';
$opt[$num] = "--title \"$hostname - Slow Queries\"";
$def[$num] = rrd::def('slow_queries', $RRDFILE[1], $DS[4], 'AVERAGE');
$label = rrd::cut('Slow Queries',25);
$def[$num] .= rrd::line1('slow_queries','#4444FF',$label,0);
$def[$num] .= rrd::gprint('slow_queries',array('LAST','AVERAGE','MAX'),"%5.0lf");

++$num;

$ds_name[$num] = 'Command Counters';
$opt[$num] = "--title \"$hostname - Command Counters\"";
$def[$num] = rrd::def('questions', $RRDFILE[1], $DS[3], 'AVERAGE');
$def[$num] .= rrd::def('select', $RRDFILE[1], $DS[12], 'AVERAGE');
$def[$num] .= rrd::def('delete', $RRDFILE[1], $DS[8], 'AVERAGE');
$def[$num] .= rrd::def('insert', $RRDFILE[1], $DS[10], 'AVERAGE');
$def[$num] .= rrd::def('update', $RRDFILE[1], $DS[9], 'AVERAGE');
$def[$num] .= rrd::def('replace', $RRDFILE[1], $DS[64], 'AVERAGE');
$def[$num] .= rrd::def('load', $RRDFILE[1], $DS[65], 'AVERAGE');
$def[$num] .= rrd::def('delete_multi', $RRDFILE[1], $DS[66], 'AVERAGE');
$def[$num] .= rrd::def('insert_select', $RRDFILE[1], $DS[11], 'AVERAGE');
$def[$num] .= rrd::def('update_multi', $RRDFILE[1], $DS[67], 'AVERAGE');
$def[$num] .= rrd::def('replace_select', $RRDFILE[1], $DS[68], 'AVERAGE');
$def[$num] .= rrd::area('questions','#FFC3C0',rrd::cut('Questions'),23);
$def[$num] .= rrd::gprint('questions',array('LAST','AVERAGE','MAX'),"%4.0lf");
$def[$num] .= rrd::area('select','#FF0000',rrd::cut('Select'),23,1);
$def[$num] .= rrd::gprint('select',array('LAST','AVERAGE','MAX'),"%4.0lf");
$def[$num] .= rrd::area('delete','#FF7D00',rrd::cut('Delete'),23,1);
$def[$num] .= rrd::gprint('delete',array('LAST','AVERAGE','MAX'),"%4.0lf");
$def[$num] .= rrd::area('insert','#FFF200',rrd::cut('Insert'),23,1);
$def[$num] .= rrd::gprint('insert',array('LAST','AVERAGE','MAX'),"%4.0lf");
$def[$num] .= rrd::area('update','#00CF00',rrd::cut('Update'),23,1);
$def[$num] .= rrd::gprint('update',array('LAST','AVERAGE','MAX'),"%4.0lf");
$def[$num] .= rrd::area('replace','#2175D9',rrd::cut('Replace'),23,1);
$def[$num] .= rrd::gprint('replace',array('LAST','AVERAGE','MAX'),"%4.0lf");
$def[$num] .= rrd::area('load','#55009D',rrd::cut('Load'),23,1);
$def[$num] .= rrd::gprint('load',array('LAST','AVERAGE','MAX'),"%4.0lf");
$def[$num] .= rrd::area('delete_multi','#942D0C',rrd::cut('Delete Multi'),23,1);
$def[$num] .= rrd::gprint('delete_multi',array('LAST','AVERAGE','MAX'),"%4.0lf");
$def[$num] .= rrd::area('insert_select','#AAABA1',rrd::cut('Insert Select'),23,1);
$def[$num] .= rrd::gprint('insert_select',array('LAST','AVERAGE','MAX'),"%4.0lf");
$def[$num] .= rrd::area('update_multi','#D8ACE0',rrd::cut('Update Multi'),23,1);
$def[$num] .= rrd::gprint('update_multi',array('LAST','AVERAGE','MAX'),"%4.0lf");
$def[$num] .= rrd::area('replace_select','#00B99B',rrd::cut('Replace Select'),23,1);
$def[$num] .= rrd::gprint('replace_select',array('LAST','AVERAGE','MAX'),"%4.0lf");

++$num;

$ds_name[$num] = 'Files and Tables';
$opt[$num] = "--title \"$hostname - Files and Tables\"";
#$def[$num] = rrd::def('table_open_cache', $RRDFILE[1], $DS[70], 'AVERAGE');
$def[$num] = rrd::def('open_tables', $RRDFILE[1], $DS[5], 'AVERAGE');
$def[$num] .= rrd::def('open_files', $RRDFILE[1], $DS[47], 'AVERAGE');
$def[$num] .= rrd::def('opened_tables', $RRDFILE[1], $DS[49], 'AVERAGE');
#$label = rrd::cut('Table Cache',25);
#$def[$num] .= rrd::area('table_open_cache','#96E78A',$label,0);
#$def[$num] .= rrd::gprint('table_open_cache',array('LAST','AVERAGE','MAX'),"%4.0lf");
$label = rrd::cut('Open Tables',25);
$def[$num] .= rrd::line1('open_tables','#9FA4EE',$label,0);
$def[$num] .= rrd::gprint('open_tables',array('LAST','AVERAGE','MAX'),"%4.0lf");
$label = rrd::cut('Open Files',25);
$def[$num] .= rrd::line1('open_files','#FFD660',$label,0);
$def[$num] .= rrd::gprint('open_files',array('LAST','AVERAGE','MAX'),"%4.0lf");
$label = rrd::cut('Opened Tables',25);
$def[$num] .= rrd::line1('opened_tables','#FF0000',$label,0);
$def[$num] .= rrd::gprint('opened_tables',array('LAST','AVERAGE','MAX'),"%4.0lf");

++$num;

$ds_name[$num] = 'MySQL Handlers';
$opt[$num] = "--title \"$hostname - MySQL Handlers\"";
$def[$num] = rrd::def('handler_write', $RRDFILE[1], $DS[30], 'AVERAGE');
$def[$num] .= rrd::def('handler_update', $RRDFILE[1], $DS[29], 'AVERAGE');
$def[$num] .= rrd::def('handler_delete', $RRDFILE[1], $DS[31], 'AVERAGE');
$def[$num] .= rrd::def('handler_read_first', $RRDFILE[1], $DS[32], 'AVERAGE');
$def[$num] .= rrd::def('handler_read_key', $RRDFILE[1], $DS[33], 'AVERAGE');
$def[$num] .= rrd::def('handler_read_next', $RRDFILE[1], $DS[34], 'AVERAGE');
$def[$num] .= rrd::def('handler_read_prev', $RRDFILE[1], $DS[35], 'AVERAGE');
$def[$num] .= rrd::def('handler_read_rnd', $RRDFILE[1], $DS[36], 'AVERAGE');
$def[$num] .= rrd::def('handler_read_rnd_next', $RRDFILE[1], $DS[37], 'AVERAGE');
$label = rrd::cut('Handler Write',25);
$def[$num] .= rrd::area('handler_write','#605C59',$label,1);
$def[$num] .= rrd::gprint('handler_write',array('LAST','AVERAGE','MAX'),"%6.0lf");
$label = rrd::cut('Handler Update',25);
$def[$num] .= rrd::area('handler_update','#D2AE84',$label,1);
$def[$num] .= rrd::gprint('handler_update',array('LAST','AVERAGE','MAX'),"%6.0lf");
$label = rrd::cut('Handler Delete',25);
$def[$num] .= rrd::area('handler_delete','#C9C5C0',$label,1);
$def[$num] .= rrd::gprint('handler_delete',array('LAST','AVERAGE','MAX'),"%6.0lf");
$label = rrd::cut('Handler Read First',25);
$def[$num] .= rrd::area('handler_read_first','#9F3E81',$label,1);
$def[$num] .= rrd::gprint('handler_read_first',array('LAST','AVERAGE','MAX'),"%6.0lf");
$label = rrd::cut('Handler Read Key',25);
$def[$num] .= rrd::area('handler_read_key','#C6BE91',$label,1);
$def[$num] .= rrd::gprint('handler_read_key',array('LAST','AVERAGE','MAX'),"%6.0lf");
$label = rrd::cut('Handler Read Next',25);
$def[$num] .= rrd::area('handler_read_next','#CE3F53',$label,1);
$def[$num] .= rrd::gprint('handler_read_next',array('LAST','AVERAGE','MAX'),"%6.0lf");
$label = rrd::cut('Handler Read Prev',25);
$def[$num] .= rrd::area('handler_read_prev','#FD7F00',$label,1);
$def[$num] .= rrd::gprint('handler_read_prev',array('LAST','AVERAGE','MAX'),"%6.0lf");
$label = rrd::cut('Handler Read Rnd',25);

++$num;

$ds_name[$num] = 'MySQL Key RW';
$opt[$num] = "--title \"$hostname - MySQL Key RW\"";
$def[$num] = rrd::def('key_writes', $RRDFILE[1], $DS[44], 'AVERAGE');
$def[$num] .= rrd::def('key_reads', $RRDFILE[1], $DS[42], 'AVERAGE');
$def[$num] .= rrd::def('key_read_req', $RRDFILE[1], $DS[41], 'AVERAGE');
$def[$num] .= rrd::def('key_write_req', $RRDFILE[1], $DS[43], 'AVERAGE');
$label = rrd::cut('Key Writes',25);
$def[$num] .= rrd::line1('key_writes','#605C59',$label,1);
$def[$num] .= rrd::gprint('key_writes',array('LAST','AVERAGE','MAX'),"%6.0lf");
$label = rrd::cut('Key Reads',25);
$def[$num] .= rrd::line1('key_reads','#D2AE84',$label,1);
$def[$num] .= rrd::gprint('key_reads',array('LAST','AVERAGE','MAX'),"%6.0lf");
$label = rrd::cut('Key Write Requests',25);
$def[$num] .= rrd::line1('key_write_req','#C9C5C0',$label,1);
$def[$num] .= rrd::gprint('key_write_req',array('LAST','AVERAGE','MAX'),"%6.0lf");
$label = rrd::cut('Key Read Requests',25);
$def[$num] .= rrd::line1('key_read_req','#9F3E81',$label,1);
$def[$num] .= rrd::gprint('key_read_req',array('LAST','AVERAGE','MAX'),"%6.0lf");

++$num;

$ds_name[$num] = 'MySQL Query Cache';
$opt[$num] = "--title \"$hostname - MySQL Query Cache\"";
$def[$num] = rrd::def('qcache_queries_in_cache', $RRDFILE[1], $DS[54], 'AVERAGE');
$def[$num] .= rrd::def('qcache_hits', $RRDFILE[1], $DS[13], 'AVERAGE');
$def[$num] .= rrd::def('qcache_inserts', $RRDFILE[1], $DS[14], 'AVERAGE');
$def[$num] .= rrd::def('qcache_not_cached', $RRDFILE[1], $DS[15], 'AVERAGE');
$def[$num] .= rrd::def('qcache_lowmem_prunes', $RRDFILE[1], $DS[53], 'AVERAGE');
$label = rrd::cut('Queries In Cache',25);
$def[$num] .= rrd::line1('qcache_queries_in_cache','#4444FF',$label,0);
$def[$num] .= rrd::gprint('qcache_queries_in_cache',array('LAST','AVERAGE','MAX'),"%5.0lf");
$label = rrd::cut('Cache Hits',25);
$def[$num] .= rrd::line1('qcache_hits','#EAAF00',$label,0);
$def[$num] .= rrd::gprint('qcache_hits',array('LAST','AVERAGE','MAX'),"%5.0lf");
$label = rrd::cut('Inserts',25);
$def[$num] .= rrd::line1('qcache_inserts','#157419',$label,0);
$def[$num] .= rrd::gprint('qcache_inserts',array('LAST','AVERAGE','MAX'),"%5.0lf");
$label = rrd::cut('Not Cached',25);
$def[$num] .= rrd::line1('qcache_not_cached','#00A0C1',$label,0);
$def[$num] .= rrd::gprint('qcache_not_cached',array('LAST','AVERAGE','MAX'),"%5.0lf");
$label = rrd::cut('Low-Memory Prunes',25);
$def[$num] .= rrd::line1('qcache_lowmem_prunes','#FF0000',$label,0);
$def[$num] .= rrd::gprint('qcache_lowmem_prunes',array('LAST','AVERAGE','MAX'),"%5.0lf");

++$num;

$ds_name[$num] = 'Prepared Statements';
$opt[$num] = "--title \"$hostname - Prepared Statements\"";
$def[$num] = rrd::def('prepared_stmt_count', $RRDFILE[1], $DS[50], 'AVERAGE');
$label = rrd::cut('Prepared Statement Count',25);
$def[$num] .= rrd::line1('prepared_stmt_count','#4444FF',$label,0);
$def[$num] .= rrd::gprint('prepared_stmt_count',array('LAST','AVERAGE','MAX'),"%5.0lf");

++$num;

$ds_name[$num] = 'Select Types';
$opt[$num] = "--title \"$hostname - Select Types\"";
$def[$num] = rrd::def('select_full_join', $RRDFILE[1], $DS[56], 'AVERAGE');
$def[$num] .= rrd::def('select_full_range_join', $RRDFILE[1], $DS[69], 'AVERAGE');
$def[$num] .= rrd::def('select_range', $RRDFILE[1], $DS[70], 'AVERAGE');
$def[$num] .= rrd::def('select_range_check', $RRDFILE[1], $DS[71], 'AVERAGE');
$def[$num] .= rrd::def('select_scan', $RRDFILE[1], $DS[72], 'AVERAGE');
$label = rrd::cut('Full Join',25);
$def[$num] .= rrd::area('select_full_join','#FF0000',$label,1);
$def[$num] .= rrd::gprint('select_full_join',array('LAST','AVERAGE','MAX'),"%5.0lf");
$label = rrd::cut('Full Range',25);
$def[$num] .= rrd::area('select_full_range_join','#FF7D00',$label,1);
$def[$num] .= rrd::gprint('select_full_range_join',array('LAST','AVERAGE','MAX'),"%5.0lf");
$label = rrd::cut('Range',25);
$def[$num] .= rrd::area('select_range','#FFF200',$label,1);
$def[$num] .= rrd::gprint('select_range',array('LAST','AVERAGE','MAX'),"%5.0lf");
$label = rrd::cut('Range Check',25);
$def[$num] .= rrd::area('select_range_check','#00CF00',$label,1);
$def[$num] .= rrd::gprint('select_range_check',array('LAST','AVERAGE','MAX'),"%5.0lf");
$label = rrd::cut('Scan',25);
$def[$num] .= rrd::area('select_scan','#7CB3F1',$label,1);
$def[$num] .= rrd::gprint('select_scan',array('LAST','AVERAGE','MAX'),"%5.0lf");

++$num;

$ds_name[$num] = 'Sorts';
$opt[$num] = "--title \"$hostname - Sorts\"";
$def[$num] = rrd::def('sort_rows', $RRDFILE[1], $DS[75], 'AVERAGE');
$def[$num] .= rrd::def('sort_range', $RRDFILE[1], $DS[74], 'AVERAGE');
$def[$num] .= rrd::def('sort_merge_passes', $RRDFILE[1], $DS[73], 'AVERAGE');
$def[$num] .= rrd::def('sort_scan', $RRDFILE[1], $DS[76], 'AVERAGE');
$label = rrd::cut('Rows Sorted',25);
$def[$num] .= rrd::area('sort_rows','#FFAB00',$label,0);
$def[$num] .= rrd::gprint('sort_rows',array('LAST','AVERAGE','MAX'),"%5.0lf");
$label = rrd::cut('Range',25);
$def[$num] .= rrd::line1('sort_range','#157419',$label,0);
$def[$num] .= rrd::gprint('sort_range',array('LAST','AVERAGE','MAX'),"%5.0lf");
$label = rrd::cut('Merge Passes',25);
$def[$num] .= rrd::line1('sort_merge_passes','#DA4725',$label,0);
$def[$num] .= rrd::gprint('sort_merge_passes',array('LAST','AVERAGE','MAX'),"%5.0lf");
$label = rrd::cut('Scan',25);
$def[$num] .= rrd::line1('sort_scan','#4444FF',$label,0);
$def[$num] .= rrd::gprint('sort_scan',array('LAST','AVERAGE','MAX'),"%5.0lf");

++$num;

$ds_name[$num] = 'Table Locks';
$opt[$num] = "--title \"$hostname - Table Locks\"";
$def[$num] = rrd::def('table_locks_immediate', $RRDFILE[1], $DS[58], 'AVERAGE');
$def[$num] .= rrd::def('table_locks_waited', $RRDFILE[1], $DS[59], 'AVERAGE');
$label = rrd::cut('Table Locks Immediate',25);
$def[$num] .= rrd::line1('table_locks_immediate','#002A8F',$label,0);
$def[$num] .= rrd::gprint('table_locks_immediate',array('LAST','AVERAGE','MAX'),"%5.0lf");
$label = rrd::cut('Table Locks Waited',25);
$def[$num] .= rrd::line1('table_locks_waited','#FF3932',$label,0);
$def[$num] .= rrd::gprint('table_locks_waited',array('LAST','AVERAGE','MAX'),"%5.0lf");

++$num;

$ds_name[$num] = 'Temporary Objects';
$opt[$num] = "--title \"$hostname - Temporary Objects\"";
$def[$num] = rrd::def('created_tmp_tables', $RRDFILE[1], $DS[25], 'AVERAGE');
$def[$num] .= rrd::def('created_tmp_disk_tables', $RRDFILE[1], $DS[23], 'AVERAGE');
$def[$num] .= rrd::def('created_tmp_files', $RRDFILE[1], $DS[24], 'AVERAGE');
$label = rrd::cut('Temp Tables',25);
$def[$num] .= rrd::area('created_tmp_tables','#837C04',$label,0);
$def[$num] .= rrd::gprint('created_tmp_tables',array('LAST','AVERAGE','MAX'),"%5.0lf");
$label = rrd::cut('Temp Disk Tables',25);
$def[$num] .= rrd::line1('created_tmp_disk_tables','#F51D30',$label,0);
$def[$num] .= rrd::gprint('created_tmp_disk_tables',array('LAST','AVERAGE','MAX'),"%5.0lf");
$label = rrd::cut('Temp Files',25);
$def[$num] .= rrd::line1('created_tmp_files','#157419',$label,0);
$def[$num] .= rrd::gprint('created_tmp_files',array('LAST','AVERAGE','MAX'),"%5.0lf");

++$num;

$ds_name[$num] = 'Transaction Handler';
$opt[$num] = "--title \"$hostname - Transaction Handler\"";
$def[$num] = rrd::def('handler_commit', $RRDFILE[1], $DS[77], 'AVERAGE');
$def[$num] .= rrd::def('handler_rollback', $RRDFILE[1], $DS[78], 'AVERAGE');
$def[$num] .= rrd::def('handler_savepoint', $RRDFILE[1], $DS[79], 'AVERAGE');
$def[$num] .= rrd::def('handler_savepoint_rollback', $RRDFILE[1], $DS[80], 'AVERAGE');
$label = rrd::cut('Handler Commit',26);
$def[$num] .= rrd::line1('handler_commit','#DE0056',$label,0);
$def[$num] .= rrd::gprint('handler_commit',array('LAST','AVERAGE','MAX'),"%5.0lf");
$label = rrd::cut('Handler Rollback',26);
$def[$num] .= rrd::line1('handler_rollback','#784890',$label,0);
$def[$num] .= rrd::gprint('handler_rollback',array('LAST','AVERAGE','MAX'),"%5.0lf");
$label = rrd::cut('Handler Savepoint',26);
$def[$num] .= rrd::line1('handler_savepoint','#D1642E',$label,0);
$def[$num] .= rrd::gprint('handler_savepoint',array('LAST','AVERAGE','MAX'),"%5.0lf");
$label = rrd::cut('Handler Savepoint Rollback',26);
$def[$num] .= rrd::line1('handler_savepoint_rollback','#487860',$label,0);
$def[$num] .= rrd::gprint('handler_savepoint_rollback',array('LAST','AVERAGE','MAX'),"%5.0lf");


?>


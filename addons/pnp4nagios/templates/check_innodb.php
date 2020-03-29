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

$orange    = '#FF9933';
$blue      = '#3E9ADE';
$red       = '#FF3300';
$darkred   = '#990000';
$paleblue  = '#80B4C1';
$yellow    = '#FFCC00';

$num = 1;

$ds_name[$num] = 'InnoDB Buffer Pool';
$opt[$num] = "--title \"$hostname - InnoDB Buffer Pool\"";
#$def[$num] = rrd::def('innodb_buffer_pool_pages_total', $RRDFILE[1], $DS[11], 'AVERAGE');
$def[$num] = rrd::def('innodb_buffer_pool_pages_data', $RRDFILE[1], $DS[6], 'MAX');
$def[$num] .= rrd::def('innodb_buffer_pool_pages_free', $RRDFILE[1], $DS[9], 'AVERAGE');
$def[$num] .= rrd::def('innodb_buffer_pool_pages_dirty', $RRDFILE[1], $DS[7], 'AVERAGE');
$def[$num] .= "CDEF:innodb_buffer_pool_pages_total=innodb_buffer_pool_pages_data,innodb_buffer_pool_pages_free,+,innodb_buffer_pool_pages_dirty,+ ";
$label = rrd::cut('Pool Size',25);
$def[$num] .= rrd::area('innodb_buffer_pool_pages_total','#3D1500',$label,0);
$def[$num] .= rrd::gprint('innodb_buffer_pool_pages_total',array('LAST'),"%.1lf%S");
$label = rrd::cut('Database Pages',25);
$def[$num] .= rrd::area('innodb_buffer_pool_pages_data','#EDAA41',$label,0);
$def[$num] .= rrd::gprint('innodb_buffer_pool_pages_data',array('LAST','AVERAGE','MAX'),"%.1lf%S");
$label = rrd::cut('Free Pages',25);
$def[$num] .= rrd::area('innodb_buffer_pool_pages_free','#AA3B27',$label,1);
$def[$num] .= rrd::gprint('innodb_buffer_pool_pages_free',array('LAST','AVERAGE','MAX'),"%.1lf%S");
$label = rrd::cut('Modified Pages',25);
$def[$num] .= rrd::line1('innodb_buffer_pool_pages_dirty','#13343B',$label,0);
$def[$num] .= rrd::gprint('innodb_buffer_pool_pages_dirty',array('LAST','AVERAGE','MAX'),"%.1lf%S");

++$num;

$ds_name[$num] = 'InnoDB Buffer Pool Activity';
$opt[$num] = "--title \"$hostname - InnoDB Buffer Pool Activity\"";
$def[$num] = rrd::def('innodb_pages_created', $RRDFILE[1], $DS[34], 'AVERAGE');
$def[$num] .= rrd::def('innodb_pages_read', $RRDFILE[1], $DS[35], 'AVERAGE');
$def[$num] .= rrd::def('innodb_pages_written', $RRDFILE[1], $DS[36], 'AVERAGE');
$def[$num] .= rrd::cdef('innodb_pages_total','innodb_pages_created,innodb_pages_read,innodb_pages_written,+,+');
$label = rrd::cut('Pages Created',25);
$def[$num] .= rrd::area('innodb_pages_created','#FFAB00',$label,1);
$def[$num] .= rrd::gprint('innodb_pages_created',array('LAST','AVERAGE','MAX'),"%5.0lf");
$label = rrd::cut('Pages Read',25);
$def[$num] .= rrd::area('innodb_pages_read','#D8ACE0',$label,1);
$def[$num] .= rrd::gprint('innodb_pages_read',array('LAST','AVERAGE','MAX'),"%5.0lf");
$label = rrd::cut('Pages Written',25);
$def[$num] .= rrd::area('innodb_pages_written','#7CB3F1',$label,1);
$def[$num] .= rrd::gprint('innodb_pages_written',array('LAST','AVERAGE','MAX'),"%5.0lf");
$def[$num] .= rrd::line1('innodb_pages_total','#145EA1');

++$num;

$ds_name[$num] = 'InnoDB I/O';
$opt[$num] = "--title \"$hostname - InnoDB I/O\"";
$def[$num] = rrd::def('innodb_data_reads', $RRDFILE[1], $DS[21], 'AVERAGE');
$def[$num] .= rrd::def('innodb_data_writes', $RRDFILE[1], $DS[22], 'AVERAGE');
$def[$num] .= rrd::def('innodb_log_writes', $RRDFILE[1], $DS[28], 'AVERAGE');
$def[$num] .= rrd::def('innodb_data_fsyncs', $RRDFILE[1], $DS[16], 'AVERAGE');
$label = rrd::cut('File Reads',25);
$def[$num] .= rrd::area('innodb_data_reads','#ED7600',$label,0);
$def[$num] .= rrd::gprint('innodb_data_reads',array('LAST','AVERAGE','MAX'),"%.1lf");
$label = rrd::cut('File Writes',25);
$def[$num] .= rrd::area('innodb_data_writes','#157419',$label,1);
$def[$num] .= rrd::gprint('innodb_data_writes',array('LAST','AVERAGE','MAX'),"%.1lf");
$label = rrd::cut('Log Writes',25);
$def[$num] .= rrd::area('innodb_log_writes','#DA4725',$label,1);
$def[$num] .= rrd::gprint('innodb_log_writes',array('LAST','AVERAGE','MAX'),"%.1lf");
$label = rrd::cut('File Syncs',25);
$def[$num] .= rrd::area('innodb_data_fsyncs','#4444FF',$label,1);
$def[$num] .= rrd::gprint('innodb_data_fsyncs',array('LAST','AVERAGE','MAX'),"%.1lf");

++$num;

$ds_name[$num] = 'InnoDB I/O Pending';
$opt[$num] = "--title \"$hostname - InnoDB I/O Pending\"";
$def[$num] = rrd::def('innodb_data_pending_fsyncs', $RRDFILE[1], $DS[17], 'AVERAGE');
$def[$num] .= rrd::def('innodb_data_pending_reads', $RRDFILE[1], $DS[18], 'AVERAGE');
$def[$num] .= rrd::def('innodb_data_pending_writes', $RRDFILE[1], $DS[19], 'AVERAGE');
$label = rrd::cut('AIO Sync',25);
$def[$num] .= rrd::area('innodb_data_pending_fsyncs','#FF7D00',$label,0);
$def[$num] .= rrd::gprint('innodb_data_pending_fsyncs',array('LAST','AVERAGE','MAX'),"%.1lf");
$label = rrd::cut('Normal AIO Reads',25);
$def[$num] .= rrd::area('innodb_data_pending_reads','#B90054',$label,0);
$def[$num] .= rrd::gprint('innodb_data_pending_reads',array('LAST','AVERAGE','MAX'),"%.1lf");
$label = rrd::cut('Normal AIO Writes',25);
$def[$num] .= rrd::area('innodb_data_pending_writes','#8F9286',$label,0);
$def[$num] .= rrd::gprint('innodb_data_pending_writes',array('LAST','AVERAGE','MAX'),"%.1lf");

++$num;

$ds_name[$num] = 'InnoDB Row Lock Time';
$opt[$num] = "--title \"$hostname - InnoDB Row Lock Time\"";
$def[$num] = rrd::def('innodb_row_lock_time', $RRDFILE[1], $DS[38], 'AVERAGE');
$label = rrd::cut('InnoDB Row Lock Time',25);
$def[$num] .= rrd::area('innodb_row_lock_time','#B11D03',$label,0);
$def[$num] .= rrd::gprint('innodb_row_lock_time',array('LAST','AVERAGE','MAX'),"%.1lf");

++$num;

$ds_name[$num] = 'InnoDB Row Lock Waits';
$opt[$num] = "--title \"$hostname - InnoDB Row Lock Waits\"";
$def[$num] = rrd::def('innodb_row_lock_waits', $RRDFILE[1], $DS[41], 'AVERAGE');
$label = rrd::cut('InnoDB Row Lock Waits',25);
$def[$num] .= rrd::area('innodb_row_lock_waits','#E84A5F',$label,0);
$def[$num] .= rrd::gprint('innodb_row_lock_waits',array('LAST','AVERAGE','MAX'),"%.1lf");

++$num;

$ds_name[$num] = 'InnoDB Row Operations';
$opt[$num] = "--title \"$hostname - InnoDB Row Operations\"";
$def[$num] = rrd::def('innodb_rows_read', $RRDFILE[1], $DS[44], 'AVERAGE');
$def[$num] .= rrd::def('innodb_rows_deleted', $RRDFILE[1], $DS[42], 'AVERAGE');
$def[$num] .= rrd::def('innodb_rows_updated', $RRDFILE[1], $DS[45], 'AVERAGE');
$def[$num] .= rrd::def('innodb_rows_inserted', $RRDFILE[1], $DS[43], 'AVERAGE');
$label = rrd::cut('Reads',10);
$def[$num] .= rrd::area('innodb_rows_read','#AFECED',$label,0);
$def[$num] .= rrd::gprint('innodb_rows_read',array('LAST','AVERAGE','MAX'),"%.1lf");
$label = rrd::cut('Deletes',10);
$def[$num] .= rrd::area('innodb_rows_deleted','#DA4725',$label,0);
$def[$num] .= rrd::gprint('innodb_rows_deleted',array('LAST','AVERAGE','MAX'),"%.1lf");
$label = rrd::cut('Updates',10);
$def[$num] .= rrd::area('innodb_rows_updated','#EA8F00',$label,0);
$def[$num] .= rrd::gprint('innodb_rows_updated',array('LAST','AVERAGE','MAX'),"%.1lf");
$label = rrd::cut('Inserts',10);
$def[$num] .= rrd::area('innodb_rows_inserted','#35962B',$label,0);
$def[$num] .= rrd::gprint('innodb_rows_inserted',array('LAST','AVERAGE','MAX'),"%.1lf");




?>


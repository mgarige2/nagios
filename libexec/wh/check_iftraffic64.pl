#!/usr/bin/perl -w
#
# check_iftraffic.pl - Nagios(r) network traffic monitor plugin
# Copyright (C) 2004 Gerd Mueller / Netways GmbH
# $Id: check_iftraffic.pl 1119 2006-02-09 10:30:09Z gmueller $
# Version: .6
#
# mw = Markus Werner mw+nagios@wobcom.de
# Remarks (mw):
#
#	I adopted as much as possible the programming style of the origin code.
#
#	There should be a function to exit this programm,
#	instead of calling print and exit statements all over the place.
#
# minor changes by mw
# 	The snmp if_counters on net devices can have overflows.
#	I wrote this code to address this situation.
#	It has no automatic detection and which point the overflow
#	occurs but it will generate a warning state and you
#	can set the max value by calling this script with an additional
#	arg.
#
# minor cosmetic changes by mw
#	Sorry but I couldn't sustain to clean up some things.
#
# gj = Greg Frater gregATfraterfactory.com
# Remarks (gj):
# minor (gj):
# 
#	* fixed the performance data, formating was not to spec
# 	* Added a check of the interfaces status (up/down).
#	  If interface is down the check returns a critical status.
# 	* Support both textual or the numeric index values.
#	* If the interface speed is not specified on the command line
#	  it gets it automatically from IfHighSpeed (or ifSpeed if IfHighSpeed
#	  counter is not available)
#	* Added option to specify a second Speed parameter to allow for 
#	  asymetrcal links such as a DSL line or cable modem where the 
#	  download and upload speeds are different
#	* Added -B option to display results in bits/sec instead of Bytes/sec
#	* Added the current usage in Bytes/s (or bit/s) to the perfdata output
#	* Added ability for plugin to determine interface to query by matching IP 
#	  address of host with entry in ipAdEntIfIndex (.1.3.6.1.2.1.4.20.1.2) 
#	* Added -L flag to list entries found in the ipAdEntIfIndex table
#	Otherwise, it works as before.
#
#
#
#
# based on check_traffic from Adrian Wieczorek, <ads (at) irc.pila.pl>
#
# Send us bug reports, questions and comments about this plugin.
# Latest version of this software: http://www.nagiosexchange.org
#
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307

use strict;

use Data::Dumper;
use Net::SNMP;
use Getopt::Long;
use Scalar::Util qw(looks_like_number);
&Getopt::Long::config('bundling');

use Data::Dumper;

my $host_ip;
my $host_address;
my $iface_number;
my $iface_descr;
my $iface_speed;
my $iface_speedOut;
my $index_list;
my $opt_h;
my $units;
my $in_ave = 0;
my $out_ave = 0;
my $in_tot = 0;
my $out_tot = 0;

my $session;
my $error;
my $port         = 161;

my @snmpoids;

#my $snmpIfInOctets;
#my $snmpIfOutOctets;

# SNMP OIDs for Traffic
my $snmpIfOperStatus 	= '1.3.6.1.2.1.2.2.1.8';	# Operational state of interface (i.e. 1-up, 2-down, etc.)
my $snmpIfInOctets32  	= '1.3.6.1.2.1.2.2.1.10';	# Total Octets entering interface (in) - 32 bit counter
my $snmpIfOutOctets32 	= '1.3.6.1.2.1.2.2.1.16';	# Total Octets leaving interface (out) - 32 bit counter
my $snmpIfInOctets  	= '1.3.6.1.2.1.31.1.1.1.6';	# Total Octets entering interface (in) - 64 bit counter
my $snmpIfOutOctets 	= '1.3.6.1.2.1.31.1.1.1.10';	# Total Octets leaving interface (out) - 64 bit counter
my $snmpIfDescr     	= '1.3.6.1.2.1.2.2.1.2';	# Textual string describing interface
my $snmpIfSpeed32     	= '1.3.6.1.2.1.2.2.1.5'; 	# bits per second
my $snmpIfSpeed    	= '1.3.6.1.2.1.31.1.1.1.15'; 	# Mbits per second
my $snmpIPAdEntIfIndex 	= '1.3.6.1.2.1.4.20.1.2'; 	# Index of interface using hosts IP addr

my $response;

# Path to  tmp files
my $TRAFFIC_FILE = "/usr/local/nagios/libexec/traffic/";
#my $TRAFFIC_FILE = "traffic/";

# Create tmp file location if it does not exist
if ( ! -d $TRAFFIC_FILE ) {
	mkdir $TRAFFIC_FILE;
}

# changes sos 20090717 UNKNOWN must be 3
my %STATUS_CODE =
  ( 'UNKNOWN' => '3', 'OK' => '0', 'WARNING' => '1', 'CRITICAL' => '2' );

#default values;
my $state = "UNKNOWN";
my $debug = 0;
my $if_status	= '4';
my ( $in_bytes, $out_bytes ) = 0;
my $warn_usage	= 85;
my $crit_usage	= 98;
my $COMMUNITY	= "public";
my $use_reg	=  undef;  # Use Regexp for name
#my $debug	=  undef;  # Enable debuging
my $output = "";
my $bits = undef; 
my $suffix = "Bs";
my $label = "";
my $thirtytwo = undef;
my $snmp_version = 2;

#added 20050614 by mw
my $max_value;
my $max_bytes;

#cosmetic changes 20050614 by mw, see old versions for detail
# Added options for bits and second max ifspeed 20100202 by gj
# Added options for specific IP addr to match 20100405 by gj
my $status = GetOptions(
	"h|help"        => \$opt_h,
	'B'		=> \$bits,
	'bits'		=> \$bits,
	"C|community=s" => \$COMMUNITY,
	"w|warning=s"   => \$warn_usage,
	"c|critical=s"  => \$crit_usage,
	"b|bandwidth|I|inBandwidth=i" => \$iface_speed,
	"O|outBandwidth=i" => \$iface_speedOut,
        'r'             => \$use_reg,           
        'noregexp'      => \$use_reg,
	"p|port=i"      => \$port,
	"u|units=s"     => \$units,
	"i|interface=s" => \$iface_descr,
	"A|address=s"   => \$host_ip,
	"H|hostname=s"  => \$host_address,
	'L'	  	=> \$index_list,
	"d|debug=i"	=> \$debug,
	'list'	  	=> \$index_list,
	"v|Version=s"	=> \$snmp_version,

	#added 20050614 by mw
	"M|max=i" => \$max_value,
		
	#added 20101104 by gjf
	"32|32bit"		=> \$thirtytwo
);

if ( $status == 0 ) {
	print_help();
	exit $STATUS_CODE{'OK'};
}

debugout ("DEBUG ENALBED at level: $debug", "1");
debugout ("INTERFACE DESCR: $iface_descr", "1"), if ( defined($iface_descr) );

# Changed 20091214 gj
# Check for missing options
#if ( ( !$host_address ) or ( !$iface_descr ) ) {
if ( !$host_address )  {
	print  "\nMissing host address!\n\n";
	stop(print_usage(),"OK");
} elsif ( ( $iface_speed ) and ( !$units ) ){
	print "\nMissing units!\n\n";
	stop(print_usage(),"OK");
} elsif ( ( $units ) and ( ( !$iface_speed ) and  ( !$iface_speedOut ) ) ) {
	print "\nMissing (-I or -O) interface maximum speed!\n\n";
	stop(print_usage(),"OK");
} elsif ( ( $iface_speedOut ) and ( !$units ) ) {
	print "\nMissing units (-u) for Out maximum speed!\n\n";
	stop(print_usage(),"OK");
} elsif ( ( $max_value ) and ( !$units ) ) {
	print "\nMissing units (-u) for maximum couter!\n\n";
	stop(print_usage(),"OK");
}

# Switch output from Bytes to bits if necessary
if ($bits) {
	$suffix = "bs"
}

# Switch to 32 bit counters if necessary
if ( defined($thirtytwo) ) {
	$snmpIfInOctets = $snmpIfInOctets32;
	$snmpIfOutOctets = $snmpIfOutOctets32;
#	$snmpIfSpeed = $snmpIfSpeed32;
}

if ( !$iface_speed ) {
	# Do nothing
} else {

	#change 20050414 by mw
	# Added iface_speedOut 20100202 by gj
	# Convert interface speed to Bytes
	$iface_speed = bits2bytes( $iface_speed, $units );
	if ( $iface_speedOut ) {
		$iface_speedOut = bits2bytes( $iface_speedOut, $units );
	}
}

if ( !$max_value ) {

	# If no -M Parameter was set, set it to 64Bit Overflow
	$max_bytes = 18446744073709600000;    # the value is (2^64)

	if ( defined($thirtytwo) ){
		# If using 32bit counters set to 32bit overflow
		$max_bytes = 4294967296;    # the value is (2^32)
	}
} else {
	# Max value specified, used given value, convert to Bytes
	$max_bytes = unit2bytes( $max_value, $units );
}

debugout ("BYTE COUNTER max_value: $max_bytes", "2");

# Check snmp version, set snmp parameters
if ( $snmp_version =~ /[12]/ ) {
	( $session, $error ) = Net::SNMP->session(
		-hostname  => $host_address,
		-community => $COMMUNITY,
		-port      => $port,
		-version   => $snmp_version
	);

	if ( !defined($session) ) {
		stop("UNKNOWN: $error","UNKNOWN");
	}
} elsif ( $snmp_version =~ /3/ ) {
	$state = 'UNKNOWN';
	stop("$state: No support for SNMP v3 yet\n",$state);
} else {
	$state = 'UNKNOWN';
	stop("$state: No support for SNMP v$snmp_version yet\n",$state);
}

debugout("SNMP:\n\tver: $snmp_version\n\tcommunity: $COMMUNITY\n\tport: $port", "3");

# Neither Interface Index nor Host IP address were specified 
if ( !$iface_descr ) {
	if ( !$host_ip ){
		# try to resolve host name and find index from ip addr
		debugout("DETECT INTERFACE start with hostname", "1");
		$iface_descr = fetch_Ip2IfIndex( $session, $host_address );
	} else {
		# Use ip addr to find index
		debugout("DETECT INTERFACE start with IP addr","1");
		$iface_descr = fetch_Ip2IfIndex( $session, $host_ip );
	}	
}

# Added 20091209 gj
# Detect if a string description was given or a numberic interface index number 
if ( $iface_descr =~ /[^0123456789]+/ ) {
	$iface_number = fetch_ifdescr( $session, $iface_descr );
	debugout("INTERFACE from text string","1"); 
} else {
	$iface_number = $iface_descr;
}

debugout("USING INT#: $iface_number", "2");
debugout("OID's:\n\tIfSpeed: $snmpIfSpeed.$iface_number\n\tIfOperStatus: $snmpIfOperStatus.$iface_number", "2");
debugout("\tInOctets: $snmpIfInOctets.$iface_number\n\tOutOctets: $snmpIfOutOctets.$iface_number", "2");

push( @snmpoids, $snmpIfSpeed . "." . $iface_number );
if ( defined($thirtytwo) ) {
	push( @snmpoids, $snmpIfSpeed32 . "." . $iface_number) 
}
push( @snmpoids, $snmpIfOperStatus . "." . $iface_number );
push( @snmpoids, $snmpIfInOctets . "." . $iface_number );
push( @snmpoids, $snmpIfOutOctets . "." . $iface_number );

if ( !defined( $response = $session->get_request(@snmpoids) ) ) {
	my $answer = $session->error;
	$session->close;

	stop("WARNING: SNMP error: $answer, interface may not support 64 bit counter!\n", "WARNING");
}

$if_status = $response->{ $snmpIfOperStatus . "." . $iface_number };
$in_bytes  = $response->{ $snmpIfInOctets . "." . $iface_number };
$out_bytes = $response->{ $snmpIfOutOctets . "." . $iface_number };
my $ifspeed = $response->{ $snmpIfSpeed . "." . $iface_number };


debugout ("FROM SNMP for int:\n\tspeed: $ifspeed\n\tstatus: $if_status\n\tIn Bytes: $in_bytes\n\tOut Bytes: $out_bytes", "1");
if ( $in_bytes eq "noSuchObject" || $out_bytes eq "noSuchObject" ) {
	# Missing data can't continue
	$state = 'UNKNOWN';
	if ( defined($thirtytwo) ) {
		stop("$state: Missing some data, does this device provide 32 bit counters?\n",$state);
	} else {
		stop("$state: Missing some data, does this device provide 64 bit counters?\n",$state);
	}
}

# Added 20091209 gj
if ( !$iface_speed ) {

	# Interface speed not provided on command line, get from device	
	# Get 64 bit IfSpeed value
	$iface_speed = $response->{ $snmpIfSpeed . "." . $iface_number };
	debugout ("64bit INT SPEED: $iface_speed", "3");

	if ( looks_like_number($iface_speed) ) {
		# Returned number as expeted not "noSuchObject" error
		if ( $iface_speed > 0 ) { 
			# Numeric value returned, proceed
			# 64bit iface speed is in Mbits, convert to bits
			$iface_speed = $iface_speed * 1000 * 1000;
			debugout ("INT SPEED converted from Mb to bits: $iface_speed", "3");
		} else {
			# number returned but NOT greater than zero - bad output
			# try 32 bit speed counter
			$iface_speed = $response->{ $snmpIfSpeed32 . "." . $iface_number };		
			debugout ("INTERFACE using 32 bit speed counters: $iface_speed", "2");
		}
	} else {
		# 64 bit speed counter returned non numeric value, possible error
		$iface_speed = $response->{ $snmpIfSpeed32 . "." . $iface_number };		
		debugout ("INTERFACE using 32 bit speed counters: $iface_speed", "2");
		if ($iface_speed >= 4294967295){
			# 32 bit counter at ceiling, too fast or not accurate report of interface speed
			$state = 'UNKNOWN';
			stop("$state: Interface too fast for 32bit counters, are 64 bit counters available?\n",$state);
		} 
	}

	# Convert speed from bits to Bytes
	$units = "b";
	$iface_speed = bits2bytes( $iface_speed, $units );
}

debugout ("UNITS: $units", "1");
debugout ("INTERFACE speed calculated as: $iface_speed", "1");

# Added 20100201 gj
# Check if Out max speed was provided, use same if speed for both if not
if (!$iface_speedOut) {
	$iface_speedOut = $iface_speed;
}

debugout ("INTERFACE speed OUT: $iface_speedOut", "1");

$session->close;

my $row;
my $last_check_time = time - 1;
my $last_in_bytes   = $in_bytes;
my $last_out_bytes  = $out_bytes;

if (
	open( FILE,
		"<" . $TRAFFIC_FILE . $host_address . "_if-" . $iface_number
	)
  )
{
	while ( $row = <FILE> ) {

		( $last_check_time, $last_in_bytes, $last_out_bytes ) =
		  split( ":", $row );

		### by sos 17.07.2009 check for last_bytes
		if ( ! $last_in_bytes  ) { $last_in_bytes=$in_bytes;  }
		if ( ! $last_out_bytes ) { $last_out_bytes=$out_bytes; }

		if ($last_in_bytes !~ m/\d/) { $last_in_bytes=$in_bytes; }
		if ($last_out_bytes !~ m/\d/) { $last_out_bytes=$out_bytes; }
	}
	close(FILE);
}

my $update_time = time;
debugout ("CURRENT timestamp: $update_time", "1");
debugout ("FILE PATH: $TRAFFIC_FILE" . $host_address . "_if-" . $iface_number, "1");
debugout("READ FROM FILE:\n\tlast time: $last_check_time\n\tlast in bytes: $last_in_bytes\n\tlast out bytes: $last_out_bytes","2");

open( FILE, ">" . $TRAFFIC_FILE . $host_address . "_if-" . $iface_number )
  or die "Can't open $TRAFFIC_FILE for writing: $!";

printf FILE ( "%s:%.0ld:%.0ld\n", $update_time, $in_bytes, $out_bytes );
close(FILE);

debugout("WRITTEN TO FILE:\n\ttime: $update_time\n\tin_bytes: $in_bytes\n\tout bytes: $out_bytes","2");

#added 20050614 by mw
#Check for and correct counter overflow (if possible).
#See function counter_overflow.
$in_bytes  = counter_overflow( $in_bytes,  $last_in_bytes,  $max_bytes );
$out_bytes = counter_overflow( $out_bytes, $last_out_bytes, $max_bytes );

# Calculate traffic since last check (RX\TX) 
my $in_traffic = sprintf( "%.2lf",
	( $in_bytes - $last_in_bytes ) / ( time - $last_check_time ) );
my $out_traffic = sprintf( "%.2lf",
	( $out_bytes - $last_out_bytes ) / ( time - $last_check_time ) );

debugout("in_traffic: $in_traffic\nout_traffic: $out_traffic","1");
# sos 20090717 changed because rrdtool needs bytes
my $in_bytes_abs  = $in_bytes;
my $out_bytes_abs = $out_bytes;

debugout("iface_speed: $iface_speed\nin_traffic: $in_traffic\nout_traffic: $out_traffic", "1");

# Calculate usage percentages
my $in_ave_pct  = sprintf( "%.2f", ( 1.0 * $in_traffic * 100 ) / $iface_speed );
my $out_ave_pct = sprintf( "%.2f", ( 1.0 * $out_traffic * 100 ) / $iface_speedOut );


if ($bits) {
	# Convert output from Bytes to bits
	$label = "bits";
	$in_tot = $in_bytes * 8;
	$out_tot = $out_bytes * 8;
	$in_ave = $in_traffic * 8;
	$out_ave = $out_traffic * 8;	
} else {
	$label = "Bytes";
	$in_tot = $in_bytes;
	$out_tot = $out_bytes;
	$in_ave = $in_traffic;
	$out_ave = $out_traffic;
}

debugout("OUTPUT:\n\tlabel: $label", "1");
debugout("\tin_tot: $in_tot\n\tout_tot: $out_tot\n\tin_ave: $in_ave\n\tout_ave: $out_ave", "2");
debugout("\tin_ave_pct: $in_ave_pct\n\tout_ave_pct: $out_ave_pct\n\tin_bytes_abs: $in_bytes_abs\n\tout_bytes_abs: $out_bytes_abs", "2");

# Scale ave and tot for output
$in_tot = unit2scale($in_tot);
$out_tot = unit2scale($out_tot);
$in_ave = unit2scale($in_ave);
$out_ave = unit2scale($out_ave);

# Convert from Bytes/bits to megaBytes/bits
$in_bytes  = sprintf( "%.2f", $in_bytes / (1024 * 1000) );
$out_bytes = sprintf( "%.2f", $out_bytes / (1024 * 1000) );

$state = "OK";

# Added 20091209 by gj
if ( $if_status != 1 ) {
	$output = "Interface $iface_descr is down!";
	$state = "CRITICAL";
}else{
	$output =
	"Average IN: "
	  . $in_ave . $suffix . " (" . $in_ave_pct . "%), " 
	  . "Average OUT: " . $out_ave . $suffix . " (" . $out_ave_pct . "%), ";
	$output .= "Total RX: $in_tot" . "$label, Total TX: $out_tot" . "$label";
}

# Changed 20091209 gj
if ( ( $in_ave_pct > $crit_usage ) or ( $out_ave_pct > $crit_usage ) or ( $if_status != 1 ) ) {
	$state = "CRITICAL";
}

if (   ( $in_ave_pct > $warn_usage )
	or ( $out_ave_pct > $warn_usage ) && $state eq "OK" )
{
	$state = "WARNING";
}

# Changed 20091209 gj
$output = "$state - $output"
  if ( $state ne "OK" );

# Changed 20091214 gj - commas should have been semi colons
$output .=
"|inUsage=$in_ave_pct%;$warn_usage;$crit_usage outUsage=$out_ave_pct%;$warn_usage;$crit_usage"
  . " inBandwidth=" . $in_ave . $suffix . " outBandwidth=" . $out_ave . $suffix 
  . " inAbsolut=$in_bytes_abs" . "B" . " outAbsolut=$out_bytes_abs" . "B";

debugout ("",1);
stop($output, $state);


sub fetch_Ip2IfIndex {
	my $state;
	my $response;

	my $snmpkey;
	my $answer;
	my $key;

	my ( $session, $host ) = @_;


	# Determine if we have a host name or IP addr
	if ( $host =~ /\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}/ ){
		#debugout("I found an IP address: $host","3");
	} else {
		debugout("RESOLVING hostname $host","3");
		$host = get_ip ( $host );
		debugout("HOSTNAME RESOLVED to IP addr: $host","3");
	}

	# Quit if results not found
	if ( !defined( $response = $session->get_table($snmpIPAdEntIfIndex) ) ) {
		$answer = $session->error;
		$session->close;
		$state = 'CRITICAL';
		stop ("$state: Interface index not detected ERROR: $answer",$state);
	}

	
	my %resp = %{$response};

	if ( $index_list ){
		print ("\nInterfaces found:\n");
		print ("  IP Addr\tIndex\n");
		print ("------------------------\n");
	}		
	# Check each returned value
	foreach $key ( keys %resp ) {

		if ( $index_list ){
			my $index_addr = substr $key, 21;
			print ($index_addr,"\t ",$resp{$key},"\n");
		}

		# Check for ip address match in returned index results
		if ( $key =~ /$host$/ ) {
			$snmpkey = $resp{$key};
		}
	}
	unless ( defined $snmpkey ) {
		$session->close;
		$state = 'CRITICAL';
		stop("$state: Could not find index matching $host",$state);
	}
	return $snmpkey;
}

sub fetch_ifdescr {
	my $state;
	my $response;

	my $snmpkey;
	my $answer;
	my $key;

	my ( $session, $ifdescr ) = @_;

	if ( !defined( $response = $session->get_table($snmpIfDescr) ) ) {
		$answer = $session->error;
		$session->close;
		$state = 'CRITICAL';
		exit $STATUS_CODE{$state};
	}

	foreach $key ( keys %{$response} ) {

		# added 20070816 by oer: remove trailing 0 Byte for Windows :-(
		my $resp=$response->{$key};
		$resp =~ s/\x00//;


                my $test = defined($use_reg)
                      ? $resp =~ /$ifdescr/
                      : $resp eq $ifdescr;

                if ($test) {

		###if ( $resp =~ /^$ifdescr$/ ) {
		###if ( $resp =~ /$ifdescr/ ) {
                ### print "$resp  \n";
		###if ( $response->{$key} =~ /^$ifdescr$/ ) {

			$key =~ /.*\.(\d+)$/;
			$snmpkey = $1;

			 print "$ifdescr = $key / $snmpkey \n";  #debug
		}
	}
	unless ( defined $snmpkey ) {
		$session->close;
		$state = 'CRITICAL';
		printf "$state: Could not match $ifdescr \n";
		exit $STATUS_CODE{$state};
	}
	return $snmpkey;
}

#added 20050416 by mw
#Converts an input value to value in bits
sub bits2bytes {
	return unit2bytes(@_) / 8;
}

#added 20050416 by mw
#Converts an input value to value in bytes
sub unit2bytes {
	my ( $value, $unit ) = @_;

	if ( $unit eq "g" ) {
		return $value * 1000 * 1000 * 1000;
	}
	elsif ( $unit eq "m" ) {
		return $value * 1000 * 1000;
	}
	elsif ( $unit eq "k" ) {
		return $value * 1000;
	}
	elsif ( $unit eq "b" ) {
		return $value * 1;
	}
	else {
		print "You have to supply a supported unit\n";
		exit $STATUS_CODE{'UNKNOWN'};
	}
}

sub unit2scale {
	# Scale output, expecting Bits\Bytes input
	my ($val) = @_;
	my $prefix = "B";

	# I'm not sure which should be used here 1024 or 1000 but 1000 is easier on the
	# eye when looking at the plug-in output
	#if ( $val > 1024 ) {
	if ( $val > 1000 ) {
	#	$val = sprintf( "%.2f", $val / 1024 );
		$val = sprintf( "%.2f", $val / 1000 );
		$prefix = "K";
	}
	if ( $val > 1000 ) {
		$val = sprintf( "%.2f", $val / 1000 );
		$prefix = "M";
	}
	if ( $val > 1000 ) {
		$val = sprintf( "%.2f", $val / 1000 );
		$prefix = "G";
	}
	return $val . $prefix;
}

# Convert from Bytes/bits to megaBytes/bits
#added 20050414 by mw
#This function detects if an overflow occurs. If so, it returns
#a computed value for $bytes.
#If there is no counter overflow it simply returns the origin value of $bytes.
#IF there is a Counter reboot wrap, just use previous output.
sub counter_overflow {
	my ( $bytes, $last_bytes, $max_bytes ) = @_;

	$bytes += $max_bytes if ( $bytes < $last_bytes );
	$bytes = $last_bytes  if ( $bytes < $last_bytes );
	return $bytes;
}

# Added 20100202 by gj
# Print results and exit script
sub stop {
	my $result = shift;
	my $exit_code = shift;
	print $result . "\n";
	exit ( $STATUS_CODE{$exit_code} );
}

# Added 20100405 by gj
# Lookup hosts ip address
sub get_ip {
	use Net::DNS;

	my ( $host_name ) = @_;

	my $res = Net::DNS::Resolver->new;
	my $query = $res->search($host_name);

	if ($query) {
		foreach my $rr ($query->answer) {
			next unless $rr->type eq "A";
			return $rr->address;
		}
	} else {
		
		stop("Error: IP address not resolved","UNKNOWN");
	}
}

sub debugout {

	my ( $text, $level ) = @_;

	if ( $level <= $debug) {
		print "$text\n";
	}
}

#cosmetic changes 20050614 by mw
#Couldn't sustain "HERE";-), either.
sub print_usage {
	print <<EOU;
    Usage: check_iftraffic64.pl -H host [ -C community_string ] [ -i if_index|if_descr ] [ -r ] [ -b if_max_speed_in | -I if_max_speed_in ] [ -O if_max_speed_out ] [ -u ] [ -B ] [ -A IP Address ] [ -L ] [ -M ] [ -w warn ] [ -c crit ]

    Example 1: check_iftraffic64.pl -H host1 -C sneaky
    Example 2: check_iftraffic64.pl -H host1 -C sneaky -i "Intel Pro" -r -B  
    Example 3: check_iftraffic64.pl -H host1 -C sneaky -i 5
    Example 4: check_iftraffic64.pl -H host1 -C sneaky -i 5 -B -b 100 -u m --32bit
    Example 5: check_iftraffic64.pl -H host1 -C sneaky -i 5 -B -I 20 -O 5 -u m 
    Example 6: check_iftraffic64.pl -H host1 -C sneaky -A 192.168.1.1 -B -b 100 -u m 

    Options:

    -H, --host STRING or IPADDRESS
        Check interface on the indicated host.
    -B, --bits FLAG
	Display results in bits per second b/s (default: Bytes/s)
    -C, --community STRING 
        SNMP Community.
    -r, --regexp
        Use regexp to match NAME in description OID
    -i, --interface STRING
        Interface Name
    -b, --bandwidth INTEGER
    -I, --inBandwidth INTEGER
        Interface maximum speed in kilo/mega/giga/bits per second. Applied to 
	both IN and OUT if out (-O) max speed is not provided. Requires -u.
    -O, --outBandwidth INTEGER
        Interface maximum speed in kilo/mega/giga/bits per second. Applied to
	OUT traffic.  Uses the same units value given for -b. Requires -u. 
    -u, --units STRING
        g=gigabits/s,m=megabits/s,k=kilobits/s,b=bits/s. Required if -b, -I, -M,
	or -O are used.
    -w, --warning INTEGER
        % of bandwidth usage necessary to result in warning status (default: 85%)
    -c, --critical INTEGER
        % of bandwidth usage necessary to result in critical status (default: 98%)
    -M, --max INTEGER
	Max Counter Value (in bits) of net devices in giga/mega/kilo/bits. Requires -u.
    -A, --address STRING (IP Address)
	IP Address to use when determining the interface index to use. Can be 
	used when the index changes frequently or as in the case of Windows 
	servers the index is different depending on the NIC installed.
    -d, --debug INTEGER
	Output some debug info, not supported inside of Nagios but may be useful
	from the command line.  Levels 1-3 can be specified, 3 being the most information.
    -L, --list FLAG (on/off)
	Tell plugin to list available interfaces. This is not supported inside 
	of Nagios but may be useful from the command line.
    -v, --Version STRING
	Set SNMP version (defaults to 2).  Version 2 required for 64 bit counters.
	Version 3 not supported. 
    --32bit FLAG
	Flag plugin to use 32 bit counters instead of 64 bit (default: 64 bit).
EOU

}



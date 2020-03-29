#!/usr/bin/perl
#
# check_iftraffic_multi - Nagios(r) network traffic monitor plugin
# Copyright (C) 2012 Peter Harrison (www.linuxhomenetworking.com)
#
# Based on code originally created for check_iftraffic and modified by the community
# Copyright (C) 2004 Gerd Mueller / Netways GmbH
#
###############################################################################################
# Changes made while script was check_iftraffic_multi
###############################################################################################
#
# ph = Peter Harrison : www.linuxhomenetworking.com 
#
#	This code is based on version 43a	
#
#	2012/09/06 by ph
#
#       * Converted script to also monitor percentage utilizaions
#	* Cleaned up the code using various subroutines
#	* Added SNMPv3 support 
#	* Added support for Net::SNMP
#	* Added support for Nagios::Plugin for more predictable Nagios states and 
#	  the support for upper and lower limits to allow for ranges of operation that 
#	  include highs and lows, not just highs.
#	  -c and -w command line options are now STRINGs, not INTEGER, to support this 
#	* Added support for File::Path. Automatically create cache directory
#	* Simplified support for "units" as it was adding unnecessary complexity to the code.
#	* -B option removed. Simplified support for "bytes". Bits and bytes are derived from "units"
#	* -M option removed. Automatically calculated
#	* Simplified logic for the use of input and output bandwidth flags
#	* Auto detect 32 / 64 bit counters without headaches.
#	* $max_bits was actually checking octets not bits. Multiplied by 8 to fix.
#
###############################################################################################
# Changes made while script was check_iftraffic.pl
###############################################################################################
#
# mw = Markus Werner mw+nagios@wobcom.de
#
# Remarks (mw):
#
#	I adopted as much as possible the programming style of the origin code.
#
#	There should be a function to exit this programm,
#	instead of calling print and exit statements all over the place.
#
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
#	  If down the check returns a critical status.
# 	* Allow either textual or the numeric index value.
#	* If the interface speed is not specified on the command line
#	  it gets it automatically from IfSpeed
#	* Added option for second ifSpeed to allow for asymetrcal links
#	  such as a DSL line or cable modem where the download and upload
#	  speeds are different
#	* Added -B option to display results in bits/sec instead of Bytes/sec
#	* Added the current usage in Bytes/s (or bit/s) to the perfdata output
#	* Added ability for plugin to determine interface to query by matching IP 
#	  address of host with entry in ipAdEntIfIndex (.1.3.6.1.2.1.4.20.1.2) 
#	* Added -L flag to list entries found in the ipAdEntIfIndex table
#	Otherwise, it works as before.
#
#	2011/08/10 by mp
#	* Added -P option to check of port-channels. Does not support 10 Gig interfaces.
#	* Modified output by adding bandwidth for charting purposes.  Very useful for charting in Splunk.
#
# Ektanoor
#	Had to radically change several snippets of code to make calculations more consistent
#	Internally all is calculated on bits. This is the basic unit for traffic calculation, so it shall stay as such.
#	No internal calculations for dimensions. All megas, gigas and kilos are made only at the beginning and ending.
#	Had to turn SNMP to version 2 as we need 64-bit counters. The 32-bit overflow too fast and too frequently.
#	Changed the way to calculate overflow. The new one is more rational and solid.
#	All errors go to stop().
#	Final note: The new version works but it can be made a lot better. All I have done was to make it workable with fast speed interfaces.
#
#       4.1 - Several changes, most of them to fit better an ISP environment:
#       - bits per second are the default now. Use -B for bytes.
#       - RX, TX and absolute values show bytes/octets only.
#       - We now use Perl's given-where "switch" in some places. Look for the correct "use" for your version of perl.
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
#
# This version supports Perl 5.10
# Also fixes output error where results are bad like below:
# CRITICAL - Average IN: 3.41Tbps (170252.50%), Average OUT: 970.95Gbps (48547.45%) Total RX: 5.81TBytes, Total TX: 1.66TBytes|inUsage=170252.50%;85;98 outUsage=48547.45%;85;98 inBandwidth=3405050072654.40bps outBandwidth=970948946016.00bps inAbsolut=6384549288059 outAbsolut=1820440453052 Bandwidth=2000000000
#
###########################################################################
# Let the coding begin ...
###########################################################################

   use strict;
   use File::Path qw(make_path);
   use Net::SNMP;
   use Net::DNS;
   use Nagios::Plugin;
   use Getopt::Long;
   &Getopt::Long::config('bundling');
   use Data::Dumper;

   &main(); exit;

sub main{

   my $interface_ip;
   my $do_32;
   my $do_percent	= 1;
   my $do_nopercent	= 0;
   my $iface_number;
   my $interface_ip;
   my $iface_descr;
   my $iface_speed;
   my $iface_speedOut;
   my $index_list;
   my $opt_h		= 0;
   my $more_help	= 0;
   my $pcstate		= "";
   my $iface_pcspeed	= 0;
   my $iface_pctest	= 0;
   my $session;
   my $error;

   # SNMP Specific
   my %snmp_vars                = ();
   my %snmp_results             = ();
   $snmp_vars{port}		= 161;
   $snmp_vars{version}		= 2;
   $snmp_vars{community}	= "public";
   my @snmpoids;
   my $response;


   # Path to tmp files
   my $data_dir 	= "/var/cache/nagios";
   if (!(-d $data_dir)) {
      make_path($data_dir, {
	verbose => 0,
	mode => 0755,
      });
   }
   my $TRAFFIC_INFILE = $data_dir . "/check_iftraffic";

   # Default command line values;
   my $if_status 		= '4';
   my ( $in_bits, $out_bits ) 	= 0;
   my $warn_usage 		= 85;
   my $crit_usage 		= 95;
   my $bwunits 			= "mb";
   my $max_bits;
   my $min_value 		= 10;

   #Need to check this
   my $use_reg    =  undef;  # Use Regexp for name

   # Get the various options
   my $status = GetOptions(
     "b|bandwidth|I|inBandwidth=i"	=> \$iface_speed,
     "P|portchannel=i"			=> \$iface_pcspeed,
     "c|critical=s"			=> \$crit_usage,
     "A|address=s"			=> \$interface_ip,
     "h|help"   			=> \$opt_h,
     "m|morehelp"   			=> \$more_help,
     "i|interface=s"			=> \$iface_descr,
     "O|outBandwidth=i"			=> \$iface_speedOut,
     "d|percent"     			=> \$do_percent,
     "D|nopercent"     			=> \$do_nopercent,
     "u|units=s"     			=> \$bwunits,
     "r|noregexp"   			=> \$use_reg,
     "w|warning=s"  			=> \$warn_usage,
     "n|min_value=i"			=> \$min_value,
     "H|hostname=s"			=> \$snmp_vars{hostname},
     "p|port=i"     			=> \$snmp_vars{port},
     "C|community=s"			=> \$snmp_vars{community},
     "s|username=s"			=> \$snmp_vars{username},
     "v|version=i"			=> \$snmp_vars{version},
     "T|authpassword=s"			=> \$snmp_vars{authpassword},
     "t|authprotocol=s"			=> \$snmp_vars{authprotocol},
     "X|privpassword=s"			=> \$snmp_vars{privpassword},
     "x|privprotocol=s"			=> \$snmp_vars{privprotocol}
   );

   # Test for Help
   if($opt_h){&print_usage();}
   if($more_help){&moreusage();}
   if(!$snmp_vars{hostname}){&print_usage();}


   # Change the default from percentages to no percentages if necessary
   if($do_nopercent){$do_percent = 0;}

   # Convert all speeds
   if($iface_speed)   {$iface_speed	= &speed_multiply($bwunits,$iface_speed);}
   if($iface_pcspeed) {$iface_pcspeed	= &speed_multiply($bwunits,$iface_pcspeed);}
   if($iface_speedOut){$iface_speedOut	= &speed_multiply($bwunits,$iface_speedOut);}

   #
   # Set variables now that we know the command line options
   # specified
   #

   # SNMP OIDs for Traffic
   my $snmpIfInOctets  		= "";
   my $snmpIfOutOctets 		= "";
   my $snmpIfOperStatus 	= '1.3.6.1.2.1.2.2.1.8';
   my $snmpIfDescr		= '1.3.6.1.2.1.2.2.1.2';
   my $snmpIfSpeed		= '1.3.6.1.2.1.2.2.1.5';
   my $snmpIPAdEntIfIndex 	= '1.3.6.1.2.1.4.20.1.2';

   # Get the SNMP session pointer
   $session = &get_snmp_session(\%snmp_vars);

   # Interface Index not specified. Try to resolve host name
   # and find index from ip addr
   # Neither Interface Index nor Host IP address were specified 
   if ( !$iface_descr ) {
      if ( !$interface_ip ) {
	# try to resolve host name and find index from ip addr
	$iface_descr = fetch_Ip2IfIndex( $session, $snmp_vars{hostname}, $snmpIPAdEntIfIndex );
      }
      else {
	# Use ip addr to find index
	$iface_descr = fetch_Ip2IfIndex( $session, $interface_ip, $snmpIPAdEntIfIndex );
      }
   }


   # Detect if a string description was given or a numeric interface index number 
   if ( $iface_descr =~ /[^0123456789]+/ ) {
      $iface_number = fetch_ifdescr( $session, $iface_descr, $snmpIfDescr, $use_reg );
   } 
   else {
      $iface_number = $iface_descr;
   }


   # Determine the oids to use (32 bit or 64)
   ($snmpIfInOctets, $snmpIfOutOctets, $do_32)= &snmp_32_bit($session, $iface_number);


   # Set the rollover value for the counters (in bits, as the counter increment bytewise)
   if ( !$do_32 ) {
      $max_bits = 18446744073709551615 * 8;
   }
   else {
      $max_bits = 4294967295 * 8;
   };


   # Create oids for critical performance information we'll need to use later
   push( @snmpoids, $snmpIfSpeed . "." . $iface_number );
   push( @snmpoids, $snmpIfOperStatus . "." . $iface_number );
   push( @snmpoids, $snmpIfInOctets . "." . $iface_number );
   push( @snmpoids, $snmpIfOutOctets . "." . $iface_number );

   # Get the performance data defined previously
   if ( !defined( $response = $session->get_request(@snmpoids) ) ) {
      my $answer = $session->error;
      &nagios_exit("SNMP error: " . $answer, "WARNING");
   }

   # If $iface_speed not defined at the command line, define it now based on SNMP data
   if ( !$iface_speed ) {
      $iface_speed = $response->{ $snmpIfSpeed . "." . $iface_number };
   }

   # Check if Out max speed was provided, use same if speed for both if not
   if (!$iface_speedOut) {
      $iface_speedOut = $iface_speed;
   }

   # Define other SNMP statuses
   $if_status = $response->{ $snmpIfOperStatus . "." . $iface_number };
   $in_bits   = $response->{ $snmpIfInOctets . "." . $iface_number }*8;
   $out_bits  = $response->{ $snmpIfOutOctets . "." . $iface_number }*8;

   # Convert the bits to values just in case
   $in_bits	= sprintf("%.2f",$in_bits);
   $out_bits	= sprintf("%.2f",$out_bits);

   # Interface down? If so, DIE!
   if ( $if_status != 1 ) {
      &nagios_exit("Interface " . $iface_descr . " is down!", "CRITICAL");
   };


   # Option -P Check Port-Channel speed to determine if all members are operational
   # Compares user input speed to actual
   if ( $iface_pcspeed != 0 ) {
      $iface_pctest = $response->{ $snmpIfSpeed . "." . $iface_number };
      if ( $iface_pctest != $iface_pcspeed ) {
        &nagios_exit("Interface " . $iface_descr . " has a member interface down!","WARNING");
      }
   }


   # Done with SNMP
   $session->close;

   # Process the data
   my ($in_usage, $out_usage, $in_traffic, $out_traffic) = 
	&process_data($if_status, $in_bits, $out_bits, 
                $TRAFFIC_INFILE, $iface_number, $snmp_vars{hostname},
        	$max_bits, $iface_speed, $iface_speedOut 
    		);


   # Report to Nagios
   &nagios_report(
	$in_usage, $out_usage,
	$in_traffic, $out_traffic,
	$iface_descr, $snmp_vars{hostname}, 
	$warn_usage, $crit_usage, $do_percent, $bwunits
	);

} # Main

sub get_snmp_session {

   # Passing multiple arrays into subroutine
   my %snmp_vars      = %{$_[0]};

   # Define the SNMP session variable
   my $session;
   my $error;

   #
   # Check for missing options
   #

   # Check missing host name
   if (!$snmp_vars{hostname}){
      &nagios_exit("Missing host address!","UNKNOWN");
   }

   # Make some variables lower case
   if ($snmp_vars{privprotocol}){$snmp_vars{privprotocol} = lc($snmp_vars{privprotocol});}
   if ($snmp_vars{authprotocol}){$snmp_vars{authprotocol} = lc($snmp_vars{authprotocol});}

   # Check SNMP version compatibility (Versions 1 & 2)
   if ( $snmp_vars{version} =~ /[12]/ ) {
      ( $session, $error ) = Net::SNMP->session(
        -hostname  => $snmp_vars{hostname},
        -community => $snmp_vars{community},
        -port      => $snmp_vars{port},
        -version   => $snmp_vars{version}
        );

   } # / SNMP version 1 or 2

   # Check SNMP version compatibility (version 3)
   elsif ( $snmp_vars{version} =~ /3/ ) {

      # AuthPriv mode
      if($snmp_vars{privpassword}){

        ($session, $error) = Net::SNMP->session(
          -username             => $snmp_vars{username},
          -authpassword         => $snmp_vars{authpassword},
          -authprotocol         => $snmp_vars{authprotocol},
          -privpassword         => $snmp_vars{privpassword},
          -privprotocol         => $snmp_vars{privprotocol},
          -hostname             => $snmp_vars{hostname},
          -port                 => $snmp_vars{port},
          -version              => $snmp_vars{version}
          );

      } # /AuthPriv mode

      # AuthNoPriv options
      else{

        # AuthNoPriv mode
        if($snmp_vars{authprotocol}){

          ($session, $error) = Net::SNMP->session(
            -username           => $snmp_vars{username},
            -authpassword       => $snmp_vars{authpassword},
            -authprotocol       => $snmp_vars{authprotocol},
            -hostname           => $snmp_vars{hostname},
            -port               => $snmp_vars{port},
            -version            => $snmp_vars{version}
            );

        } # /AuthNoPriv mode

        # noAuthNoPriv mode
        else{

          ($session, $error) = Net::SNMP->session(
            -username           => $snmp_vars{username},
            -authpassword       => $snmp_vars{authpassword},
            -hostname           => $snmp_vars{hostname},
            -port               => $snmp_vars{port},
            -version            => $snmp_vars{version}
            );

        } # /noAuthNoPriv mode

      } # /AuthNoPriv options

   } # /SNMP version 3

   # Some other version of SNMP
   else {
      &nagios_exit("Unknown SNMP v" . $snmp_vars{version},"UNKNOWN");
   };

   # Things failed, so DIE!
   if ( !defined($session) ) {
      &nagios_exit($error,"UNKNOWN");
   };

   # Return the session pointer
   return($session);
}


sub process_data {

   my ($if_status, $in_bits, $out_bits, 
       $TRAFFIC_INFILE, $iface_number, $host_address,
        $max_bits, $iface_speed, $iface_speedOut
      ) = @_;

   # Initialize variables
   my $row;
   my $last_in_bits	= 0;
   my $last_out_bits	= 0;
   my $in_traffic	= 0;
   my $out_traffic	= 0;
   my $filename		= $TRAFFIC_INFILE."_if".$iface_number."_".$host_address;

   # Define times when updates were done
   my $update_time	= time;
   my $last_check_time	= 0;


   # Does file exist and is it readable?
   if ( (-e $filename) && (-r $filename) && (-w $filename) ){

      # Read data file 
      if ( open(INFILE,"<".$filename)) {
	while ( $row = <INFILE> ) {
	  chomp($row);
	  ( $last_check_time, $last_in_bits, $last_out_bits ) = split( ':', $row );
	  if (!$last_in_bits)		{ $last_in_bits  = $in_bits;  }
	  if (!$last_out_bits)		{ $last_out_bits = $out_bits; }
	  if ($last_in_bits !~ m/\d/)	{ $last_in_bits  = $in_bits;  }
	  if ($last_out_bits !~ m/\d/)	{ $last_out_bits = $out_bits; }
	}
      }
      close(INFILE);
   }
   elsif ( (-e $filename) && (!(-r $filename) || !(-w $filename) ) ){

      # File exists but is not readable or writable
      &nagios_exit("File " . $filename . " is not readable or writable by Nagios / Icinga", "CRITICAL");
   }
   else {

      # New file to be created
      $last_check_time	= $update_time - 1;
      $last_out_bits	= $out_bits - 1;
      $last_in_bits	= $in_bits - 1; 
      
   }

   # Write new data to file 
   if ( open(OUTFILE,">".$filename )) {
      printf OUTFILE ("%s:%s:%s\n", $update_time, $in_bits, $out_bits );
      close(OUTFILE);
   };


   # Calculate $in_bits 
   if ( $in_bits < $last_in_bits ) {

      # Counter rolls over
      $in_bits		= $in_bits + ($max_bits - $last_in_bits);
      $in_traffic	= $in_bits/($update_time - $last_check_time);

   } 
   else { 
      $in_traffic = ($in_bits - $last_in_bits)/($update_time - $last_check_time); 
   };

   # Calculate $out_bits 
   if ( $out_bits < $last_out_bits ) {

      # Counter rolls over
      $out_bits		= $out_bits + ($max_bits - $last_out_bits);
      $out_traffic	= $out_bits/($update_time - $last_check_time);

   }
   else { 
      $out_traffic	= ($out_bits-$last_out_bits)/($update_time - $last_check_time); 
   };


   # Calculate usage percentages, not as decimal
   my $in_usage  = ($in_traffic*100)/$iface_speed;
   my $out_usage = ($out_traffic*100)/$iface_speedOut;

   return ($in_usage, $out_usage, $in_traffic, $out_traffic);
} # Process data

sub nagios_report {

   my (
	$in_usage, $out_usage, 
	$in_traffic, $out_traffic, 
	$ifName, $hostname,  
	$warn_usage, $crit_usage, $do_percent,$bwunits
       ) = @_;

   # Define nagios pointers and other variables
   my $np_threshold     = 0;
   my @nagios_value     = "";
   my %nagios_hash	= ();
   my $count		= -1;
   my $suffix		= "";
   my $uom		= "";
   my $np_in_traffic	= $in_traffic;
   my $np_out_traffic	= $out_traffic;

   # Convert traffic to bytes if needed
   if(&byte_output($bwunits)){
      $np_in_traffic	= $np_in_traffic / 8;
      $np_out_traffic	= $np_out_traffic / 8;
   }

   # Convert traffic to simpler nomenclature
   $np_in_traffic	= &speed_divide($bwunits,$np_in_traffic);
   $np_out_traffic	= &speed_divide($bwunits,$np_out_traffic);

   # Create suffix
   $suffix = get_suffix($bwunits);

   # Format $np_in_traffic and $np_out_traffic
   $np_in_traffic	= sprintf("%.3f",$np_in_traffic);
   $np_out_traffic	= sprintf("%.3f",$np_out_traffic);
   $in_usage		= sprintf("%.3f",$in_usage);
   $out_usage		= sprintf("%.3f",$out_usage);

   # Define the message we will be giving
   my $np_message	=  "Host " . $hostname . ", interface " . $ifName . " : ";

   # Define values we are going to pass to Nagios
   if($do_percent){
      $nagios_hash{Traffic_In_Percent}	= $in_usage; 
      $nagios_hash{Traffic_Out_Percent}	= $out_usage; 
      $uom			= "%";

      # Though tracking percentages, also provide actual values as it's more human readable 
      $np_message		.= "Traffic_In = " . $np_in_traffic . $suffix . " : ";
      $np_message		.= "Traffic_Out = " . $np_out_traffic .  $suffix . " : ";
   }
   else{
      $nagios_hash{Traffic_In}	= $np_in_traffic; 
      $nagios_hash{Traffic_Out}	= $np_out_traffic; 
      $uom			= $suffix;
   }
   # Create a Nagios object
   my $np = Nagios::Plugin->new(shortname => "IFTRAFFIC");

   foreach my $key (sort keys(%nagios_hash)){

     # Increment count
     $count +=1;

     # Format the key
     my $key_value	= sprintf("%.3f",$nagios_hash{$key});

     # Define the values we are going to test against
     $nagios_value[$count] = $key_value;

     # Define message
     $np_message .= $key . " @ " . $key_value . $uom . ", ";

     # Set up the thresholds we are interested in
     if( ($warn_usage >= 0) && ($crit_usage >= 0) ){
	$np_threshold = $np->set_thresholds(
	  warning      => $warn_usage ,
	  critical     => $crit_usage );
     }
     elsif($crit_usage >= 0){
	$np_threshold = $np->set_thresholds(
	  critical     => $crit_usage );
     }
     elsif($warn_usage >= 0){
	$np_threshold = $np->set_thresholds(
	  warning      => $warn_usage  );
     }


     # Define the performance data. $nagios_value[0]
     $np->add_perfdata(
        label => $key,
        value => $nagios_value[$count],
        threshold => $np_threshold,
        uom => $uom
     );
   }

   # All done. Remove trailing comma from $message
   $np_message =~ s/\,+\s+$//g;

   # Process and exit
   $np->nagios_exit(
        return_code => $np->check_threshold(check => \@nagios_value), message => $np_message
   );

}

sub speed_multiply{
   my ($bwunits,$iface_speed) = @_;
   return( &set_speed($bwunits,$iface_speed,0) );
}

sub speed_divide{
   my ($bwunits,$iface_speed) = @_;
   return( &set_speed($bwunits,$iface_speed,1) );
}

sub set_speed {

   my ($bwunits,$iface_speed,$do_divide) = @_;
 
   my $return_speed 	= 0;

   # Are we Kilo, Mega, Giga, Tera, Peta, Eta?
   # If so, then mutliply the iface_speed provided accordingly
   if(!$do_divide){
      if(lc($bwunits) =~ /^e/){
	$return_speed = $iface_speed * 1024 * 1024 * 1024 * 1024 * 1024 * 1024;
      }
      elsif(lc($bwunits) =~ /^p/){
	$return_speed = $iface_speed * 1024 * 1024 * 1024 * 1024 * 1024;
      }
      elsif(lc($bwunits) =~ /^t/){
	$return_speed = $iface_speed * 1024 * 1024 * 1024 * 1024;
      }
      elsif(lc($bwunits) =~ /^g/){
	$return_speed = $iface_speed * 1024 * 1024 * 1024;
      }
      elsif(lc($bwunits) =~ /^m/){
	$return_speed = $iface_speed * 1024 * 1024;
      }
      elsif(lc($bwunits) =~ /^k/){
	$return_speed = $iface_speed * 1024;
      }
      else {
	$return_speed = $iface_speed;
      }
   }
   else {
      if(lc($bwunits) =~ /^e/){
        $return_speed = $iface_speed /( 1024 * 1024 * 1024 * 1024 * 1024 * 1024 );
      }
      elsif(lc($bwunits) =~ /^p/){
        $return_speed = $iface_speed /( 1024 * 1024 * 1024 * 1024 * 1024 );
      }
      elsif(lc($bwunits) =~ /^t/){
        $return_speed = $iface_speed /( 1024 * 1024 * 1024 * 1024 );
      }
      elsif(lc($bwunits) =~ /^g/){
        $return_speed = $iface_speed /( 1024 * 1024 * 1024 );
      }
      elsif(lc($bwunits) =~ /^m/){
        $return_speed = $iface_speed /( 1024 * 1024 );
      }
      elsif(lc($bwunits) =~ /^k/){
        $return_speed = $iface_speed /( 1024 );
      }
      else {
        $return_speed = $iface_speed;
      }
   }

   return ($return_speed);
   
}

sub get_suffix {

   my ($bwunits) = @_;

   my $do_bytes         = 0;
   my $uom              = "";

   # Are we Kilo, Mega, Giga, Tera, Peta, Eta?
   # If so, then mutliply the iface_speed provided accordingly
   if(lc($bwunits) =~ /^e/){
      $uom = "E";
   }
   elsif(lc($bwunits) =~ /^p/){
      $uom = "P";
   }
   elsif(lc($bwunits) =~ /^t/){
      $uom = "T";
   }
   elsif(lc($bwunits) =~ /^g/){
      $uom = "G";
   }
   elsif(lc($bwunits) =~ /^m/){
      $uom = "M";
   }
   elsif(lc($bwunits) =~ /^k/){
      $uom = "k";
   }
   else {
      $uom = "";
   }

   # Modify $uom for bits or Bytes
   if(&byte_output($bwunits)){
      $uom	= $uom . "Bps";
   }
   else {
      $uom	= $uom . "bps";
   }

   return($uom);
}

sub byte_output{

   my ($bwunits) 	= @_;
   my $do_bytes		= 0;

   # Did the user specify Bytes?
   # If so, then return the correct status
   if($bwunits =~ m/B/){
      $do_bytes = 1;
   }
   else{
      $do_bytes = 0;
   }
   return ($do_bytes);

}

sub nagios_exit {

   my ($message, $status) = @_;
   
   $status = uc($status);
   $message = $status . ": " . $message;

   if ($status eq "UNKNOWN"){
      my $np = Nagios::Plugin->new(shortname => "UNKNOWN");
      $np->nagios_exit(UNKNOWN, $message);
   }
   elsif ($status eq "WARNING"){
      my $np = Nagios::Plugin->new(shortname => "WARNING");
      $np->nagios_exit( WARNING, $message )
   }
   elsif ($status eq "CRITICAL"){
      my $np = Nagios::Plugin->new(shortname => "CRITICAL");
      $np->nagios_exit( CRITICAL, $message )
   }
}


# Lookup hosts ip address
sub get_ip {


 my ( $host_name ) = @_;
 my $res = Net::DNS::Resolver->new;
 my $query = $res->search($host_name);

 if ($query) {
  foreach my $rr ($query->answer) {
   next unless $rr->type eq "A";
   return $rr->address;
  }
 } else {
  &nagios_exit("Host IP address not resolvable","UNKNOWN");
 }
};


sub snmp_32_bit {

   my ( $session, $iface_number ) = @_;

   # 64 bit counters
   my $snmpIfInOctets	= '1.3.6.1.2.1.31.1.1.1.6';	# 64 bit
   my $snmpIfOutOctets	= '1.3.6.1.2.1.31.1.1.1.10';    # 64 bit
  
   # Initalize other variables
   my $response;
   my @request;
   my $answer;
   my $oid_value	= 0;
   my $do_32		= 0;

   $request[0] = $snmpIfInOctets . "." . $iface_number;

   # Quit if query completely fails
   if ( !defined( $response = $session->get_request(@request) ) ) {

      $answer = $session->error;
      $session->close;
      &nagios_exit("$answer", "CRITICAL");

   }

   $oid_value = $response->{  $request[0] };
   if (!$oid_value){

      # No 64-bit found, then return 32-bit OIDs
      $snmpIfInOctets    = '1.3.6.1.2.1.2.2.1.10';
      $snmpIfOutOctets   = '1.3.6.1.2.1.2.2.1.16';

      # We are using 32 bit counters
      $do_32 = 1;
   }
   else {

      # We are using 64 bit counters
      $do_32 = 0;
   }

   return ($snmpIfInOctets, $snmpIfOutOctets, $do_32);

}

sub fetch_Ip2IfIndex {

 my ( $session, $host, $snmpIPAdEntIfIndex ) = @_;

 my $response;
 my $snmpkey;
 my $answer;
 my $key;

 # Determine if we have a host name or IP addr
 if ( $host !~ /\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}/ ) {
  $host = get_ip ( $host );
 };

 # Quit if results not found
 if ( !defined( $response = $session->get_table($snmpIPAdEntIfIndex) ) ) {
  $answer = $session->error;
  $session->close;
  &nagios_exit("$answer", "CRITICAL");
 };

 my %resp = %{$response};
 foreach $key ( keys %resp ) {
  # Check for ip address matching in returned index results
  if ( $key =~ /$host$/ ) {
   $snmpkey = $resp{$key};
  }
 }
 unless ( defined $snmpkey ) {
  $session->close;
  &nagios_exit("Could not match command line IfIndex specified for " . $host, "CRITICAL");
 }
 return $snmpkey;
};


sub fetch_ifdescr {

 my ( $session, $ifdescr, $snmpIfDescr, $use_reg ) = @_;

 my $response;
 my $snmpkey;
 my $answer;
 my $key;

 if ( !defined( $response = $session->get_table($snmpIfDescr) ) ) {
  $answer = $session->error;
  $session->close;
  &nagios_exit($answer, "UNKNOWN");
 };

 foreach $key ( keys %{$response} ) {

  # added 20070816 by oer: remove trailing 0 Byte for Windows :-(
  my $resp=$response->{$key};
  $resp =~ s/\x00//;

  my $test = defined($use_reg) ? $resp =~ /$ifdescr/ : $resp eq $ifdescr;

  if ($test) {
   $key =~ /.*\.(\d+)$/;
   $snmpkey = $1;
  }
 }
 unless ( defined $snmpkey ) {
  $session->close;
  &nagios_exit("Could not match " . $ifdescr . "specified on command line", "CRITICAL");
 }
 return $snmpkey;
};

sub print_usage {

    print <<EOU;

    This program provides alerts, status and statistics on network interface usage. Events can be triggered on actual usage
    or percentage utilization of an interface. 


    Usage: check_iftraffic_multi -H host [ -C community_string ] [ -i if_index|if_descr ] [ -r ] [ -b if_max_speed_in | -I if_max_speed_in ] 
		[ -O if_max_speed_out ] [ -P port_channel_speed ] [ -u units] [ -A IP Address ] [ -w warn ] [ -c crit ]
		[ -v snmpv3_version ] [ -s snmpv3_username ] [ -W snmpv3_authpassword ] [ -w snmpv3_authprotocol ] [ -X snmpv3_privpassword ]
		[ -x snmpv3_privprotocol ] 

    Example 1: check_iftraffic_multi -H host1 -C sneaky -D
    Example 2: check_iftraffic_multi -H host1 -C sneaky -i "Intel Pro" -r -B -d
    Example 3: check_iftraffic_multi -H host1 -C sneaky -i 5 -D
    Example 4: check_iftraffic_multi -H host1 -C sneaky -i 5 -b 100 -u mbps -D
    Example 5: check_iftraffic_multi -H host1 -C sneaky -i 5 -b 20 -O 5 -u mbps -D
    Example 6: check_iftraffic_multi -H host1 -C sneaky -A 192.168.1.1 -B -b 100 -u m kBps -D
    Example 7: check_iftraffic_multi -H host1 -C sneaky -i Port-channel50 -b 2 -u g -P 2000000000 -D

    Example 7: check_iftraffic_multi --hostname localhost --bandwidth 100  \
		--warning 1:85 --critical 98 --interface eth0 --username snmpv3user  --authpass negril \
		--authproto md5 --version 3 --percent

    Example 8: check_iftraffic_clvr --hostname localhost --bandwidth 100  --warning 85 --critical 98 --interface eth0 \
		--username securev3user --authproto md5 --authpass montegobay --version 3 --privproto des --privpass negril

    Example 9: check_iftraffic_multi --hostname localhost --bandwidth 100  --warning 1:85 --critical 98 --interface eth0 \
		--username openv3user  --authpass ochorios --version 3 --percent


    Options:

    -h, --help
        This help message

    -H, --hostname STRING or IPADDRESS
        Host to query via SNMP

    -C, --community STRING
        SNMP Community (Default = "public")

    -v, --version INTEGER
        SNMP version (Default = 2)

    -p, --port INTEGER
        SNMP UDP port (Default = 161)

    -s, --username
        Set the securityName used for authenticated SNMPv3 communication.

    -T, --authpassword
        Set the SNMPv3 authentication pass phrase used for authenticated SNMPv3 communication.

    -t, --authprotocol
        Set  the authentication protocol (MD5 or SHA) used for authenticated SNMPv3
        communication.

    -X, --privpassword
        Set the privacy pass phrase used for encrypted SNMPv3 communication.

    -x, --privprotocol
        Set the privacy protocol (DES or AES) used for encrypted SNMPv3 communication.

    -A, --address STRING
        IP address of interface to monitor, if --interface is unknown

    -i, --interface STRING
        Interface Name

    -b, --bandwidth INTEGER

    -I, --inBandwidth INTEGER
        Interface maximum speed in kilo/mega/giga/bits per second.  Applied to
        both IN and OUT if no second (-O) max speed is provided.

    -O, --outBandwidth INTEGER
        Interface maximum speed in kilo/mega/giga/bits per second.  Applied to
        OUT traffic.  Uses the same units value given for -b.

    -P, --portchannel
	Checks if interface leaves Port-channel by compareing Port-channel speed to number.
	Enter Port-channel bandwidth total. Does not work with 10G interfaces.

    -r, --regexp
        Use regexp to match NAME in description OID

    -w, --warning STRING
        Bandwidth usage necessary to result in warning status (default: 85%)
	If --percent is set, then this will be interpreted as a % value
	If --nopercent is set, then this will be interpreted as a multiple of --units

    -c, --critical STRING
        Bandwidth usage necessary to result in critical status (default: 98%)
	If --percent is set, then this will be interpreted as a % value
	If --nopercent is set, then this will be interpreted as a multiple of --units

    -u, --units STRING
        (Bits)  kbps, Mbps, Gbps, Tbps, Pbps, Ebps (default Mbps)
        (Bytes) kBps, MBps, GBps, Tbps, PBps, EBps

    -d, --percent (default mode)
	If set, check will alarm based on percentage utilization of the interface.
	--warning and --critical levels are assumed to be percentages when --percent
        is set.

    -D, --nopercent
	If set, check will alarm based on actual utilization of the interface not percentage
	utilization. --warning and --critical levels may have to be changed from the default values.

EOU

  exit();
}

sub moreusage {

print STDERR << "EOF";

   # Without PNP4Nagios ########################################################################    
   Sample SNMPv2 commands
   to add to your Nagios / Icinga command file
   #############################################################################################    

   define command{
        command_name    check_iftraffic_percent
        command_line    \$USER1\$/check_iftraffic_multi --percent --hostname \$HOSTADDRESS\$ --community \$ARG1\$ --interface \$ARG4\$ --warning \$ARG2\$ --critical \$ARG3\$
        }

   define command{
        command_name    check_iftraffic_absolute
        command_line    \$USER1\$/check_iftraffic_multi --nopercent --hostname \$HOSTADDRESS\$ --community \$ARG1\$ --interface \$ARG4\$ --warning \$ARG2\$ --critical \$ARG3\$
        }

   # Without PNP4Nagios ########################################################################    
   Sample SNMPv2 checks 
   to add to the Nagios / Icinga file where your checks are located
   #############################################################################################    

   define service{
        use                             local-service			; Name of service template to use
        host_name                       device-name
        service_description             FA0/17-BANDWIDTH
        check_command                   check_iftraffic_percent!public!85!95!FastEthernet0/17
        }

    define service{
        use                             local-service		         ; Name of service template to use
        host_name                       device-name
        service_description             FA0/17-BANDWIDTH-DEFAULT
        check_command                   check_iftraffic_absolute!public!0.02:85!0.01:95!FastEthernet0/17
        }

   # With PNP4Nagios ###########################################################################    
   Sample SNMPv2 commands
   to add to your Nagios / Icinga command file
   #############################################################################################    

   define command{
        command_name    check_iftraffic_percent
        command_line    \$USER1\$/check_iftraffic_multi --percent --hostname \$HOSTADDRESS\$ --community \$ARG2\$ --interface \$ARG5\$ --warning \$ARG3\$ --critical \$ARG4\$
        }

   define command{
        command_name    check_iftraffic_absolute
        command_line    \$USER1\$/check_iftraffic_multi --nopercent --hostname \$HOSTADDRESS\$ --community \$ARG2\$ --interface \$ARG5\$ --warning \$ARG3\$ --critical \$ARG4\$
        }

   # With PNP4Nagios ###########################################################################    
   Sample SNMPv2 checks 
   to add to the Nagios / Icinga file where your checks are located
   #############################################################################################    

   Note:
	You will have to create separate configuration files in the PNP4Nagios "etc/check_commands"
	directory. Use the sample files that exist there as a guide. Create these configuration files:

	1) check_iftraffic_percent.cfg
	2) check_iftraffic_absolute.cfg

	Make sure the following directives are applied in each file

	   CUSTOM_TEMPLATE = 1
	   DATATYPE = GAUGE
	   RRD_STORAGE_TYPE = SINGLE
   Note:
        PNP4Nagios chart template file gauge_single_rrd_one_chart_per_rra.php must be placed in 
        your "pnp4nagios/share/templates/" directory

   Note:
	If your charts are not displayed it could be due to the fact that PNP4Nagios did not
	create a correctly configured .rrd and .xml file (AMPS, HUMIDITY,TEMPERATURE) in the 
	"pnp4nagios/var/perfdata/\$HOSTNAME\$/ directory because you restarted Nagios / Icinga 
	before you created the .cfg files above. The .rrd and .xml file for your check may have 
	to be deleted so that PNP4Nagios can recreate it automatically.

   #############################################################################################    

   define service{
        use                             local-service,srv-pnp         ; Name of service template to use
        host_name                       device-name
        service_description             FA0/17-BANDWIDTH
        check_command                   check_iftraffic_percent!gauge_single_rrd_one_chart_all_rras!public!85!95!FastEthernet0/17
        }

    define service{
        use                             local-service,srv-pnp         ; Name of service template to use
        host_name                       device-name
        service_description             FA0/17-BANDWIDTH-DEFAULT
        check_command                   check_iftraffic_absolute!gauge_single_rrd_one_chart_all_rras!public!0.02:85!0.01:95!FastEthernet0/17

EOF

   exit();

}



#!/usr/bin/perl
# 
############################## check_snmp_free_interfaces.pl ##############################
#										       #
# Description : Count the number of free interfaces more than X days on a switch       #
# Date : Apr 08 2011                                                                   #
# Author  : R. Lorenzini		                                               #
#										       #
########################################################################################
#
# Help : ./check_snmp_free_interfaces.pl -h
#

use Net::SNMP;
use Getopt::Long;

Getopt::Long::Configure('bundling');
GetOptions
    ("h"   => \$opt_h, "help"         => \$opt_h,
     "H=s" => \$opt_H, "hostname=s"     => \$opt_H,
     "C=s" => \$opt_C, "community=s"     => \$opt_C,
     "w=s" => \$opt_w, "warning=s"     => \$opt_w,
     "c=s" => \$opt_c, "warning=s"     => \$opt_c,
     "d=s" => \$opt_d, "delay=s"	     => \$opt_d,
     "e"   => \$opt_e, "extended"         => \$opt_e);
	

$script    = "check_snmp_free_interfaces.pl";
$script_version = "1.0";

# SNMP options
$version = "2c";
$timeout = 2;

$number_of_interfaces = 0;
@target_interface_index = (0);
@target_interface_descr = (0);
$target_interface = "ethernet";

$oid_ifnumber		= ".1.3.6.1.2.1.2.1.0";	
$oid_sysdescr 		= ".1.3.6.1.2.1.1.1.0";
$oid_ifdescr 		= ".1.3.6.1.2.1.2.2.1.2";	# need to append integer for specific interface
$oid_ifadminstatus	= ".1.3.6.1.2.1.2.2.1.7.";	# need to append integer for specific interface
$oid_ifoperstatus	= ".1.3.6.1.2.1.2.2.1.8.";	# need to append integer for specific interface
$oid_iflastchange	= ".1.3.6.1.2.1.2.2.1.9.";	# need to append integer for specific interface
$oid_uptime		= ".1.3.6.1.2.1.1.3.0";

$ifadminstatus		= "n/a";
$ifoperstatus		= "n/a";
$iflastchange		= "n/a";

$returnstring = "";

$warning = 5;
$critical = 2;
$community = "public"; 		# Default community string

if ($opt_h){
    usage();
    exit(0);
}
if ($opt_H){
    $hostname = $opt_H;
}
else {
    print "No specified hostname\n";
    usage();
    exit(0);
}
if ($opt_C){
    $community = $opt_C;
}
if ($opt_d){
    $delais = $opt_d;
}
else {
    print "No specified delay\n";
    usage();
    exit(0);
}
if ($opt_w){
    $warning = $opt_w;
}
if ($opt_c){
    $critical = $opt_c;
}

# Create the SNMP session

$version = "1";
($s, $e) = Net::SNMP->session(
   -community    =>  $community,
   -hostname     =>  $hostname,
   -version      =>  $version,
   -timeout      =>  $timeout,
);

if (!defined($s->get_request($oid_sysdescr))) {
  # If we can't connect using SNMPv1 lets try as SNMPv2
  $s->close();
  sleep 0.5;
  $version = "2c";
  ($s, $e) = Net::SNMP->session(
    -community    =>  $community,
    -hostname     =>  $hostname,
    -version      =>  $version,
    -timeout      =>  $timeout,
  );
  if (!defined($s->get_request($oid_sysdescr))) {
    print "Agent not responding, tried SNMP v1 and v2\n";
    exit(1);
  }
}


if (find_match() == 0){
    $nb_if_libre = 0;
    $count = 1;
    $res = $s->get_request(-varbindlist => [ $oid_uptime ],);
    @SysUptime = split(/\ /,$res->{$oid_uptime});
    if ( $SysUptime[0] < $delais ) {
        $status = 1;
                $returnstring = "Switch uptime lower than defined delay (Uptime is $SysUptime[0] days)";
    }
    else {
    	while ($count < ($#target_interface_index + 1)) {
		if (probe_interface() == 1) {
			$nb_if_libre = $nb_if_libre + 1;
		}
		$count = $count + 1 ;
    	}
    	if ($nb_if_libre > $warning) {
		$status = 0;
		$returnstring = "$nb_if_libre free interfaces on this switch | free_ports=$nb_if_libre";
    	}
   	else {
		if ($nb_if_libre > $critical) {
			$status = 1;
			$returnstring = "$nb_if_libre free interfaces on this switch | free_ports=$nb_if_libre";
    		}
		else {
			$status = 2;
			$returnstring = "$nb_if_libre free interfaces on this switch | free_ports=$nb_if_libre";
		}
    	}
    }
}
else {
    $status = 2;
    print "Interface $target_interface not found on device $hostname\n";
    exit $status;
}

# Close the session
$s->close();

if($status == 0){
    print "OK - $returnstring\n";
    exit $status;
}
elsif($status == 1){
    print "Warning - $returnstring\n";
    exit $status;
}
elsif($status == 2){
    print "CRITICAL - $returnstring\n";
    exit $status;
}
else{
    print "Plugin error! SNMP status unknown\n";
    exit $status;
}

exit 2;


#################################################
# Finds match for supplied interface name
#################################################

sub find_match {

    if (!defined($s->get_request($oid_ifnumber))) {
        if (!defined($s->get_request($oid_sysdescr))) {
            print "Status is a Warning Level - SNMP agent not responding\n";
            exit 1;
        }
        else {
            print "Status is a Warning Level - SNMP OID does not exist\n";
            exit 1;
        }
    }
    
    if (!defined($s->get_table($oid_ifdescr))){
    }
    else {
	foreach ($s->var_bind_names()) {
            $temp_interface_descr = $s->var_bind_list()->{$_};
	    if (index(lc($temp_interface_descr),lc($target_interface)) != -1) {
		@res = split(/\./,$_);
		push (@target_interface_index, $res[$#res]);
		push(@target_interface_descr,$temp_interface_descr);
	    }
        }
    }
    if ($#target_interface_index == 0){
        return 1;
    }
    else {
        return 0;
    }
}

####################################################################
# Gathers data about target interface                              #
####################################################################


sub probe_interface {

    $oid_temp = $oid_ifadminstatus . $target_interface_index[$count];    
    if (!defined($s->get_request($oid_temp))) {
    }
    else {
        foreach ($s->var_bind_names()) {
            $ifadminstatus = $s->var_bind_list()->{$_};
        }
    }
    ############################
        
    $oid_temp = $oid_ifoperstatus . $target_interface_index[$count];    
    if (!defined($s->get_request($oid_temp))) {
    }
    else {
        foreach ($s->var_bind_names()) {
            $ifoperstatus = $s->var_bind_list()->{$_};
	}
    }
    ############################
        
    $oid_temp = $oid_iflastchange . $target_interface_index[$count];    
    if (!defined($s->get_request($oid_temp))) {
    }
    else {
        foreach ($s->var_bind_names()) {
            $iflastchange = $s->var_bind_list()->{$_};
        }
    }
    ############################

    if (($ifadminstatus eq "2") || ($ifoperstatus eq "2")) {
	@lastchange = split(/\ /,$iflastchange);
	if ($lastchange[1] eq "days,") {
		$res = $SysUptime[0] - $lastchange[0];
	}
	else {
		$res = $SysUptime[0];
	}
	if ($res > $delais)
	  {
		if ($opt_e) {
			print "Interface ",$target_interface_descr[$count]," is free for ",$res," days.\n";
		}
		return 1;
	} 
	else {
		return 0;
		
	}
    }
    else {
	return 0;
    }

}

####################################################################
# help and usage information                                       #
####################################################################

sub usage {
    print << "USAGE";
--------------------------------------------------------------------
$script v$script_version

Return the number of interfaces down for more than X days.. 

Usage: $script -H <hostname> -c <community> [...]

Options: -H 	Hostname or IP address
         -C 	Community (default is public)
	 -d 	Number of days since interfaces are down
	 -w	Warning free interfaces - default 5
	 -c	Critical free interfaces - default 2
	 -e     Extended view
	
USAGE
     exit 1;
}



####################################################################
# Appends string to existing $returnstring                         #
####################################################################

sub append {
    my $appendstring =    @_[0];    
    $returnstring = "$returnstring$appendstring";
}




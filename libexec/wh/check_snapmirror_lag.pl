#! /usr/bin/perl -w


use strict;
use Getopt::Long;
use vars qw($opt_V $opt_h $opt_w $opt_c $opt_H $opt_C $opt_v $nr $B $B1 $PROGNAME);
use lib "/usr/local/nagios/libexec"  ;
use utils qw(%ERRORS &print_revision &support &usage);

$PROGNAME = "check_lagtime";

sub print_help ();
sub print_usage ();

$ENV{'PATH'}='';
$ENV{'BASH_ENV'}=''; 
$ENV{'ENV'}='';

Getopt::Long::Configure('bundling');
GetOptions
	("V"   => \$opt_V, "version"    => \$opt_V,
	 "h"   => \$opt_h, "help"       => \$opt_h,
	 "w=s" => \$opt_w, "warning=s"  => \$opt_w,
	 "c=s" => \$opt_c, "critical=s" => \$opt_c,
	 "H=s" => \$opt_H, "hostname=s" => \$opt_H,
	 "v=s" => \$opt_v, "volume=s" => \$opt_v,
	 "C=s" => \$opt_C, "community=s" => \$opt_C);

if ($opt_V) {
	print_revision($PROGNAME,'$Revision: 0.1 $');
	exit $ERRORS{'OK'};
}


if ($opt_h) {print_help(); exit $ERRORS{'OK'};}

($opt_H) || usage("Host name/address not specified\n");
my $host = $1 if ($opt_H =~ /([-.A-Za-z0-9]+)/);
($host) || usage("Invalid host: $opt_H\n");

($opt_v) || usage("Volume name/address not specified\n");
my $vol = $1 if ($opt_v =~ /([-.A-Za-z0-9_]+)/);
($vol) || usage("Invalid host: $opt_v\n");

($opt_w) || usage("Warning threshold not specified\n");
my $warning = $1 if ($opt_w =~ /([0-9]+)+/);
($warning) || usage("Invalid warning threshold: $opt_w\n");

($opt_c) || usage("Critical threshold not specified\n");
my $critical = $1 if ($opt_c =~ /([0-9]+)/);
($critical) || usage("Invalid critical threshold: $opt_c\n");

($opt_C) || ($opt_C = "public") ;

my $nr=0;
$nr=`/usr/bin/snmpwalk -v 2c -c $opt_C $host .1.3.6.1.4.1.789.1.9.20.1.2 | /bin/grep $vol| /bin/awk -F' ' '{print \$1}' | /bin/awk -F. '{print \$NF}' `;
$B=`/usr/bin/snmpget -v 2c -c $opt_C $host .1.3.6.1.4.1.789.1.9.20.1.6.$nr`;
my @test=split(/Timeticks:/,$B);
$B=$test[1];

my @min=split(/\(/,$B);
$B1=$min[1];
my @min2=split(/\)/,$B1);
$B1=$min2[0];
$B1=$B1/100;



if ($B1>$critical){ print "CRITICAL - Snapmirror Lag Time for $vol: $B"; exit $ERRORS{'CRITICAL'} };
if ($B1>$warning){ print "WARNING - Snapmirror Lag Time for $vol: $B"; exit $ERRORS{'WARNING'} };
print "OK - Snapmirror Lag Time for $vol: $B"; exit $ERRORS{'OK'};


sub print_usage () {
	print "Usage: $PROGNAME -H <host> [-C community] -w <warn> -c <crit>\n";
}

sub print_help () {
	print_revision($PROGNAME,'$Revision: 0.2 $');
	print "Copyright (c) 2009 Rob Hassing

This plugin reports the Snapmirror lagtime of a Netapp Storage device

";
	print_usage();
	print "
-H, --hostname=HOST
   Name or IP address of host to check
-v, --volume=Volume
   Name of the volume to check
-C, --community=community
   SNMPv1 community (default public)
-w, --warning=INTEGER
   Lag time in minutes above which a WARNING status will result
-c, --critical=INTEGER
   Lag time in minutes above which a CRITICAL status will result

";
	support();
}

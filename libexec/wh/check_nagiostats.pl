#!/usr/bin/perl

###################################################################
#
# VIM SETTINGS
# ts=3
# sw=3
#
# #################################################################

###################################################################
#	check_nagiostats - check nagios performance data
#
#	License Information:
#	This program is free software; you can redistribute it and/or modify
#	it under the terms of the GNU General Public License as published by
#	the Free Software Foundation; either version 2 of the License, or
#	(at your option) any later version.
#
#	This program is distributed in the hope that it will be useful,
#	but WITHOUT ANY WARRANTY; without even the implied warranty of
#	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#	GNU General Public License for more details.
#
#	To get a copy of the GNU General Public License, write to the Free
#	Software Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
#
####################################################################

use strict;
use lib "/usr/local/nagios/libexec";
use utils qw(%ERRORS);
use Getopt::Long;

####################################################################
# var declaration

my $version="20121031";
my $file="/usr/local/nagios/var/status.dat";
my $help;
my $verbose=0;
my $value;
my $warning;
my $critical;
my $service_latency;
my $host_latency;
my $max_host_latency;
my $min_host_latency;
my $avg_host_latency;
my $hostcount;
my $servicecount;
my $text;
my $perfdat;
my $unit="sec";

####################################################################
# get options
#

GetOptions(
	"h"			=>	\$help,					"help"					=>	\$help,
	"f:s"			=>	\$file,					"file:s"					=>	\$file,
	"s"			=>	\$service_latency,	"service_latency"		=>	\$service_latency,
	"o"			=>	\$host_latency,		"host_latency"			=>	\$host_latency,
	"hostcount"	=>	\$hostcount,			"servicecount"			=>	\$servicecount,
	"w:i"			=>	\$warning,				"warning:i"				=>	\$warning,
	"c:i"			=>	\$critical,				"critical:i"			=>	\$critical,
	"v"			=>	\$verbose,				"verbose"				=>	\$verbose);

####################################################################
# action
#

if ($service_latency && $warning && $critical){
	check_s_latency();
}
elsif ($host_latency && $warning && $critical){
	check_h_latency();
}
elsif ($hostcount){
	check_h_count();
}
elsif ($servicecount){
	check_s_count();
}
else{
	print_help();
}

if($verbose){
	print "\nstatus.dat location: $file\n";
}


###################################################################
# funktions
#

sub check_s_latency(){
	my ($min_service_name, $max_service_name, $line, $value1, $sum, $max_service_latency, $min_service_latency, $avg_service_latency, @values, $long_service_output);
	my $i=0;

	open (FILE, $file)
		or die $!;
	$/ = "";

	foreach $line (<FILE>){
		if ($line =~ /servicestatus/){
			@values=split(/=/, $line);
			foreach $value(@values){
				if($value=~/check_latency/){
					($value,$value1)=split(/\n/, @values[13]);

					if(!$max_service_latency){
						$max_service_latency=$value;
					}
					if(!$min_service_latency){
						$min_service_latency=$value;
					}
					if(!$avg_service_latency){
						$avg_service_latency=$value;
					}

# catch max time of latency:
					if($max_service_latency<$value){
						$max_service_latency=$value;
						($max_service_name, $value1)=split(/\n/, @values[2]);

						if($verbose){
							print "max_service_latency: $max_service_latency\n";
							print "max_service_name: $max_service_name\n";
						}

					}

# catch min time of latency:
					if($min_service_latency>$value){
						$min_service_latency=$value;
						($min_service_name, $value1)=split(/\n/, @values[2]);

						if($verbose){
							print "min_service_latency: $min_service_latency\n";
							print "min_service_name: $min_service_name\n";
						}

					}

# calculate avg time of latency:
					$sum+=$value;
					$i++;
				}
			}
		}
	}

	close (FILE);
	$avg_service_latency=($sum/$i);

# filling vars for print
$avg_service_latency=sprintf"%.3f", $avg_service_latency;
$text=("max latency: $max_service_name=$max_service_latency\navg latency: $avg_service_latency\nmin latency: $min_service_name=$min_service_latency");
$perfdat=("max=${max_service_latency}s;$warning;$critical avg=${avg_service_latency}s;$warning;$critical; min=${min_service_latency}s;$warning;$critical");
$value=$max_service_latency;
}

sub check_h_latency(){
	my ($line, $value1, $sum, $max_host_name, $min_host_name, $max_host_latency, $min_host_latency, $avg_host_latency, @values);
	my $i=1;

	open (FILE, $file)
		or die $!;
	$/ = "";

	foreach $line(<FILE>){
		if($line=~/hoststatus/){
			@values=split(/=/, $line);
			foreach $value(@values){
				if($value=~/check_latency/){
					($value,$value1)=split(/\n/, @values[12]);

					if(!$max_host_latency){
						$max_host_latency=$value;
					}
					if(!$min_host_latency){
						$min_host_latency=$value;
					}
					if(!$avg_host_latency){
						$avg_host_latency=$value;
					}

# catch max time of latency:
					if($max_host_latency<$value){
						$max_host_latency=$value;
						($max_host_name, $value1)=split(/\n/, @values[1]);

						if($verbose){
							print "max_host_latency: $max_host_latency\n";
						}

					}

# catch min time of latency:
					if($min_host_latency>$value){
						$min_host_latency=$value;
						($min_host_name, $value1)=split(/\n/, @values[1]);

						if($verbose){
							print "min_host_latency: $min_host_latency\n";
						}

					}

# calculate avg time of latency:
					$sum+=$value;
					$i++;
				}
			}
		}
	}

	close (FILE);
	$avg_host_latency=($sum/$i);

# filling vars for print
$avg_host_latency=sprintf"%.3f", $avg_host_latency;
$text=("max latency: $max_host_name=$max_host_latency\navg latency: $avg_host_latency\nmin latency: $min_host_name=$min_host_latency");
$perfdat=("max=${max_host_latency}s;$warning;$critical avg=${avg_host_latency}s;$warning;$critical min=${min_host_latency}s;$warning;$critical");
$value=$max_host_latency;
}

sub check_h_count(){
	my $line;
	my $counter_host_checks=0;

	open (FILE, $file)
		or die $!;
	$/ = "";

	foreach $line(<FILE>){
		if($line=~/hoststatus/){
			$counter_host_checks++;
		}
	}

	close (FILE);

# filling vars for print
$text=("Host Checks: $counter_host_checks");
$perfdat=("count=$counter_host_checks");

# this ugly thing is needed to return OK:
$warning=2;
$critical=2;
$value=1;
}

sub check_s_count(){
	my $line;
	my $counter_service_checks=0;

	open (FILE, $file)
		or die $!;
	$/ = "";

	foreach $line(<FILE>){
		if($line=~/servicestatus/){
			$counter_service_checks++;
		}
	}

	close (FILE);

# filling vars for print
$text=("Service Checks: $counter_service_checks");
$perfdat=("count=$counter_service_checks");

# this ugly thing is needed to return OK:
$warning=2;
$critical=2;
$value=1;
}

sub print_help(){
	print "\n\nVersion: $version\n";
	print "Autor: Daniel Bierstedt [daniel.bierstedt\@gmail.com]\n\n";
	print "This plugin checks nagios performance data by parsing the nagios\n";
	print "status.dat file, which is expected to be located at\n";
	print "\"/usr/local/nagios/var/status.dat\". Only service check latency and host check\n";
	print "latency are implemented ATM. I plan to do more checks in future,\n";
	print "please send bug reports or feature requests by mail.\n";
	print "\n\n";
	print "options:\n";
	print "-s|--service_latency\n";
	print "-o|--host_latency\n";
	print "-w|--warning\n";
	print "-c|--critical\n";
	print "-f|--file\n";
	print "--hostcount\n";
	print "--servicecount\n";
	print "-h|--help:\t\tprint help\n";
	print "-v|--verbose:\t\tprint verbose (testing) output\n";
	print "Examples:\n";
	print "To check host latency: check_nagiostats -o -w 200 -c 500\n";
	print "To check service latency: check_nagiostats -s -w 200 -c 500\n";
	print "Attention: warning and critical always checks max_latency, not\n";
	print "avg or min. Does it make sense to send out alarms based on avg\n";
	print "then on max?\n\n";
	print "To count checked services: check_nagiostats --servicecount (there is no warning or critical)\n";
	print "To count checked hosts: check_nagiostats --hostcount (there is no warning or critical)\n";
}

#
###########################################################################

if($value){
	if($value>=$critical){
		print "$text|$perfdat";
		exit $ERRORS{'CRITICAL'};
	}
	elsif($value>=$warning){
		print "$text|$perfdat";
		exit $ERRORS{'WARNING'};
	}
	elsif($value<$warning){
		print "$text|$perfdat";
		exit $ERRORS{'OK'};
	}
	else{
		print "\noutput unknown. DO SOMETHING!\n\n";
		exit $ERRORS{'UNKNOWN'};
	}
}


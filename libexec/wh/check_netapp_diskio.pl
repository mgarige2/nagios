#!/usr/bin/perl -w

# Written by liwei on Oct 10,2008 modified by Emmanuel Doguet for
#
# - Netapp filer adapt (64 bits with Low & High counter)
# - Cleaning
# - Add Centreon Perfdatas (units)

use strict;
use Net::SNMP;
use Getopt::Long;

#use lib "/app/nagios/libexec";
use utils qw(%ERRORS $TIMEOUT);

my $o_host =    undef;          # hostname
my $o_community = undef;        # community
my $o_port =    161;            # port
my $o_warn =    undef;          # warning limit
my $o_crit=     undef;          # critical limit
my $o_timeout= 10;
my $exit_code = undef;
my $o_type=undef;
my $output=undef;
my $o_perf= undef;

my %oids = (
                  'diskReadHighBytes'               => ".1.3.6.1.4.1.789.1.2.2.15.0",
                  'diskReadLowBytes'                => ".1.3.6.1.4.1.789.1.2.2.16.0",
                  'diskWriteHighBytes'            => ".1.3.6.1.4.1.789.1.2.2.17.0",
                  'diskWriteLowBytes'               => ".1.3.6.1.4.1.789.1.2.2.18.0",


);


my @oidlist=($oids{diskReadHighBytes},$oids{diskReadLowBytes},$oids{diskWriteHighBytes},$oids{diskWriteLowBytes});

sub check_options {
    Getopt::Long::Configure ("bundling");
    GetOptions(
        'H:s'   => \$o_host,            'hostname:s'    => \$o_host,
        'p:i'   => \$o_port,            'port:i'        => \$o_port,
        'C:s'   => \$o_community,       'community:s'   => \$o_community,
        'c:s'   => \$o_crit,            'critical:s'    => \$o_crit,
        'w:s'   => \$o_warn,            'warn:s'        => \$o_warn,
#       'T:s'   => \$o_type,
    );

}

########## MAIN #######

check_options();

# Connect to host
my ($session,$error);
         ($session, $error) = Net::SNMP->session(
                -hostname  => $o_host,
                -community => $o_community,
                -port      => $o_port,
                -timeout   => $o_timeout
          );

if (!defined($session)) {
   printf("ERROR: %s.\n", $error);
   exit $ERRORS{"UNKNOWN"};
}

my $resultat=undef;
# Get rid of UTF8 translation in case of accentuated caracters (thanks to Dimo Velev).
$session->translate(Net::SNMP->TRANSLATE_NONE);

  if (Net::SNMP->VERSION < 4) {
    $resultat = $session->get_request(@oidlist);
  } else {
    $resultat = $session->get_request(-varbindlist  => \@oidlist);
  }


if (!defined($resultat)) {
   printf("ERROR: Description/Type table : %s.\n", $session->error);
   $session->close;
   exit $ERRORS{"UNKNOWN"};
}

$session->close;

my $new_read_bytes;
my $new_write_bytes;
my $left_shift= 2**32;
my $last_read_bytes = 0;
my $last_write_bytes  = 0;
my $row ;
my  $last_check_time ;
my  $update_time;
my @last_values=undef;

my $flg_created = 0;

$new_read_bytes= $$resultat{$oids{diskReadHighBytes}} *  $left_shift  +  $$resultat{$oids{diskReadLowBytes}};
$new_write_bytes= $$resultat{$oids{diskWriteHighBytes}} * $left_shift  +  $$resultat{$oids{diskWriteLowBytes}};

if (-e "/var/lib/centreon/centplugins/traffic_disk_".$o_host) {
    open(FILE,"<"."/var/lib/centreon/centplugins/traffic_disk_".$o_host);
    while($row = <FILE>){
                @last_values = split(":",$row);
                $last_check_time = $last_values[0];
                $last_read_bytes = $last_values[1];
                $last_write_bytes = $last_values[2];
                $flg_created = 1;
    }
    close(FILE);
} else {
    $flg_created = 0;
}

$update_time = time();

unless (open(FILE,">"."/var/lib/centreon/centplugins/traffic_disk_".$o_host)){
    print "Check mod for temporary file : /var/lib/centreon/centplugins/traffic_disk_".$o_host. " !\n";
    exit $ERRORS{"UNKNOWN"};
}
print FILE "$update_time:$new_read_bytes:$new_write_bytes";
close(FILE);

if ($flg_created == 0){
    print "First execution : Buffer in creation.... \n";
    exit($ERRORS{"UNKNOWN"});
}



my $read_diff=$new_read_bytes - $last_read_bytes;
$read_diff=$new_read_bytes if ($read_diff < 0);

my $write_diff=$new_write_bytes - $last_write_bytes;
$write_diff=$new_write_bytes if ($write_diff < 0);

my $time_diff=$update_time - $last_check_time;
$time_diff=$update_time if ($time_diff < 0);

my $read_rate = $read_diff / ( $time_diff );
my $write_rate = $write_diff / ( $time_diff );


printf("Disk read : %.2f KB/s , Disk write : %.2f KB/s ", $read_rate/1024, $write_rate/1024);
#printf("|disk_read=".$read_rate."Bytes/s disk_write=".$write_rate."Bytes/s\n");
printf("|TOTAL-Read=".$read_rate." TOTAL_Write=".$write_rate."\n");


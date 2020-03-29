#!/usr/bin/perl -w
use strict;
use JMX::Jmx4Perl;
use JMX::Jmx4Perl::Request;   # Type constants are exported here
use Getopt::Std;
use Data::Dumper;

# perl scritp for Nagios. Used to check the current failed queue count
# Chris Krelle 08.29.2011
# NOTE: host being checked MUST have the Jolokia javaagent jar

#Setup
my %Opts;
getopts('H:w:c:B:',\%Opts);

my $JolokiaPort = 8778;
my $JolokiaPath = "/jolokia";
my $Attribute = "MemoryPercentUsage";
my $ResponseValue = 0;
my $ReturnMsg = "";
my $ExitLevel = 0;

my $HostTmpName;
my @SplitName ;
my $BrokerName;
my $QueueName;
my @QueueNames;
my $Queues;
my @SplitVar;
my $TmpQueName;
my $TmpWorkingQueName;
my $ChkResponse;
my $FailedChkCVar;
my $Mbean ;
my $CntChkRequest;
my $Loops;
my $Counter;

# Now for some basic checks
if ( !$Opts{H} && $ExitLevel == 0 )
{
    $ReturnMsg="No Host to check provided.";
    $ExitLevel=3;
}
if ( !$Opts{w} && $ExitLevel == 0 )
{
    $ReturnMsg="No Warn Level provided.";
    $ExitLevel=3;
}
if ( !$Opts{c} && $ExitLevel == 0 )
{
    $ReturnMsg="No Critial Level provided.";
    $ExitLevel=3;
}
if ( $Opts{w} >= $Opts{c} && $ExitLevel == 0 )
{
    $ReturnMsg="Warn Level can not be equal to or greater then Critical Level.";
    $ExitLevel=3;
}
# if we reach this point and $ExitLevel is still zero lets see if we can get the broker name for the activeMq bean
if ( $ExitLevel == 0 )
{
	#$HostTmpName = $Opts{H};
	#@SplitName = split('\.', $HostTmpName);
	#$BrokerName = "$SplitName[0].$SplitName[1]";
	$BrokerName = $Opts{B};
	$Mbean = "org.apache.activemq:BrokerName=$BrokerName,Type=Broker";
	# connect to Jolokia running on the server to be checked
	my $jmx = new JMX::Jmx4Perl(url => "http://$Opts{H}:$JolokiaPort$JolokiaPath", verbose => 0);
	# Query the server for the current number of connections as reported by the RL_Api
	my $request = new JMX::Jmx4Perl::Request({type => READ,
		mbean=> "$Mbean",
		attribute => "$Attribute"});
	# Get the Response from Jolokia
	my $response = $jmx->request($request);
	$ChkResponse = $response->value();

		if ( $ChkResponse >= $Opts{c} )
		{
			# we are over the critical threshold
			$ExitLevel = 2;
			$ReturnMsg="Critical: Memory usage >= $Opts{c} %.";
		}
		if ( $ChkResponse >= $Opts{w} && $ExitLevel == 0)
		{
			# we are over the warning threshold
			$ExitLevel = 1;
			$ReturnMsg="Warning: Memory usage >= $Opts{w} %.";
		}

}
# if $ExitLevel Not set up to this point then all should be ok
if ( $ExitLevel == 0 )
{
    $ReturnMsg="OK : Memory usage at $ChkResponse %";
}
print "$ReturnMsg\n";
exit $ExitLevel;


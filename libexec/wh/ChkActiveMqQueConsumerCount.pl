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
getopts('H:c:B:',\%Opts);

my $JolokiaPort = 8778;
my $JolokiaPath = "/jolokia";
my $Attribute = "Queues";
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
my $CntChkResponse;
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
if ( !$Opts{c} && $ExitLevel == 0 )
{
    $ReturnMsg="No Critial Level provided.";
    $ExitLevel=3;
}
if ( !$Opts{B} && $ExitLevel == 0 )
{
    $ReturnMsg="BrokerName not provided.";
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
	@QueueNames = $response->value();
	$Queues =  Dumper(@QueueNames);
	$Loops = () = $Queues=~ /Destination=/g;
	$Counter=-1;
	foreach (1..$Loops)
	{
		++$Counter;
		$TmpQueName = Dumper($QueueNames[0][$Counter]);

		@SplitName=split( '=>', $TmpQueName);
		$TmpWorkingQueName = substr($SplitName[1],2,-13);
		$FailedChkCVar = () = $TmpWorkingQueName =~ /=NotificationSystem./g;
		if ( $FailedChkCVar > 0 && $ExitLevel == 0 )
		{
			# now that we found a notification queue lets see if there
			# are any listeners in it.
			$Mbean = $TmpWorkingQueName;
			$Attribute = "ConsumerCount";
			$CntChkRequest = new JMX::Jmx4Perl::Request({type => READ,
				mbean=> "$Mbean",
				attribute => "$Attribute" });
		
			$CntChkResponse = $jmx->request($CntChkRequest);
			if ( $CntChkResponse->value() > 0 )
			{
				# ok we have listeners.
				# Lets see if we need to warn or set a critical alert
				if ( $CntChkResponse->value() < $Opts{c} && $ExitLevel == 0)
				{
					# we are over the critical threshold
					$ExitLevel = 2;
					$ReturnMsg="Critical: There are not at least $Opts{c} Consumers for queue $TmpWorkingQueName.";
				}
			}
		}
	}
}
# if $ExitLevel Not set up to this point then all should be ok
if ( $ExitLevel == 0 )
{
    $ReturnMsg="OK";
}
print "$ReturnMsg\n";
exit $ExitLevel;


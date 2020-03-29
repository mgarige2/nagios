#!/usr/bin/perl -w
   use strict;
   use JMX::Jmx4Perl;
   use JMX::Jmx4Perl::Request;   # Type constants are exported here
   use Getopt::Std;
# perl scritp for Nagios. Used to check the current connection count to rl_api
# Chris Krelle 08.05.2011
# NOTE: host being checked MUST have the Jolokia javaagent jar

my %Opts;
getopts('H:w:c:',\%Opts);

my $JolokiaPort = 8778;
my $JolokiaPath = "/jolokia";
my $Mbean = "com.reachlocal.api.cassandra:type=PooledCassandraClientProvider-PooledCassandraClientProvider";
my $Attribute = "NumClients";
my $ResponseValue = 0;
my $ReturnMsg = "";
my $ExitLevel = 0;
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

if ( $Opts{w} >= $Opts{c} )
{
    $ReturnMsg="Warn Level can not be equal to or greater then Critical Level.";
    $ExitLevel=3;
}

#   my $jmx = new JMX::Jmx4Perl(url => "http://dapp1002.dyn.wh.reachlocal.com:8778/jolokia", verbose => 0);
if ( $ExitLevel == 0 )
{
   # connect to Jolokia running on the server to be checked
   my $jmx = new JMX::Jmx4Perl(url => "http://$Opts{H}:$JolokiaPort$JolokiaPath", verbose => 0);
   # Query the server for the current number of connections as reported by the RL_Api
   my $request = new JMX::Jmx4Perl::Request({type => READ,
        mbean=> "$Mbean",
        attribute => "$Attribute"
   });
   # Get the Response
   my $response = $jmx->request($request);
   $ResponseValue = $response->value();
   if ( $ResponseValue )
   {
        if ( $ResponseValue =~ /^[+-]?\d+$/ ) {
            # looks like a good response.
        } else {
            # some thing is not right we did not get a number back
            $ExitLevel=3;
            $ReturnMsg="Api returned \"$ResponseValue\" which is not a number.";
       }
   } else {
       if ( $ResponseValue == defined($ResponseValue) )
       {
           # looks like we got a null value back
           $ReturnMsg="Api returned a NULL value.($ResponseValue)";
           $ExitLevel=3;
       }
   }
}

# now check to see if we need to set any alerts
# Start with Critical
if ( $ExitLevel == 0 )
{
    if ( $ResponseValue >= $Opts{c} )
    {
        $ReturnMsg="Critical:Api reports $ResponseValue connection(s)";
        $ExitLevel=2;
    }
}
# Then Check Warn level
if ( $ExitLevel == 0 )
{
    if ( $ResponseValue >= $Opts{w} )
    {
        $ReturnMsg="Warn:Api reports $ResponseValue connection(s)";
        $ExitLevel=1;
    }
}
# if ExitLevel is 0 then all should be OK
if ( $ExitLevel == 0 )
{
    $ReturnMsg="OK - $ResponseValue current connection(s)";
}
#Return results back to Nagios
print "$ReturnMsg\n";
exit $ExitLevel;

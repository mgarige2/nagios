#!/usr/bin/perl
# file: uploadafile.pl
# call me like this:
# uploadafile.pl --url="https://instance.service-now.com/sys_import.do?sysparm_import_set_tablename=dloo_test&sysparm_transform_after_load=true"
# --uploadfile=/Users/davidloo/Desktop/test_files/test_users.csv
#
# the "sysparm_transform_after_load=true" parameter instructs the import set to transform immediately after loading
#
#use strict;
use LWP::UserAgent;
use HTTP::Request::Common;
use Getopt::Long;
use File::Basename;

my ( $o_url, $o_fqn );
GetOptions(
    "url=s"        => \$o_url,
    "uploadfile=s" => \$o_fqn,
);

# mandatory arguments: url
&usage unless ( $o_url && $o_fqn );

my $url   = $o_url;
my $fname = $o_fqn;

BEGIN { $ENV{PERL_LWP_SSL_VERIFY_HOSTNAME} = 0 }
# put timeouts, proxy etc into the useragent if needed
my $ua  = LWP::UserAgent->new(
	ssl_opts => {
		verify_hostname => 0,
		SSL_VERIFY_MODE => SSL_VERIFY_NONE
		});

# setup basic authentication credentials
$ua->credentials(
  'reachlocal.service-now.com:443',
  'Service-now',
  'cmdbservice' => '!mp0rtCI'
);

my $req = POST $url, Content_Type => 'form-data',
        Content      => [
                submit => 1,
                upfile =>  [ $fname ]
        ];
my $response = $ua->request($req);



if ($response->is_success()) {
    print "OK: ", $response->content;
} else {
    print $response->as_string;
}

exit;

sub usage {
        printf "usage:&nbsp;%s --url=%s --uploadfile=%s\\n",
                basename($0),'https://....','c:/data/test.csv';
        exit
}


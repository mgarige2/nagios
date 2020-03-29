#!/usr/bin/perl

# Copyright (c) 2012 Jason Hancock <jsnbyh@gmail.com>
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is furnished
# to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.
#
# This file is part of the nagios-cpu bundle that can be found
# at https://github.com/jasonhancock/nagios-html-email

use strict;
use warnings;

use MIME::Lite;
use URI::Escape;

my $nagios_url = $ARGV[0] || die('You must pass the url to your nagios installation as the first argument'); 

my $color_red    = '#FF8080';
my $color_green  = '#80FF80';
my $color_yellow = '#FFFF80';
my $color_orange = '#FF9900';
my $color_even   = '#C9C9C9';
my $color_odd    = '#EAEAEA';

my %colors=(
    'PROBLEM'         => $color_red,
    'RECOVERY'        => $color_green,
    'ACKNOWLEDGEMENT' => $color_yellow,
    'CRITICAL'        => $color_red,
    'WARNING'         => $color_yellow,
    'OK'              => $color_green,
    'UNKNOWN'         => $color_orange,
    'UP'              => $color_green,
    'DOWN'            => $color_red,
    'UNREACHABLE'     => $color_orange,
);

my %allowed_types = (
    'PROBLEM'         => 1,
    'RECOVERY'        => 1,
    'ACKNOWLEDGEMENT' => 1
);

exit if !defined($allowed_types{$ENV{NAGIOS_NOTIFICATIONTYPE}});
#print "$ENV{NAGIOS_SERVICEATTEMPT}";
my $type = $ENV{NAGIOS_SERVICEATTEMPT} ? 'service' : 'host';
#my $type = 'service';
#print "$type";

my $font = 'helvetica, arial';
my $style_th_even = '"background-color: #c9c9c9; font-weight: bold; width: 130px;"';
my $style_th_odd  = '"background-color: #eaeaea; font-weight: bold; width: 130px;"';
my $style_td_even = '"background-color: #c9c9c9;"';
my $style_td_odd  = '"background-color: #eaeaea;"';
my $style_table   = "\"font-family: $font; font-size: 12px;\"";

my $style_state = sprintf('"background-color: %s"', 
    $type eq 'service'
    ? $colors{$ENV{NAGIOS_SERVICESTATE}}
    : $colors{$ENV{NAGIOS_HOSTSTATE}}
);

my $subject = sprintf('** %s %s Alert: %s is %s **',
    $ENV{NAGIOS_NOTIFICATIONTYPE},
    ucfirst($type),
    $type eq 'service' ? $ENV{NAGIOS_HOSTNAME} . '/' . $ENV{NAGIOS_SERVICEDESC} : $ENV{NAGIOS_HOSTNAME},
    $type eq 'service' ? $ENV{NAGIOS_SERVICESTATE} : $ENV{NAGIOS_HOSTSTATE}
);

my $host_url = sprintf('%s/cgi-bin/status.cgi?navbarsearch=1&host=%s',
    $nagios_url,
    $ENV{NAGIOS_HOSTNAME}
);
my @rows;
my $notification_title;
print "$type";

if($type eq 'service') {
    my $service_url = sprintf('%s/cgi-bin/extinfo.cgi?type=2&host=%s&service=%s',
        $nagios_url,
        $ENV{NAGIOS_HOSTNAME},
        uri_escape($ENV{NAGIOS_SERVICEDESC})
    );

    $notification_title = 'Nagios Service Notification';

    @rows = (
        { 
            'title' => 'Service State:',
            'data'  => $ENV{NAGIOS_SERVICESTATE},
            'style' => $style_state,
        },
        { 
            'title' => 'Notification Type:',
            'data'  => $ENV{NAGIOS_NOTIFICATIONTYPE},
        },
        {
            'title' => 'Hostname:',
            'data'  => "<a href=\"$host_url\">$ENV{NAGIOS_HOSTNAME}</a>",
        },
        {
            'title' => 'Service Name:',
            'data'  => "<a href=\"$service_url\">$ENV{NAGIOS_SERVICEDESC}</a>",
        },
        {
            'title' => 'Service Data:',
            'data'  => $ENV{NAGIOS_SERVICEOUTPUT},
        },
        {
            'title' => 'IP Address:',
            'data'  => $ENV{NAGIOS_HOSTADDRESS},
        },
        {
            'title' => 'Hostgroups:',
            'data'  => $ENV{NAGIOS_HOSTGROUPNAME},
        },
        {
            'title' => 'Event Time:',
            'data'  => $ENV{NAGIOS_SHORTDATETIME},
        },
    );
} else {
    $notification_title = 'Nagios Host Notification';

    @rows = (
        {
            'title' => 'Host State:',
            'data'  => $ENV{NAGIOS_HOSTSTATE},
            'style' => $style_state,
        },
        {
            'title' => 'Notification Type:',
            'data'  => $ENV{NAGIOS_NOTIFICATIONTYPE},
        },
        {
            'title' => 'Hostname:',
            'data'  => "<a href=\"$host_url\">$ENV{NAGIOS_HOSTNAME}</a>",
        },
        {
            'title' => 'Host Data:',
            'data'  => $ENV{NAGIOS_HOSTOUTPUT},
        },
        {
            'title' => 'IP Address:',
            'data'  => $ENV{NAGIOS_HOSTADDRESS},
        },
        {
            'title' => 'Hostgroups:',
            'data'  => $ENV{NAGIOS_HOSTGROUPNAMES},
        },
        {
            'title' => 'Event Time:',
            'data'  => $ENV{NAGIOS_SHORTDATETIME},
        },
    );
}

if($ENV{NAGIOS_NOTIFICATIONTYPE} eq 'ACKNOWLEDGEMENT') {
    push(@rows,
        {
            'title' => 'Acknowledged By:',
            'data'  => $ENV{NAGIOS_NOTIFICATIONAUTHORALIAS},
        }
    );
    push(@rows,
        {
            'title' => 'Comment:',
            'data'  => $ENV{NAGIOS_NOTIFICATIONCOMMENT},
        }
    );
}

# Begin the email
my $body = "
<body>
<h3 style=\"font-family: $font; color: black\">$notification_title</h3>
<table border=\"0\" cellpadding=\"4\" cellspacing=\"2\" style=$style_table>";

# Add the rows to the email
for(my $i=0; $i<@rows; $i++) {
    $body .= sprintf('<tr><td style=%s>%s</th><td style=%s>%s</td></tr>',
        $i % 2 == 0 ? $style_th_even : $style_th_odd,
        $rows[$i]->{'title'},
        defined($rows[$i]->{'style'}) ? $rows[$i]->{'style'} : $i % 2 == 0 ? $style_td_even : $style_td_odd,
        $rows[$i]->{'data'}
    );
}
$body .= '</table></body>';

my $msg = MIME::Lite->new(
    To      => $ENV{NAGIOS_CONTACTEMAIL},
    Subject => $subject,
    Type    =>'multipart/related'
);

$msg->attach(Type => 'text/html', Data => $body);
$msg->send();


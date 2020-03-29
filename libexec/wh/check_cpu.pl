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
# at https://github.com/jasonhancock/nagios-cpu

use strict;
use warnings;
use Nagios::Plugin;

my $np = Nagios::Plugin->new(
    usage     => "Usage: %s\n",
    version   => '0.0.1',
    plugin    => $0,
    shortname => 'CPU',
    blurb     => 'Checks the cpu utilization',
    timeout   => 10,
);

$np->getopts;


my @keys = qw/user nice system idle iowait irq softirq steal guest/;
my %results;

foreach my $key(@keys) {
    $results{$key} = 0;
}

my $output = `cat /proc/stat`;
my @lines = split(/\n/, $output);

foreach my $line(@lines) {
    if($line=~m/^cpu\s+/) {
        my @pieces = split(/\s+/, $line);

        for(my $i=1; $i<@pieces; $i++) {
            $results{$keys[$i - 1]} = $pieces[$i];
        }
    }
}

foreach my $key(@keys) {
    $np->add_perfdata(
        label => $key,
        value => $results{$key} 
    );
}

$np->nagios_exit('OK', '');



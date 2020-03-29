#!/usr/bin/perl

my $s = join(",", @ARGV);
if ( $s =~ /10.101.12.60/ ) {
    open FH, ">>/tmp/test.log";
    print FH join("\n", @ARGV), "\n";
    close FH;
}

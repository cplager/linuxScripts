#!/usr/bin/env perl

use strict;
use warnings;

my $flag = "%"; # '#' doesn't work in bash

my $quiet;
while (@ARGV && $ARGV[0] =~ /^-/) {
   (my $arg = shift) =~ s/^-+//;
   if ($arg =~ /^quiet/i) {
      $quiet = "true";
   }
}

my $prog;
if (!@ARGV) {
	$prog = $0;
	$prog =~ s=.*/==g;
	die qq(Usage: $prog command file1 file2 ...
Use '$flag' instead of the filename.
ex:
$prog "mv $flag ../bin/#.old" file1 file2 file3...\n );
}


my $newcommand = shift @ARGV;
foreach my $file (@ARGV) {
	my $command = $newcommand;
	$command =~ s/$flag/$file/g;
	print "unix> $command\n" unless $quiet;
	print `$command`;
	print "\n" unless $quiet;
}

#!/usr/bin/env perl

use warnings;
use strict;

die "Usage: $0 computer.inter.net direc/tory file1 file2 file\*3\n"
  unless @ARGV >= 3;

my $computer = shift;
my $dir      = shift;
my @files    = @ARGV;

my $command = "ssh $computer \"chdir $dir >& /dev/null; tar czf - @files\" | tar xzvf -";

print "$command\n";
system $command;

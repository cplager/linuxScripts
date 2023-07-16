#!/usr/bin/perl

$file = shift @ARGV;
$spaces = shift @ARGV || 0;
($exe = $file) =~ s/\.[^\.]+$//;
open (SOURCE, $file) or die "Can't open $file for input\n";

print "\n" x $spaces;

while (<SOURCE>) {
    chomp;
    last if ((! m|^\s*//|) && (!m|^\s*$|)); # don't go past initial comments
    if (m|//\s*\(compile\)\s*|i) {
        $command = $';
        $command =~ s/\#\#/$exe/g;
        $command =~ s/\#/$file/g;
        print "unix> $command\n";
        system $command;
        last;
    }
}

#!/usr/bin/env perl

$numspaces = 3;
sub numerically {
	my ($first, $second);
	if ($a =~ /^(\d+)/) {
		$first = $1;
	}
	if ($b =~ /^(\d+)/) {
		$second = $1;
	}
	$first <=> $second;
}

sub printnice {
	my ($string) = @_;
	$retval = "";
	while ($string ne "") {
		$len = length ($string);
		$break = $len - int ($len / $numspaces) * $numspaces;
		if (! $break) {
			$break = $numspaces;
		}
		$first = substr ($string, 0, $break);
		$string = substr ($string, $break);
		$retval .= "$first ";
	} # while
	return $retval;
}

sub printFormatted {
	my ($value) = @_;
	my ($number, $rest);
	if ($value =~ /^(\d+)/) {
		$number = $1;
		$rest = $';
	}
	$rest =~ s/^\s*\.$/**Total** (K)/;
	printf ("%12s %s\n", printnice($number), $rest);
}

open (DULISTING, "du -k |") or die "Couldn't do du -k\n";

while (<DULISTING>) {
	#print;
	chomp;
    s|\./||; # get rid of first ./
    # Only take the top level directories
    if (! m|\/|) {
        push (@list, $_);
        next;
    }
}

foreach $entry (sort numerically @list) {
	printFormatted($entry);
}

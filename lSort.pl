#!/usr/bin/env perl

$numspaces = 3;

sub numerically {
	my ($first, $second);
	$first = $size{$a};
	$second = $size{$b};
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
	
#initialize output
@output = ();
@long = ();
@link = ();
$shortOut = "";

if (@ARGV && ($ARGV[0] =~ /^-s/i)) {
	shift @ARGV;
	$shortOut = "true";
}

if (@ARGV && ($ARGV[0] =~ /^-l/i)) {
	shift @ARGV;
	$shortOut = "";
}

if (@ARGV && ($ARGV[0] =~ /^-h/i)) {
	if ($0 =~ m|/([^/]+)$|) {
		$running = $1;
	} else {
		$running = $0;
	}
	print "Usage: $running (-options) (directory)
-h  -> this help output

Note : If no directory is given, current directory will be used.
";
	exit;
}

open (LISTING, "ls -alF @ARGV |") or die ("Couldn't get list");
while ($line = <LISTING>) {
	@array = split /\s+/, $line;
	# print out name of directory or name of link and where it points
	if ($array[8] =~ m|\.{1,2}/|) {
		next;
	}
	push (@names, $array[8]);
	$size{$array[8]} = $array[4];
}

@names = sort numerically @names;
$total = 0;
foreach $name (@names) {
	printf ("%16s   %s\n", printnice($size{$name}), $name);
	$total += $size{$name};
}
$nice = printnice ($total);
$dash = "-"x(length($nice) - 1);
printf ("%15s\n%16s (bytes)\n", $dash, $nice);

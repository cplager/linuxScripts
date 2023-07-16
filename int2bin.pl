#!/usr/local/bin/perl -w

$usehex = "true";
$numspaces = 8;

sub int2bin {
	my ($num) = @_;
	if (0 == $num) {
		$retval = "0";
	} else {
		$power = log($num) / $log2;
		#print "$num : $power\n";
		$start = int ($power) + 1;
		$retval = "";
		for ($loop = $start - 1; $loop >=0; --$loop)
		{
			if ((2 ** $loop) > $num)
			{
				$retval .= "0";
			} else {
				$retval .= "1";
				$num -= (2 ** $loop);
			}
		} # for
	} # num  0
	return $retval;
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
	
$log2 = log(2);
#$almost1 = .99999999;


$num = 1;
$arg = "";
die "\n" unless (@ARGV);
if ($ARGV[0] =~ /\-d/)
{
	$usehex = "";
	$arg = "true";
}
if ($ARGV[0] =~ /\-n(\d+)/) {
	$numspaces = $1;
	$arg = "true";
}
if ($arg) {
	shift @ARGV;
}

foreach $arg (@ARGV)
{
	@parts = split (" ", $arg);
	foreach $part (@parts) {
		if ($usehex) {
			$display = $part; 
			$part = hex($part);
			$display .= " ($part)";
		} else {
			$display = $part;
		}
		print $num++.") $display : ".printnice (int2bin($part))."\n";
	}
}
print "\n";

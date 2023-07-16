#!/usr/bin/perl

$char = "/";
$space = "";
$recursion = 1;
($short = $0) =~ s|.+/||g;
$help = "Usage: $short (-options)
-cX  => Use X as the comment character ('$char' default)
-e   => puts Extra blank lines around comment
-h   => This help screen
-rN  => Use N levels of recursion ($recursion default)
-ra  => print out all recursion levels upto and including N
-sN  => Use N spaces before the comment";

while ($ARGV[0] =~ /^-/) {
	$rest = $';
	# change the character
	if ($rest =~ /^h/i) {
        die "$help\n";
		next;
	}
	if ($rest =~ /^c(.)/i) {
		$char = $1;
		shift;
		next;
	}
	# change number of spaces
	if ($rest =~ /^s(\d+)/i) {
		$space = " " x $1;
		shift;
		next;
	}
	if ($rest =~ /^r(\d+)/i) {
        $recursion = $1;
		shift;
		next;
	}
	if ($rest =~ /^e/i) {
        $extra = "true";
		shift;
		next;
	}
	if ($rest =~ /^ra/i) {
        $all = "true";
		shift;
		next;
	}
	print "Unknown argument: $rest\n";
	shift;
}

while(<>)
{
   chop;
   push(@file,$_);
   if ( ($length = length)  > $maxlength ) {
       $maxlength = $length;
   }
}

print "\n\n";

for $loop (1..$recursion) {
    if ($extra && (1 != $loop)) {
        push @file, "";
        unshift @file, "";
    }
    @file = comment ($maxlength, @file);
    $maxlength += 6;
    printComment(@file) if $all;
}

printComment(@file) unless $all;

sub printComment {    
    my @lines = @_;
    foreach $line (@lines) {
        print "$space$line\n";
    }
    print "\n";
}

sub comment {
    my $maxlength = shift;
    my @lines = @_;
    #print "max $maxlength @lines\n";
    my @retval = ();

    # We have "//" at the beginning, "//" at the end, and a couple of
    # spaces that change the total length.
    my $borderlength = $maxlength + 6;

    # $borderlength should be even, since the pieces of the token are
    # 2 characters.
    my $border;
    $border = $char if ( $borderlength%2 );
    
    # Set the upper/lower border token to be "//".
    my $token = $char x 2;
    
    # Create the upper and lower border.
    $border .= $token x int(($borderlength)/2);
    
    # Set the end of line token.
    my $eoline = "$token";
    
    # If the border length isn't a multiple of 4, we'll end with "//" instead.
    #( $borderlength%4 ) && ( $border .= "//" ) && ( $eoline = "//\n" );
    
    # We have 5 characters of padding around every line: "// " and $eoline.
    my $padding = $borderlength - 5;
    
    push @retval, "$border";
    foreach my $line (@file)
    {
        push @retval,  ("$token $line" . " " x 
                        ($padding - length($line)) 
                        . $eoline);
    }
    push @retval, "$border";
    return @retval;
}

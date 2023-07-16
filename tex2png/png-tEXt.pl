#! /usr/bin/env perl
#-----------------------------------------------------------------------------

#-----------------------------------------------------------------------------
# Code starts here
#-----------------------------------------------------------------------------

# Be strict about the perl
use strict;
    
# Declare variables
my (
    $ihdr,                      # IHDR chunk
    $infile,                    # input filename
    $png,               # png data that doesn't concern us (just copy)
    $pngsize,                   # Total size of png
    $pos,                       # position in $png
    $sig,                       # PNG signature
    $status,                    # Status of Compress::Zlib
    $tchunk,                    # content of text chunk
    $text,                # 'string' of all tEXt chunks with CRC, etc.
    $zhandle,                   # Compression handle
    $zzTXt,                     # Compressed chunk
    %opts,                      # Command line options
    %tEXt,                      # tEXt chunks to insert
    %zTXt,                      # zTXt chunks to insert
   );

#-------------------------------------------------------------------------
# Read the command line options
#-------------------------------------------------------------------------
getopt('lickwartsgcLICKWARTSGC',\%opts);


# -k (keyword=keytext)
if ( defined( $opts{'k'} ) ) {
   # crude = keytext cannot contain =
   my ($kwd, $ktxt) = split /=/, $opts{'k'} ; 
   $tEXt{$kwd} = $ktxt ;
}


#-------------------------------------------------------------------------
# Read the input file
#-------------------------------------------------------------------------

die $usage unless defined($ARGV[0]) ;
$infile = $ARGV[0] ;
$text = '' ;

$pngsize = -s $infile;

open(IN, "$infile") or die "Cannot find input file $infile.\n$!";
binmode(IN);
read(IN, $sig, 8);

if (ValidateSignature($sig)) {
   close(IN);
   &Error('No png signature.');
}
read(IN, $ihdr, 25 ) ;

read(IN, $png, $pngsize-8-25);
close(IN);

$pos=0;

while (ChunkPrint()) {}

#-------------------------------------------------------------------------
# Process the command line options
#-------------------------------------------------------------------------
foreach my $keyword ( keys %tEXt ) {
   my $tbuffer;
   if ( substr($tEXt{$keyword},0,1) eq '@' ) # @ indicates get text from a file
     {
        open(IN, "<".substr($tEXt{$keyword},1) ) 
          or die "Cannot find text source file ".
            substr($tEXt{$keyword},1)."\n$!" ;
        $tbuffer = join '', <IN> ;
        close(IN) ;
     } else {
        $tbuffer = $tEXt{$keyword} ;
        $tbuffer =~  s/\\([tnrfbae])/control_char($1)/eg;
     }
   $tchunk = sprintf "%s%c%s", $keyword, 0, $tbuffer ;
   $text .= pack "N A* N", (length( $tchunk ), 
                            'tEXt'.$tchunk, &crc32( 'tEXt'.$tchunk ) ) ;
   $pngsize += length($tchunk) + 8 ;
} # foreach $keyword


#-------------------------------------------------------------------------
# Join the bits together, and dump them in binary mode to output
#-------------------------------------------------------------------------
$png = $sig.$ihdr.$text.$png;

binmode(STDOUT);
print  $png ;




# ChunkPrint
sub ChunkPrint {
   my $chunk = substr($png, $pos, 8);
   my ($length, $type) = unpack("N A4", $chunk);
   
   if ($type eq 'IEND' || $pos > ($pngsize - 12)) {
      return 0;
   }
   
   $pos += $length + 12;
}

# ValidateSignature
sub ValidateSignature {
   my $sig = shift;
   $sig eq "\x89PNG\r\n\x1a\n" && return 1;
   return 0;
}

# control_char
sub control_char {
   my $string = shift;
   $string/tnrfbae/\t\n\r\f\b\a\e/ ;
   return $string;
}

#!/usr/local/bin/perl

## Cut Text Chunks from PNG File 
## txtcut.cgi v0.3 May 2 2001 by techan
## Usage: http://(Path)/txtcut.cgi?Filename

$file = $ARGV[0];
$file =~ s/[^\w\-\~\/\.]//g;
$file eq "" && &Error('This script is operable.');

$pngsize = -s $file;
open(IN, "$file") || &Error('Can\'t find file.');
binmode(IN);
read(IN, $sig, 8);
unless (&ValidateSignature) { close(IN); &Error('No png signature.'); }
read(IN, $png, $pngsize-8);
close(IN);

$png=$sig.$png;
$pos=8;
$cut=0;
1 while (&ChunkCut);
$pngsize -= $cut;

$|=1;
print "Content-type: image/png\n";
# print "Content-length: $pngsize\n";
print "\n";
binmode(STDOUT);
print $png;
exit;

sub ChunkCut
{
$chunk=substr($png, $pos, 8);
($length, $type)=unpack("N A4", $chunk);
if ($type eq 'IEND' || $pos > ($pngsize-$cut-12)) { return 0; }
if ($type ne 'tEXt' && $type ne 'zTXt' && $type ne 'iTXt') { $pos +=$length+12; }
else { $cut +=$length+12; $png=substr($png,0,$pos).substr($png,($pos+$length+12)); }
return 1;
}

sub ValidateSignature
{
$sig eq "\x89PNG\r\n\x1a\n" && return 1;
return 0;
}

sub Error
{
print "Content-type: text/html\n\n";
print $_[0];
exit;
}
__END__

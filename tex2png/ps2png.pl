#!/usr/bin/env perl

use warnings;
use strict;

##############
## Defaults ##
##############
my $detail_default = 1.0;
my $margin_default = 10;
my $dpi_default = 100;
my $rotate_default = 0;
my $xsize_inch_default = 12;
my $ysize_inch_default = 12;
my $text_alpha_bits_default = 4;
my $graphics_alpha_bits_default = 4;

my $version = "ps2png.pl v0.9";
(my $command = $0) =~ s|.+/||g;
my $usage = "Usage: $command [-options] ps_file image_file
Description:

Options : 
--detail_ratio=n        [default = $detail_default}
--dpi=n                 [default = $dpi_default}
--help                  this menu
--margin=n              [default = $margin_default}
--rotate_angle=n        [default = $rotate_default} (counterclockwise in deg)]
--transparent=colorname [default no transparent color set]
--graphics_alpha_bits=n [default = $graphics_alpha_bits_default}
--text_alpha_bits=n     [default = $text_alpha_bits_default}

$version";

my %optionsHash = ();

while (@ARGV && $ARGV[0] =~ /^-/) {
   my $arg = shift @ARGV;
   $arg =~ s/^\-+//;
   die "$usage\n" if ($arg =~ /^help/);
   my ($name, $value);
   if ($arg =~ /^(\w+)=(\S+)/) {
      $name  = $1;
      $value = $2;
   } else {
      die "I don't understand '-$arg'.  Aborting.\n";
   }
   if ($name =~ /^dpi/i) {
      $optionsHash{dpi} = $value;
      next;
   }
   if ($name =~ /^det/i) {
      $optionsHash{detail_ratio} = $value;
      next;
   }
   if ($name =~ /^mar/i) {
      $optionsHash{margin_width} = $value;
      next;
   }
   if ($name =~ /^rot/i) {
      $optionsHash{rotate_angle} = $value;
      next;
   }
   if ($name =~ /^tra/i) {
      $optionsHash{transparent} = $value;
      next;
   }
   if ($name =~ /^gr/i) {
      $optionsHash{graphics_alpha_bits} = $value;
      next;
   }
   if ($name =~ /^te/i) {
      $optionsHash{text_alpha_bits} = $value;
      next;
   }
}

my $ps_file = shift;
my $output_file = shift;

die unless ($output_file);

convertPs2Png ($ps_file, $output_file, %optionsHash);

sub convertPs2Png {
   my $ps_file = shift;
   my $output_file = shift;
   my %optionsHash = @_;

   my %valuesHash;
   $valuesHash {dpi} = $dpi_default;
   $valuesHash {detail_ratio} = $detail_default;
   $valuesHash {margin_width} = $margin_default;
   $valuesHash {rotate_angle} = $rotate_default;
   $valuesHash {xsize_inch} = $xsize_inch_default;
   $valuesHash {ysize_inch} = $ysize_inch_default;
   $valuesHash {text_alpha_bits} = $text_alpha_bits_default;
   $valuesHash {graphics_alpha_bits} = $graphics_alpha_bits_default;

   # overwrite the defaults with the options hash
   foreach my $key (keys %optionsHash) {
      $valuesHash{$key} = $optionsHash{$key};
   }

   # convert command
   my $convert_command;
   if ($output_file =~ /\.gif$/i) {
      chomp ($convert_command = `which ppmtogif`);
   } elsif ($output_file =~ /\.png$/i) {
      chomp ($convert_command = `which pnmtopng`);
   } else {
      die "Target must be a .png or .gif file.  Aborting.\n";
   }

   if (! -e $convert_command) {
      die "Path to NETPBM not set correctly ('$convert_command').  Aborting.\n";
   }


   my $reduction_ratio = sprintf (".3f", 1 / $valuesHash{detail_ratio}); 

   #dpi of working field

   my $work_dpi = $valuesHash{detail_ratio} * $valuesHash{dpi}; 

   #size of working field in pixels
   my $pix_Xsize =  $work_dpi * $valuesHash{xsize_inch};
   my $pix_Ysize =  $work_dpi * $valuesHash{ysize_inch};

   print "source : $ps_file ,  target : $output_file\n";

   unlink $output_file;

   my $gscommand = "gs < /dev/null  -sDEVICE=ppmraw -dTextAlphaBits=$valuesHash{text_alpha_bits} -dGraphicsAlphaBits=$valuesHash{graphics_alpha_bits} -sOutputFile=- -g$pix_Xsize"."x"."$pix_Ysize -r$work_dpi -q -dNOPAUSE $ps_file | pnmcrop -white";

   # rotate command
   if ($valuesHash{rotate_angle}) {
      $gscommand .= " | pnmrotate $valuesHash{rotate_angle}";
   }

   # scale command
   if (1 != $valuesHash{detail_ratio}) {
      $gscommand .= " | pnmscale $valuesHash{reduction_ratio}";
   }

   # margin command
   if ($valuesHash{margin_width}) {
      $gscommand .= " | pnmmargin -white $valuesHash{margin_width}";
   }

   my $color_reduction_command = "pnmdepth 15";

   # transparent option
   my $transparent_option = "";
   if ($valuesHash{transparent}) {
      $transparent_option = "-transparent $valuesHash{transparent}";
   }


   $gscommand .= "| $color_reduction_command | ppmquant 256 | $convert_command -interlace $transparent_option -";

   #print "command $gscommand\n";

   system "$gscommand > $output_file";

   return;
}


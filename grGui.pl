#!/usr/bin/env perl

use strict;
use warnings;
#use lib "/cdf/scratch/cplager/perllibs";
use Tk;

# global variables
my $version = "grGui version 1.60 050615 cplager\@fnal.gov";
my $noWrap   = "none";				# do not change
my $wrap     = "word";				# do not change
my $charWrap = "char";				# do not change
my $xon = "/home/cplager/bin/startcommand";
my $font = "6x13";
my $checkCase = "";
my $doDirectories = "";
my $verbose = "true";
my $doBinary = "";
my $doAnd = "";
my $doFileAnd = "";
my $doText = "";
my $noback = "";
my $doWrap = $wrap;
my $height = 60;
my $width  = 80;

my $help = "\nUsage: grGui w=word1 (w=word2 ...) (file1 file2 ...) (-options)
options:
-and          => does 'and' instead of 'or'
-avoid dir/   => doesn't look in directory dir/ 
-bin          => search binary files 
-case         => force case matching g95
-charwrap    => window will wrap long lines (character wrap)
-dir          => expand directories
-exclude file => excludes files matching 'file'
-fn XXX       => sets emacs font to 'XXX'
-file         => only prints files where each word is found at least once
-height NN   => set height to NN lines (default: $height)
-help         => this help screen
-list file    => uses 'file' to provide list of files to check
-noback      => won't open up backup files ('~' or '.bak')
-nolink       => won't follow soft-linked directories
-nowrap      => will NOT rap long lines
-nv          => non-verbose (won't print directory names)
-width NN    => set width to NN lines (default $width)
-text         => dumps result to STDOUT
-wrap         => window will wrap long lines
The order of the arguments doesn't matter.

If no files are given, the default is to search all files in the
current directory.

$version\n";


sub clicked {
   my $var = shift;
   my $position = $var->index('current');
   if ($position =~ /(\d+).\d+/) {
	  my $lineNum = $1;
	  my $line = $var->get("$lineNum.0", "$lineNum.0 lineend");
	  if ($line =~ /^in file (.+):$/i) {
		 my $file = $1;
		 if ($file !~ m|^/|) {
			$file = "$ENV{PWD}/$file";
		 }			
		 my $cmd = "$xon emacs -rv -fn $font $file";
		 system ($cmd);
	  }
   }
}

my @excludes = ();
my (@files, @words, @not);
# parsing arguments
while (my $arg = shift @ARGV) {
   if ($arg =~ /w=/) {
	  push @words, $';
	  next;
   }
   if ($arg =~ /n=/) {
	  push @not, $';
	  next;
   }
   if ($arg =~ /^-/) {
	  my $option = $';
 	  if ($option =~ /^text/i) {
		 $doText = "true";
		 next;
	  }
	  if ($option =~ /^and/i) {
		 $doAnd = "true";
		 next;
	  }
	  if ($option =~ /^noback/i) {
		 $noback = "true";
		 next;
	  }
	  if ($option =~ /^bin/i) {
		 $doBinary = "true";
		 next;
	  }
	  if ($option =~ /^case/) {
		 $checkCase = "true";
		 next;
	  }
	  if ($option =~ /^dir/i) {
		 $doDirectories = "true";
		 next;
	  }
	  if ($option =~ /^exclude/i) {
		 my $excluded = shift @ARGV;
		 push @excludes, $excluded if $excluded;
		 next;
	  }
	  if ($option =~ /^height/i) {
		 $height = shift @ARGV;
		 next;
	  }
	  if ($option =~ /^width/i) {
		 $width = shift @ARGV;
		 next;
	  }
	  if ($option =~ /^list/i) {
		 my $filename = shift @ARGV;
		 if (! -e $filename) {
			warn "Can't open $filename for list of files\n";
			next;
		 }
		 open (LISTFILE, $filename) or
		   warn "Can't open $filename for reading\n";
		 while (<LISTFILE>) {
			chomp;
			if (-e $_) {
			   push @files, $_;
			}
		 }
		 next;
	  }
	  if ($option =~ /^file/i) {
		 $doFileAnd = "true";
		 next;
	  } elsif ($option =~ /^fn(\w*)/) {
		 $font = $1;
		 if (! $font) {
			$font = shift @ARGV;
		 }
		 next;
	  }
	  if ($option =~ /^height/i) {
		 my $value = shift @ARGV;
		 if ($value =~ /^\d+$/) {
			$height = $value;
		 }
		 next;
	  }
	  if ($option =~ /^width/i) {
		 my $value = shift @ARGV;
		 if ($value =~ /^\d+$/) {
			$width = $value;
		 }
		 next;
	  }
	  if ($option =~ /^h/i) {
		 print "$help";
		 exit;
	  }
	  if ($option =~ /^nv/i) {
		 $verbose = "";
		 next;
	  }
	  if ($option =~ /^nowrap/i) {
		 $doWrap = $noWrap;
		 next;
	  }
	  if ($option =~ /^charwrap/i) {
		 $doWrap = $charWrap;
		 next;
	  }
	  if ($option =~ /^wrap/i) {
		 $doWrap = $wrap;
		 next;
	  }
   } else {
	  push @files, $arg;
	  next;
   }
}

# don't have both lineAnd and fileAnd
if ($doAnd) {
   $doFileAnd = "";
}

#$numfiles = @files;
#print "files ($numfiles):\n".join("\n", @files)."\n";

if (! @files) {
   @files = glob ("*");
   push @files, glob (".*");
}

die "Usage: grGui w=word1 (w=word2) file1 file2\nUse -h for help\n" 
  if (!@words);

my $startDir = my $currentDir = $ENV{'PWD'};
my @goodFiles = ();
my %beenThere = ();
foreach my $file (@files) {
   if ($noback) {
	  # check file name
	  next if (($file =~ /\~$/) || ($file =~ /\.bak$/));
   }
   if ($file !~ m|^/|) {
	  $file = "$currentDir/$file";
   }		
   if (-d $file) {
	  next if (! $doDirectories);
	  if (($file eq ".") && (1 == @files)) {
		 $file = $startDir;
	  }
	  # we don't want /. or /..
	  if ( ($file =~ m|/\.$|) ||
		   ($file =~ m|/\.\.$|) ) {
		 next;
	  }
	  # is this excluded
	  my $isexcluded = "";
	  (my $short = $file) =~ s|.+/||g;
	  foreach my $exclude (@excludes) {
		 if ($short =~ /$exclude/) {
			$isexcluded = "true";
			last;
		 }
	  }
	  if ($isexcluded) {
		 #print "excluding $file\n";
		 next;
	  }
	  $file =~ s|//|/|g;
	  chdir $file;
	  my $key = `pwd`;
	  if (! $beenThere{$key}) {
		 # we haven't been there yet
		 print "dir $file\n" if ($verbose);
		 $beenThere{$key} = "yep";
		 my @newFiles = glob ("$file/*");
		 push @files, @newFiles;
		 @newFiles = glob ("$file/.*");
		 push @files, @newFiles;
	  }
   } elsif (-e $file) {
	  # make sure we don't take excluded files
	  (my $short = $file) =~ s|.+/||g;
	  my $dontTake = "";
	  foreach my $exclude (@excludes) {
		 if ($short =~ /$exclude/i) {
			$dontTake = "true";
			last;
		 }
	  }
	  next if ($dontTake);
	  if ($doBinary || (! -B $file)) {
		 push @goodFiles, $file;
	  }
   } else {
	  warn "$file doesn't exist\n";
   }
}
chdir $startDir;

# setup Tk stuff
my $main = MainWindow->new (-background => 'white',
							-title => "grGui: @words");
my $text = $main->Scrolled("Text",
						   -background => "white",
						   -tabs => [qw/1.8i 2.9i left/],
						   -spacing3 => 0,
						   -width => $width,
						   -font => $font,
						   -wrap => $doWrap,
						   -height => $height)->pack();
my $okButton = $main->Button(-text => "Done",
							 -relief => 'flat',
							 -borderwidth => 2,
							 -width => 4,
							 -takefocus => 1,
							 -highlightthickness => 3,
							 -background => 'white',
							 -foreground => 'black',
							 -activebackground => 'white',
							 -activeforeground => 'red',
							 -command => sub {exit;})->
  pack (-side => 'bottom', -anchor => 'center');
# make tags
$text->tagConfigure('filename', 
					-foreground => "blue",
					-underline => 1);
$text->tagConfigure('red', -foreground => "red");
$text->tagConfigure('green', -foreground => "darkgreen");
$text->tagConfigure('lineNumber', 
					-foreground => 'white', 
					-background => 'darkgreen');
# set tag binds
$text->tagBind('filename', "<Button-1>", \&clicked);
$text->tagBind('filename', "<Any-Enter>", 
			   sub {shift->configure(-cursor => 'hand2')} );
$text->tagBind('filename', "<Any-Leave>", 
			   sub {shift->configure(-cursor => 'xterm')} );
$text->tagRaise('lineNumber');

# bind events
$main->bind("<Q>", sub {exit;});
$main->bind("<q>", sub {exit;});
$main->bind("<Home>", sub {$text->yviewMoveto(0.0);});
$main->bind("<End>", sub {$text->yviewMoveto(1.0);});
$main->bind("<Next>", sub {$text->yviewScroll(1 => 'pages');});
$main->bind("<Prior>", sub {$text->yviewScroll(-1 => 'pages');});
$main->bind("<BackSpace>", sub {$text->yviewScroll(-1 => 'pages');});
$main->bind("<space>", sub {$text->yviewScroll(1 => 'pages');});
$main->bind("<Down>", sub {$text->yviewScroll(1 => 'units');});
$main->bind("<Up>", sub {$text->yviewScroll(-1 => 'units');});
$main->bind("<Right>", sub {$text->xviewScroll(1 => 'units');});
$main->bind("<Left>", sub {$text->xviewScroll(-1 => 'units');});


my $numFiles = my $numWords = my $numLines = 0;
my $textout = "";
my $numFilesSearched = 0;
foreach my $file (sort @goodFiles) {
   ++$numFilesSearched;
   $file =~ s|//|/|g;
   $file =~ s|/\./|/|g;
   if (! open (SOURCE, $file) ) {
	  warn "Can't open $file\n";
	  next;
   }
   if ($doFileAnd) {
	  my %wordFound = ();
	  READING: while (<SOURCE>) {
		 my $wordIndex = -1;
		 # kick out the lines with the words we don't want
		 foreach my $word (@not) {
			# if we find any of these words, don't use this line
			if ((/$word/) || (/$word/i && ! $checkCase)) {
			   # got one, skip this line
			   next READING;
			}                
		 } # foreach @not
		 foreach my $word (@words) {
			++$wordIndex;
			if ((/$word/) || (/$word/i && ! $checkCase)) {
			   $wordFound{$word} = "found";
			}
		 } # foreach @words 
	  } # while SOURCE
	  my $ok = "true";
	  foreach my $word (@words) {
		 if (! $wordFound{$word} ) {
			$ok = "";
			last;
		 }
	  }
	  if (! $ok) { 
		 next;					#file		 
	  }
	  close (SOURCE);
	  open (SOURCE, $file)
   }							# doFileAnd
   my $first = "true";
   my $line = 0;
   my $options = "i";
 READFILE: while (<SOURCE>) {
	  ++$line;
	  # kick out the lines with the words we don't want
	  foreach my $word (@not) {
		 # if we find any of these words, don't use this line
		 if ((/$word/) || (/$word/i && ! $checkCase)) {
            # got one, skip this line
            next READFILE;
		 }                
	  }
	  if ($doAnd) {
		 foreach my $word (@words) {
			if (! (/$word/) && ! (/$word/i && ! $checkCase) ) {
			   next READFILE;
			}
		 }
	  }							# if doAnd
	  foreach my $word (@words) {
		 # ++$wordIndex;
		 if ((/$word/) || (/$word/i && ! $checkCase)) {
			# $whichWords[$wordIndex] = 1;
			++$numLines;
			if ($first) {
			   ++$numFiles;
			   if ($file !~ m|^/|) {
				  $file = "$ENV{PWD}/$file";
			   }			
			   $text->insert ('end', "\nIn file ");
			   $text->insert ('end', $file, 'filename');
			   $text->insert ('end', ":\n");
			   $textout .= "\nIn file $file:\n";
			   $first = 0;
			}
			my $number = sprintf ("%4d", $line);
			my $good = sprintf (" %s", $_);
			chomp $good;
			$good =~ s/\t/    /g;
			$text->insert ('end', $number, 'lineNumber');
			$text->insert ('end', "$good\n");
			$textout .= sprintf ("%5d  %s\n", $number, $_);
			# first let's get a list of all words we should highlight
			my @goodWords = ();
			foreach my $word (@words) {
			   #++$wordIndex;
			   my $rest = $_;
			   while ($rest) {
				  if (($rest =~ /($word)/) ||
					  ($rest =~ /($word)/i && ! $checkCase)) {
					 #$whichWords[$wordIndex] = 1;
					 push @goodWords, $1;
					 $rest = $'; #';
				  } else {
					 $rest = "";
				  }
			   }				# while $rest
			}					# foreach word
			# Now, lets highlight the words
			my $endPosition = $text->index('current');
			if ($endPosition =~ /^(\d+)\./) {
			   my $start = ($1 - 1).".0";
			   $numWords += @goodWords;
			   foreach my $hword (@goodWords) {
				  my $index = $start;
				  my $wordLen = length($hword);
				  while ($index) {
					 #print "index $index\n";
					 $index = $text->
					   search(-exact, $hword, $index, $endPosition);
					 if ($index) {
						my $end = "$index + $wordLen chars";
						#print "$index $end\n";
						$text->tagAdd('red', 
									  $index, 
									  "$index + $wordLen chars");
						$index .= " + 1 chars";
					 }			# if index
				  }				# while $index
			   }				# foreach hword
			   next READFILE;
			} else {
			   next READFILE;
			}
		 }						# if $word
	  }							# foreach word
   }							# while source
}								# file
$text->insert ('1.0', "$numWords matches found in $numLines lines of $numFiles files out of $numFilesSearched files searched\n", 'green');
$text->configure(-state => 'disabled');
if ($doText) {
   print "$numWords matches found in $numLines lines of $numFiles files out of $numFilesSearched files searched\n$textout\n";
} else {
   MainLoop;
}

#!/usr/bin/env perl

use strict;
use warnings;
use Term::ANSIColor qw(:constants);



my $version = "cgr.pl version 1.21 090608 cplager\@fnal.gov";
my $checkCase = "";
my $doDirectories = "";
my $verbose = "true";
my $doBinary = "";
my $doAnd = "";
my $doFileAnd = "";
my $doText = "";
my $noback = "";
my $only = "";
my $linenums = "true";
my $startmark = ",,,1,,,";
my $endmark   = ",,,2,,,";
my $matchColor = RED.BOLD;  # matching color
my $numColor = GREEN;   # line numbers
my $fileColor_wb = BLUE.BOLD; # file color assuming white background
my $fileColor_bb = YELLOW.BOLD; # file color assuming black background
my $fileColor = $fileColor_bb; # filename color
my $reset        = RESET;
my $sepchar = " "; # should be '|' or ' ';
my $nolink = "";
my $doHtml = "";
my @standardAvoids = (".backup", "CVS");
my @standardExcludes = ('~$', '\.bak$', '\.o$', '\.d$');

my $help = "\nUsage: cgr.pl w=word1 (w=word2 ...) (file1 file2 ...) (-options)
options:
-and          => does 'and' instead of 'or'
-avoid dir/   => doesn't look in directory dir/ 
-black        => changes colors for a black background (default)
-case         => force case matching
-dir          => expand directories
-exclude file => excludes files matching 'file'
-file         => only prints files where each word is found at least once
-help         => this help screen
-html         => Use HTML colors instead of Term::ANSIColor
-just         => JUST prints out the match and NOTHING else
-list file    => uses 'file' to provide list of files to check
-match file   => only checks files matching 'file'
-noback       => won't open up backup files ('~' or '.bak')
-nocolor      => Turns off all colors (used when dumping to file)
-nolink       => will not follow soft-linked directories
-(no)line     => (Don't) print line numbers
-only         => prints out matches ONLY (no summary, no filenames)
-quiet        => Quiet/non-verbose (won't print directory names)
-standard     => use standard options, 'avoid's and 'exclude's
-white        => changes colors for a white background
If no files are given, the default is to search all files in the
current directory.

$version\n";

sub splitBy {
   my $line = shift;
   my @words = @_;
   my @retval;
   push @retval, $line;
   foreach my $word (@words) {
	  my @curval;
	  foreach my $segment (@retval) {
		 # check to see if this word appears at all in this segment
		 if ($segment !~ /$word/) {
			push @curval, $segment;
			next;
		 }
		 # if we're still here, then we need to split the line up
		 while ($segment =~ m|$word|) {
			push @curval, $` if (defined $`);
			push @curval, $&;
			$segment = $';
		 }
		 push @curval, $segment if (defined $segment);
	  } # foreach @retval
	  @retval = @curval;
   } # foreach @words
   return @retval;
} # sub splitBy

my @excludes = ();
my @matches  = ();
my @toAvoid = ();
my (@files, @words, @not);
my $justMatchOnly = "";
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
      $arg =~ s/^-+//;
	  if ($arg =~ /^and/i) {
		 $doAnd = "true";
		 next;
	  }
      if ($arg =~ /^standard/i) {
         push @excludes, @standardExcludes;
         push @toAvoid, @standardAvoids;
         $nolink = "true";
         $doDirectories = "true";
         $verbose = "";
         next;
      }
      if ($arg =~ /^avoid/i) {
         my $toavoid = shift;
         push @toAvoid, $toavoid if ($toavoid);
         next;
      }
	  if ($arg =~ /^noline/i) {
		 $linenums = "";
		 next;
	  }
	  if ($arg =~ /^html/i) {
		 $doHtml = "true";
		 $verbose = "";
         $matchColor = "<font color=\"red\">";
         $numColor   = "<font color=\"green\">";
         $fileColor  = "<font color=\"blue\">";
         $reset      = "</font>";
		 next;
	  }
	  if ($arg =~ /^just/i) {
		 $justMatchOnly = "true";
		 next;
	  }
	  if ($arg =~ /^nolink/i) {
		 $nolink = "true";
		 next;
	  }
	  if ($arg =~ /^line/i) {
		 $linenums = "true";
		 next;
	  }
	  if ($arg =~ /^noback/i) {
		 $noback = "true";
		 next;
	  }
	  if ($arg =~ /^only/i) {
		 $only = "true";
		 next;
	  }
	  if ($arg =~ /^bin/i) {
		 $doBinary = "true";
		 next;
	  }
	  if ($arg =~ /^case/) {
		 $checkCase = "true";
		 next;
	  }
	  if ($arg =~ /^dir/i) {
		 $doDirectories = "true";
		 next;
	  }
      if ($arg =~ /^nocolor/i) {
         $matchColor = "";
         $numColor   = "";
         $fileColor  = "";
         $reset      = "";
         next;
      }
	  if ($arg =~ /^white/i) {
         $fileColor = $fileColor_wb;
		 next;
	  }
	  if ($arg =~ /^black/i) {
         $fileColor = $fileColor_bb;
		 next;
	  }
	  if ($arg =~ /^exclude/i) {
		 my $excluded = shift @ARGV;
		 push @excludes, $excluded if $excluded;
		 next;
	  }
	  if ($arg =~ /^match/i) {
		 my $match = shift @ARGV;
		 push @matches, $match if $match;
		 next;
	  }
	  if ($arg =~ /^list/i) {
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
	  if ($arg =~ /^file/i) {
		 $doFileAnd = "true";
		 next;
	  } 
	  if ($arg =~ /^h/i) {
		 print "$help";
		 exit;
	  }
	  if ($arg =~ /^nv/i) {
		 $verbose = "";
		 next;
	  }
	  if ($arg =~ /^quiet/i) {
		 $verbose = "";
		 next;
	  }
      die "I don't understand '-$arg'.\n";
	  ## if ($arg =~ /^width/i) {
	  ##    my $value = shift @ARGV;
	  ##    if ($value =~ /^\d+$/) {
	  ##   	$width = $value;
	  ##    }
	  ##    next;
	  ## }
	  ## if ($arg =~ /^nowrap/i) {
	  ##    $doWrap = $noWrap;
	  ##    next;
	  ## }
	  ## if ($arg =~ /^wrap/i) {
	  ##    $doWrap = $wrap;
	  ##    next;
	  ## }
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

# lets setup the excludes and the avoids so that they become exact
# string matches UNLESS they have characters beyond simple characters
foreach my $exclude (@excludes) {
   if ($exclude =~ /^[\w\-\.~]+$/) {
      # $exclude ONLY has standard characters
      $exclude =~ s|\.|\\.|g;
      $exclude = "\^$exclude\$";
   }
}
foreach my $avoid (@toAvoid) {
   if ($avoid =~ /^[\w\-\.~]+$/) {
      # $avoid ONLY has standard characters
      $avoid =~ s|\.|\\.|g;
      $avoid = "\^$avoid\$";
   }
}

my $startDir = my $currentDir = $ENV{'PWD'};
my @goodFiles = ();
my %beenThere = ();
while (my $file = shift @files) {
   if ($file !~ m|^/|) {
	  $file = "$currentDir/$file";
   }		
   # we want to check matches, but only if it is not a directory
   if ($noback) {
	  # check file name
	  next if ( ($file =~ /\~$/)      || 
                ($file =~ /\.bak$/)   || 
                ($file =~ /\.backup$/)   );
   }
   if (-d $file) {
	  next if (! $doDirectories);
      next if (-l $file && $nolink);
      if (@toAvoid) {
         (my $short = $file) =~ s|.*/||g;
         my $ok = "true";
         foreach my $avoid (@toAvoid) {
            if ($short =~ /$avoid/) {
               $ok = "";
               last;
            } # foreach avoid
         }
         next unless $ok;
      }
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
      if (@matches) {
         my $found = "";
         foreach my $match (@matches) {
            if ($file =~ /$match/) {
               $found = "true";
               last;
            } # if match
         } # foreach match
         next unless $found;
      } # if @matches
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


my $numFiles = my $numWords = my $numLines = 0;
my $numFilesSearched = 0;
my $text;

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
		 chomp;
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
	  chomp;
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
	  }	# if doAnd
      if ($justMatchOnly) {
         foreach my $word (@words) {
            if ($checkCase) {
               while (/($word)/g) {
                  print "$1\n";
               }
            } else {
               while (/($word)/gi) {
                  print "$1\n";
               }
            } # else if check case
         } # foreach word
         next READFILE;
      } # if justMatchCase
	  my @goodWords;
	  foreach my $word (@words) {
		 # ++$wordIndex;
		 if ((/$word/) || (/$word/i && ! $checkCase)) {
			push @goodWords, $word;
		 } # if word found
	  } # foreach word
	  # if we didn't find anythingg don't bother
	  $numWords += @goodWords;
	  next READFILE unless (@goodWords);
	  if ($doAnd) {
		 next READFILE unless (scalar @goodWords == scalar @words);
	  }
	  ++$numLines;
	  if ($first) {
		 ++$numFiles;
		 if ($file !~ m|^/|) {
			$file = "$ENV{PWD}/$file";
		 }
         my $prettyfile = $file;
         $prettyfile =~ s|^$currentDir|./|;
         $prettyfile =~ s|/{2,}|/|g;
		 $text .= "\nIn file ". $fileColor . $prettyfile . $reset . " :\n" unless ($only);
		 $first = 0;
	  }
	  my $number = sprintf ("%5d%s", $line, $sepchar);
	  $text .= $numColor . $number . $reset if ($linenums);
	  foreach my $word (@goodWords) {
		 if ($checkCase) {
			s|($word)|$startmark$1$endmark|g;
		 } else {
			s|($word)|$startmark$1$endmark|ig;
		 }
	  } # foreach word
	  # O.k.  Here's the fun part.  Since we just put in the
	  # startmarks and the endmarks, we know they come in pairs.  We
	  # now need to get rid of the embedded marks 
	  # (e.g. aaaSbbSccEddEee ==> aaSbbccddEee)
	  my @parts = splitBy ($_, $startmark, $endmark);
	  my $level = 0;
	  my $line;
	  foreach my $part (@parts) {
		 if ($part ne $startmark && $part ne $endmark) {
            $part = fixHtmlTxt ($part) if ($doHtml);
			$line .= $part;
			next;
		 } # not $startmark nor $endmark
		 if ($part eq $startmark) {
			if (0 == $level++) {
			   $line .= $matchColor;
			}
			next;
		 } # if $startmark
		 if ($part eq $endmark) {
			if (0 == --$level) {
			   $line .= $reset;
			}
			next;
		 }
	  }	# foreach @parts
	  $text .= $line."\n";
   } # while READFILE
} # while @goodFiles

if (! $justMatchOnly) {
   print $numColor, "$numWords matches found in $numLines lines of $numFiles files out of $numFilesSearched files searched\n", $reset unless ($only);
   print $text if ($text);
}
print $reset; # just in case...

sub fixHtmlTxt {
   my $string = shift;
   $string =~ s|&|&amp;|g;
   $string =~ s|\<|&lt;|g;
   $string =~ s|\>|&gt;|g;
   return $string;
}

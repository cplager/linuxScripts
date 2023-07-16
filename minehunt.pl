#!/usr/bin/perl
use Tk;
use Tk::Font;

##########################
## Initialize Variables ##
##########################

$numMines = 20;
$numFound = $numMines;
$game_over = "true";
$numX = 20;
$numY = 14;
$total = $numX * $numY;
$size = 15;
$space = 0;
$border = 5;
$fontsize = $size * 0.8;
$prettykey = "";
$mine_mark = "#";
$grid_color = 'SeaGreen3';
$non_exposed_color = "grey";
@colors = qw (blue DarkGoldenrod4 red orange black purple1 gold1 khaki4 mistyrose4);
$font = "";

##################
## Main Program ##
##################
parce_arguments();
tk_init();
draw_rectangles();
start_game();
MainLoop;

#################
## Subroutines ##
#################
sub parce_arguments {
	while ($_ = shift @ARGV) {
		# number of mines 
		if (/^-m/i) {
			my $num = -1;
			my $rest = $';
			if ($rest =~ /(\d+)/) {
				$num = $1;
			} else {

				$rest = shift @ARGV;
				if ($rest =~ /(\d+)/) {
					$num = $1;
				}
			}
			if (($num >= 0) && ($num < $total)) {
				$numMines = $num;
			}
			next;
		} # if -m
		# height
		if (/^-h/i) {
			my $num = -1;
			my $rest = $';
			if ($rest =~ /(\d+)/) {
				$num = $1;
			} else {
				$rest = shift @ARGV;
				if ($rest =~ /(\d+)/) {
					$num = $1;
				}
			}
			if (($num > 5) && ($num < 50)) {
				$numY = $num;
				$total = $numX * $numY;
			}
			next;
		} # if -h
		# width
		if (/^-w/i) {
			my $num = -1;
			my $rest = $';
			if ($rest =~ /(\d+)/) {
				$num = $1;
			} else {
				$rest = shift @ARGV;
				if ($rest =~ /(\d+)/) {
					$num = $1;
				}
			}
			if (($num > 5) && ($num < 50)) {
				$numX = $num;
				$total = $numX * $numY;
			}
			next;
		} # if -w
		# size
		if (/^-z/i) {
			my $num = -1;
			my $rest = $';
			if ($rest =~ /(\d+)/) {
				$num = $1;
			} else {
				$rest = shift @ARGV;
				if ($rest =~ /(\d+)/) {
					$num = $1;
				}
			}
			if (($num > 5) && ($num < 50)) {
				$size = $num;
                $fontsize = $size * 0.8;
			}
			next;
		} # if -z
		# space
		if (/^-s/i) {
			my $num = -1;
			my $rest = $';
			if ($rest =~ /(\d+)/) {
				$num = $1;
			} else {
				$rest = shift @ARGV;
				if ($rest =~ /(\d+)/) {
					$num = $1;
				}
			}
			if (($num >= 0) && ($num < 50)) {
				$space = $num;
			}
			next;
		} # if -s
	} # while ARGV
}

sub tk_init {
	$widthX = $numX * ($size + $space) - $space + 2 * $border;
	$widthY = $numY * ($size + $space) - $space + 2 * $border;
	$main = MainWindow->new(-background => "white");
    my $bf = $main->fontCreate('big',
                               -family=>'arial',
                               -weight=>'bold',
                               -size=>$fontsize);
	($nicename = $0) =~ s|.+/||g;
	$nicename = ucfirst $nicename;
	$main->title("$nicename $numX x $numY");
	$main->bind( "<q>" , sub { exit(0); } );
	$main->bind( "<Q>" , sub { exit(0); } );
	
	$frame1 = $main->Frame(#-relief => 'groove',
						   -bd => 2,
						   -width => 1000)->pack(-side => 'top',
												-fill => 'x');
	$frame2 = $main->Frame(#-relief => 'groove',
						   #-background => 'grey',
						   -bd => 2,
						   -width => 1000)->pack(-side => 'top',
												 -fill => 'x');
	$currenttime = 0;
	
	# $frame1->Label(-textvariable => \$numFound)->pack(-anchor => 'w');
	# $frame1->Label(-text => "Current Coordinates")->pack(-anchor => 'w');
	# $frame1->Label(-textvariable => \$currentkey)->pack(-anchor => 'w');
	# $frame1->Button(-text => "Start",
	# 				 -command => \&start_game)->pack(-anchor => 's');
	# $frame1->Button(-text => "Quit",
	# 				 -command => sub {exit})->pack(-anchor => 's');

	$frame1->Button(-text => "Start",
				   -command => \&start_game)->pack(-side => 'left',
													   -padx => 3);
	$frame1->Button(-text => "Quit",
					 -command => sub {exit})->pack(-side => 'left',
													   -padx => 3);
	$frame1->Label(-text => "Mines: ")->pack(-side => 'left');
	$frame1->Label(-textvariable => \$numFound)->pack(-side => 'left',
													   -padx => 10);
	$frame2->Label(-text => "Time: ")->pack(-side => 'left');
	$frame2->Label(-textvariable => \$currenttime)->pack(-side => 'left');
	$frame2->Label(-text => "Current Coordinates")->pack(-side => 'left');
	$frame2->Label(-textvariable => \$prettykey)->pack(-side => 'left');
	$textMessage = "Hi Mom";

	$textWidget = $main->Label(-textvariable => 
							   \$textMessage)->pack(-side => 'bottom',
													-fill => 'both',
													-expand => 1
													);
	$canvas = $main->Canvas(-cursor => "crosshair",
							#-background => "white",
							-height => $widthY,
							-width => $widthX)->pack(-side => 'bottom',
													 -fill => 'both',
													 -expand => 1);	
	#$main->bind("<Motion>", \&update_time);
	$starttime = time();
	$main->repeat(1000,\&update_time);
}

sub update_time {
	$currenttime = time() - $starttime unless $game_over;
}

sub change_message {
	my ($message) = @_;
	$textMessage = $message;
	$main->update;
}

sub start_game {
	change_message ("Starting Game...");
	%mine = ();
	$currenttime = sprintf ("%4d", 0);
	$game_over = "";
	%checked = ();
	%marked = ();
	%doublechecked = ();
	%number = ();
	$canvas->delete ("all");
	$numFound = $numMines;
	create_mines();
	#reset_mines();
	draw_rectangles();
	my $id = $canvas->find("withtag", "end_message");
	$canvas->delete($id) if ($id);
	$starttime = time();
	bind_start();
	change_message ("");
}

sub reset_mines() {
	for $X (1..$numX) {
		for $Y (1..$numY) {
			my $key = "$X\_$Y";
			# reset color of all rectangles
			change_rect_color ($key, $grid_color);
			# remove any text
			my $id = $canvas->find("withtag", "mine_$key");
			$canvas->delete($id) if ($id); # remove mine marking
			$id = $canvas->find("withtag", "text_$key");
			$canvas->delete($id) if ($id); # remove mine marking			
		} # for $Y
	} # for $X
}

sub create_mines {
	my $createdMines = 0;
	while ($createdMines < $numMines) {
		my $mineIndex = int (rand($total));
		my $Ymine = int ($mineIndex / $numX) + 1;
		my $Xmine = $mineIndex % $numX + 1;
		my $key = "$Xmine\_$Ymine";
		if (! $mine{$key} ) {
			$mine{$key} = $key;
			++$createdMines;
			#print "mine $key\n";
		}
	} # for $mines
}

sub draw_rectangles {
	for $X (1..$numX) {
		for $Y (1..$numY) {
			my $key = "$X\_$Y";
			my $startX = $border + ($X - 1) * ($size + $space);
			my $startY = $border + ($Y - 1) * ($size + $space);
			my $endX = $startX + $size;
			my $endY = $startY + $size;
			my $tag = "rect_$key";
			my $color = $grid_color;
			if ($mine{$key}) {
				#$color = 'red';
			}
			$canvas->createRectangle ($startX, $startY, $endX, $endY,
									  -outline => 'black',
									  -fill => $color,
									  -tag => $tag);
			if ($mine{$key}) {
				#my $centerX = $startX + $size / 2;
				#my $centerY = $startY + $size / 2;
				#$canvas->createText($centerX, $centerY, 
				#					-anchor => "center",
				#					-text => "*",
				#					-tag => "text_$key");
			}
		} # for Y
	} # for X
}

sub enter_box {
    my($c) = @_;	
	#update_time();
    my $id = $c->find("withtag", "current");
	@list = $canvas->gettags($id);
	$found = "";
	foreach (@list) {
		if (/(\w+)_(\d+_\d+)/) {
			$word = $1;
			$found = $2;
			last;
		}
	}
	$currentkey = $found;
	$prettykey = sprintf ("%-5s", $currentkey);
	if ($found) {
		if ($checked{$found}) {
			$color = 'white';
		} elsif ($marked{$found}) {
			$color = 'orange';
		} else {
			$color = 'blue';
		}
		change_rect_color ($found, $color);
	}
}

sub leave_box {
    my($c,) = @_;	
	#update_time();
    my $id = $c->find(qw/withtag current/);
	$found = "";
	@list = $canvas->gettags($id);
	foreach (@list) {
		if (/(\w+)_(\d+_\d+)/) {
			$word = $1;
			$found = $2;
			last;
		}
	}
	$currentkey = "";
	$prettykey = "";
	if ($found) {
		if ($checked{$found}) {
			$color = 'white';
		} elsif ($marked{$found}) {
			$color = 'orange';
		} else {
			$color = $grid_color;
		}
		change_rect_color ($found, $color);
	}
}

sub show_mines {
	my $mineKey;
	# show real mines
	foreach $mineKey (%mine) {
		my $id = $canvas->find("withtag", "rect_$mineKey");
		$canvas->itemconfigure($id, -fill => 'red');
	}
	# show marked mines
	foreach $mineKey (%marked) {
		if ($mine{$mineKey}) {
			# a correctly marked mine
			my $id = $canvas->find("withtag", "mine_$mineKey");
			$canvas->delete($id); # remove mine marking
			place_text($mineKey, $mine_mark, 'blue', "mine_$mineKey");
			
		} else {
			# an incorrectly marked mine
			my $id = $canvas->find("withtag", "mine_$mineKey");
			$canvas->delete($id); # remove mine marking
			place_text($mineKey, "X", 'green', "mine_$mineKey");
		}
	}
	# disable the game
	change_message ("Sorry.  You lose. :-)");
	$game_over = "true";
	bind_stop();
	$canvas->Tk::bind("<ButtonRelease-3>", \&start_game);
}

sub num_near_mines {
	my ($key) = @_;
	my ($x, $y, $retval);
	my ($keyX, $keyY) = split_key($key);
	$retval = 0;
	for ($x = $keyX - 1; $x <= $keyX + 1; ++$x) {
		for ($y = $keyY - 1; $y <= $keyY + 1; ++$y) {
			if ($mine{"$x\_$y"}) {
				++$retval;
			}
		} # for $y
	} # for $x
	return $retval;
}

sub split_key {
	my ($key) = @_;
	if ($key =~ /(\d+)_(\d+)/) {
		return ($1, $2);
	} 
	# error condition
	return (0, 0);
}

sub place_text {
	my ($key, $text, $color, $textkey) = @_;
	my ($X, $Y) = split_key($key);
	my $startX = $border + ($X - 1) * ($size + $space);
	my $startY = $border + ($Y - 1) * ($size + $space);
	my $centerX = $startX + $size / 2;
	my $centerY = $startY + $size / 2;
    $canvas->createText($centerX, $centerY, 
                        -anchor => "center",
                        -fill => $color,
                        -text => $text,
                        -tag => $textkey,
                        -font => 'big');
}	

sub place_number {
	my ($key, $num) = @_;
	$number{$key} = $num;
	return unless $num;
	place_text ($key, $num, $colors[$num - 1], "text_$key", 'big');
}

sub check_spot {
	my ($key) = @_;
	return if ($marked{$key});
	if ($mine{$key}) {
		show_mines();
		change_rect_color ($key, 'orange');
		place_text ($key, "!", 'black', "mine_$key");
		return;
	}
	change_rect_color($key, 'white');
	# o.k.  How many mines are here
	my $num = num_near_mines($key);
	if ($num) {
		place_number($key, $num);
	} else {
		clear_empty_mines($key);
	}
	$checked{$key} = $key; # mark this one as checked
}

sub mark_a_bunch {
	my ($key) = @_;
	my $numMarked = 0;
	my ($X, $Y) = split_key($key);
	# are X and Y in range
	return if (($X <= 0) || ($Y <= 0));
	return if (($X > $numX) || ($Y > $numY));
	# loop through all blocks within 1
	for ($x = $X - 1; $x <= $X + 1; ++$x) {
		# make sure $x is in a good range
		next if (($x <= 0) || ($x > $numX)); 
		for ($y = $Y - 1; $y <= $Y + 1; ++$y) {
			next if (($y <= 0) || ($y > $numY));
			next if (($x == $X) && ($y == $Y));
			my $tempkey = "$x\_$y";
			++$numMarked if ($marked{$tempkey} || ! $checked{$tempkey});
		} # for $y
	} # for $x
	return 0 unless ($numMarked == $number{$key});
	# now let's marked everything that isn't already
	# loop through all blocks within 1
	for ($x = $X - 1; $x <= $X + 1; ++$x) {
		next if (($x <= 0) || ($x > $numX)); 
		for ($y = $Y - 1; $y <= $Y + 1; ++$y) {
			next if (($y <= 0) || ($y > $numY));
			next if (($x == $X) && ($y == $Y));
			my $tempkey = "$x\_$y";
			mark_mine ($tempkey) unless $marked{$tempkey};
		} # for $y
	} # for $x
	return 1;
}

sub remove_a_bunch {
	my ($key) = @_;
	return if (!$checked{$key});
	# maybe we should mark a bunch instead of removing a bunch
	return if mark_a_bunch($key);
	# count number of marked mines in immediate neighborhood
	my $numMarked = 0;
	my ($X, $Y) = split_key($key);
	# are X and Y in range
	return if (($X <= 0) || ($Y <= 0));
	return if (($X > $numX) || ($Y > $numY));
	# loop through all blocks within 1
	for ($x = $X - 1; $x <= $X + 1; ++$x) {
		# make sure $x is in a good range
		next if (($x <= 0) || ($x > $numX)); 
		for ($y = $Y - 1; $y <= $Y + 1; ++$y) {
			next if (($y <= 0) || ($y > $numY));
			next if (($x == $X) && ($y == $Y));
			my $tempkey = "$x\_$y";
			++$numMarked if ($marked{$tempkey});
		} # for $y
	} # for $x
	return unless ($numMarked == $number{$key});
	#print "\nkey $key\n";
	my $Xstart = $X - 1;
	my $Xstop =  $X + 1;
	my $Ystart = $Y - 1;
	my $Ystop =  $Y + 1;
	my ($x, $y);
	++$Xstart if ($Xstart <= 0);
	--$Xstop  if ($Xstop > $numX);
	++$Ystart if ($Ystart <= 0);
	--$Ystop  if ($Ystop > $numY);
	#print "Xstart $Xstart Xstop $Xstop Ystart $Ystart Ystop $Ystop\n";
	for ($x = $Xstart; $x <= $Xstop; ++$x) {
		for ($y = $Ystart; $y <= $Ystop; ++$y) {
			my $tempkey = "$x\_$y";
			#print "checking $tempkey\n";
			next if (($x == $X) && ($y == $Y));
			#print "checked\n";
			check_spot($tempkey) if (! $marked{$tempkey});
		} # for $y
	} # for $x
	#print "finished remove_a_bunch\n";
}

sub unmark_mine {
	my ($key) = @_;
	return if (! $marked{$key});
	change_rect_color($key, $grid_color);
	++$numFound;
	my $id = $canvas->find("withtag", "mine_$key");
	$canvas->delete($id); # remove mine marking
	delete $marked{$key};
}

sub mark_mine {
	my ($key) = @_;
	# don't mark something if we know nothing's there
	return if ($checked{$key}); 
	if ($marked{$key}) {
		# this is currently marked.  Unmark it
		unmark_mine($key);
	} else {
		# mark it
		$marked{$key} = $key;
		change_rect_color($key, 'orange');
		--$numFound;
		place_text($key, $mine_mark, 'red', "mine_$key");
		if (0 == $numFound) {
			my $numMatched = 0;
			foreach (keys %mine) {
				++$numMatched if ($marked{$_});
			}
			if ($numMines == $numMatched) {
				change_message ("Hey!  You've done it.  You won!");
				$game_over = "true";
				bind_stop();
			}
		}
	}
}

sub start_click {
	$startkey = $currentkey;
}

sub right_click {
	#update_time();
	return unless ($currentkey && ($startkey eq $currentkey));
	#bind_start();
	mark_mine($currentkey);
	#bind_start();
}

sub left_click {
	return unless ($currentkey && ($startkey eq $currentkey));
	# Has it been checked before?
	if ($checked{$currentkey}) {
        double_left_click();
        return;
    }
	bind_stop();
	change_message ("Checking spot");
	check_spot($currentkey);
	change_message ("") unless $game_over;
	bind_start() unless $game_over;
}

sub double_left_click {
	#update_time();
	return unless ($currentkey && ($startkey eq $currentkey));
	bind_stop();
	change_message ("Clearing out a bunch of mines...");
	remove_a_bunch($currentkey);
	change_message ("") unless $game_over;
	bind_start() unless $game_over;
}

sub change_rect_color {
	my ($key, $color) = @_;
	my $id = $canvas->find("withtag", "rect_$key");
	$canvas->itemconfigure($id, 
						   -fill => $color);
}

sub clear_empty_mines {
	my ($key) = @_;
	return if ($doublechecked{$key}); # already been done
	$doublechecked{$key} = $key; # only do this once
	my ($X, $Y) = split_key($key);
	# are X and Y in range
	return if (($X <= 0) || ($Y <= 0));
	return if (($X > $numX) || ($Y > $numY));
	# loop through all blocks within 1
	my $Xstart = $X - 1;
	my $Xstop =  $X + 1;
	my $Ystart = $Y - 1;
	my $Ystop =  $Y + 1;
	my ($x, $y);
	++$Xstart if ($Xstart <= 0);
	--$Xstop  if ($Xstop > $numX);
	++$Ystart if ($Ystart <= 0);
	--$Ystop  if ($Ystop > $numY);
	#print "Xstart $Xstart Xstop $Xstop Ystart $Ystart Ystop $Ystop\n";
	for ($x = $Xstart; $x <= $Xstop; ++$x) {
		for ($y = $Ystart; $y <= $Ystop; ++$y) {
			my $tempkey = "$x\_$y";
			# make sure $y is in a good range
			#already cleared the center
			next if (($x == $X) && ($y == $Y));
			next if ($checked{$tempkey}); #already been done;
			$checked{$tempkey} = $tempkey; # only do this once
			check_spot($tempkey);
			change_rect_color ($tempkey, 'white');
			#check_spot($tempkey);
		} # for $y
	} # for $x
}

sub bind_start {
	$canvas->bind('all', '<Any-Enter>' => [\&enter_box]);
	$canvas->bind('all', '<Any-Leave>' => [\&leave_box]);
	$canvas->Tk::bind("<ButtonPress-1>", \&start_click);
	$canvas->Tk::bind("<ButtonPress-2>", \&start_click);
	$canvas->Tk::bind("<ButtonPress-3>", \&start_click);
	$canvas->Tk::bind("<ButtonRelease-1>", \&left_click);
	$canvas->Tk::bind("<ButtonRelease-3>", \&right_click);
	$canvas->Tk::bind("<Double-Button-1>", \&double_left_click);
	$canvas->Tk::bind("<ButtonRelease-2>", \&double_left_click);
}

sub bind_stop {
	$canvas->bind('all', '<Any-Enter>' => [\&nothing]);
	$canvas->bind('all', '<Any-Leave>' => [\&nothing]);
	$canvas->Tk::bind("<ButtonRelease-1>", \&nothing);
	$canvas->Tk::bind("<ButtonRelease-3>", \&nothing);
	$canvas->Tk::bind("<Double-Button-1>", \&nothing);
	$canvas->Tk::bind("<ButtonRelease-2>", \&nothing);
}

sub where_item {
	my ($canv, $x, $y) = @_;
	$x = $canv->canvasx($x);
	$y = $canv->canvasy($y);
	$textcoords = sprintf ("x %4d   y %4d", $x, $y);
}

sub nothing {
}

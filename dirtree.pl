#!/bin/perl

#initialize dir_list & count
#$#dir_list = $[ - 1; # could use splice(@dir_list, 0, $#dir_list + 1) or @dirlist = ();
@dir_list = ();
$count = 0;
#start dir_list
if ($#ARGV == -1) {
	push @ARGV, ".";
	#print "ARGC $#ARGV :", join (":", @ARGV), ":\n"
}
@dir_list = @ARGV;
#print "dir list: $#dir_list :", join (":", @dir_list), ":\n";
#push (@dir_list, $ARGV[0]);
while ($count <= $#dir_list)
{
	opendir (DIRECTORY, $dir_list[$count]);
	#|| warn ("Can't open directory $dir_list[$count].\n");
	$current = $dir_list[$count];
	# make sure current ends with a '/'
	$current .= "/"	unless ($current =~ m|/$|); # could be m#/$#, etc.
	while ($filename = readdir (DIRECTORY))
	{
		if (($filename ne ".") && ($filename ne "..")) {
			if (( -d $current.$filename) && !(-l $current.$filename)) {
				push (@dir_list, $current.$filename);
			}
		}
	}
	closedir (DIRECTORY);
	$count++;
}
#print $#dir_list, " dl\n";
if ($#dir_list > 0) {
	#print "Sorting...\n";
	@dir_list = sort @dir_list;
	print join ("\n", @dir_list), "\n";
} else {
	print "$ARGV[0] is not a valid directory or has no subdirectories.\n";
}



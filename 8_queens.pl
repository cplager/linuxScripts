#!/usr/local/bin/perl -w

use strict;
use warnings;

my @fact = (1, 1, 2, 6, 24, 120, 720, 5040, 40320);

sub decode8 {
   my $index = shift;
   my @list = (1, 2, 3, 4, 5, 6, 7, 8);
   my @retval = ();
   for (my $loop = 8; $loop >= 2; --$loop) {
	  my $value = int ($index / $fact[$loop - 1]);
	  $index -= $value * $fact[$loop - 1];
	  my $bla = splice @list, $value, 1;
	  push @retval, $bla;
   }							# for $loop
   push @retval, $list[0];
   return @retval;
}

sub is_array_unique {
   my %hash = ();
   while (@_) {
	  my $element = shift @_;
	  if (defined $hash{$element}) {
		 return;
	  }
	  $hash{$element} = "true";
   }
   return "true";
}


# main program
my $found = 0;
for my $index (0..40319) {
   my @list =decode8($index);
   die "problem $index : @list\n" unless is_array_unique(@list);
   my @sum = my @diff = ();
   for my $loop (0..7) {
	  push @sum, $loop + $list[$loop];
	  push @diff, $loop - $list[$loop];
   }							# for $loop
   if ((is_array_unique(@sum)) && (is_array_unique(@diff))) {
	  print "@list\n";
	  ++$found;
   }
}
print "found $found\n";

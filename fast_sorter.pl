#!/usr/bin/perl -w

use strict;
use Getopt::Long;
use Pod::Usage;

# Setup main variables from script arguments
my ($unique, $sort, $count, $quiet, $DEBUG);

# Grab the options passed on the command line.
GetOptions (
  "unique|u" => \$unique,              # flag
  "sort|s" => \$sort,                  # flag
  "count|c" => \$count,                # flag
  "quiet|q" => \$quiet,                # flag
  "verbose|v" => \$DEBUG,              # flag
  "help|?|h" => sub { pod2usage(1); }, # flag
) or pod2usage("$0: Unrecognized program argument.");

if( !( defined($unique) or defined($sort) or defined($count) ) ) {
  pod2usage("$0:  Required argument missing.");
}

my ( %hash, $key, $value );

if ( $unique ) {
  print "Entered unique loop\n" if $DEBUG;

  while( my $mac = <> ) {
    next unless $mac;
    chomp $mac;

    $hash{$mac}++;
  }

  # Do all the prints here
  if ( $sort ) {
    print "Entered sorted print loop\n" if $DEBUG;

    for $key ( sort keys %hash ) {
      if ( $count ) {
        print "$hash{$key} \t$key\n";
      }
      else {
        print "$key\n";
      }
    }
  }
  else {
    print "Entered unsorted print loop\n" if $DEBUG;
    for $key (keys %hash) { 
      if ( $count ) {
        print "$hash{$key} \t$key\n";
      }
      else {
        print "$key\n";
      }
    }
  }
}

if ( $sort and not $unique ) {
  # Join to an array and sort for print
  print "So you want sorted but not uniqued data, eh? Patience my dear, patience.\n"
}

__END__

=head1 NAME

fast_sorter - Reimplementation of GNU sort and GNU uniq to perform faster
by Scott Pack

=head1 SYNOPSIS

fast_sorter.pl [options]

 Options:
   -u, --unique     Deduplicate entries in the input
   -s, --sort       Print the output ASCII sorted
   -c, --count      Print the output along with duplication counts
   -v, --verbose    Print debugging information
   -h, --help       Brief help message


By Scott Pack

=cut

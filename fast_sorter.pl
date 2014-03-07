#!/usr/bin/perl -w

use strict;
use Getopt::Long;
use Pod::Usage;

# Setup main variables from script arguments
my $unique;
my $sort; 
my $count;
my $quiet;                                             # Declare the variable for setting the 'quiet' flag.
my $DEBUG;

# Grab the options passed on the command line.
GetOptions (
    "unique|u" => \$unique,              # flag
    "sort|s" => \$sort,                  # flag
    "count|c" => \$count,                # flag
    "quiet|q" => \$quiet,                # flag
    "verbose|v" => \$DEBUG,              # flag
    "help|?|h" => sub { pod2usage(1); }, # flag
) or pod2usage("$0: Unrecognized program argument.");

if( !( defined($unique) or defined($sort) or defined($count) ) )
{
    pod2usage("$0:  Required argument missing.");
}


if( $DEBUG )
{
  print "Count => TRUE\n" if $count;
  print "Unique => TRUE\n" if $unique;
  print "Sort => TRUE\n" if $sort;
}


my %hash;
my $key;
my $value;

if ( $unique )
{

  print "Entered unique loop\n" if $DEBUG;

  while( my $mac = <> )
  {
    next unless $mac;
    chomp $mac;

    $hash{$mac}++;
  }


# Do all the prints here
  if ( $sort )
  {
    print "Entered sorted print loop\n" if $DEBUG;

    #while ( ($key, $value) = each(%hash) ) 
    for $key ( sort keys %hash )
    {
      if ( $count )
      {
        print "$hash{$key} \t$key\n";
      }
      else
      {
        print "$key\n";
      }
    }
  }
  else
  {
    print "Entered unsorted print loop\n" if $DEBUG;
    for $key (keys %hash)
    { 
      if ( $count )
      {
        print "$hash{$key} \t$key\n";
      }
      else
      {
        print "$key\n";
      }
    }
  }
}

if ( $sort and not $unique )
{
  # Join to an array and sort for print
  print "So you want sorted but uniqued data, eh? Patience my dear, patience.\n"
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

#!/usr/bin/perl
# File    : nessus_installed_software.pl
# Author  : Scott Pack
# Created : October 2016
# Purpose : Process an exported Nessus scan to generated Installed
#           Software verision report.
#
#     Copyright (c) 2016 Scott Pack. 
#     Creative Commons Attribution-NonCommercial-NoDerivs 3.0
#
#
#
use warnings;
use strict;
use feature "switch"; # Enables switch replacements given/when
use Getopt::Long qw(:config bundling);
use Pod::Usage;
use Data::Dumper;
use Net::IP qw(ip_is_ipv4);
use Date::Parse;
use Text::CSV_XS qw( csv );


# Hash to store all of the command line arguments, along with defaults
my $options = { verbose => 0,
                format => 'csv',
              };

# Grab the options passed on the command line.
GetOptions( $options,
    'nessus|report|n=s',    # Nessus report
    'software|s=s@',        # Specific Application Name
    'out|o=s',              # output file for writing
    'verbose|v+',           # flag
    'quiet|q',              # flag
    'help|?|h' => sub { pod2usage( -verbose => 0, -exitval => 1 ); },    # flag
) or pod2usage("$0: Unrecognized program argument.");

pod2usage("$0: Missing required arguments.") unless (exists($options->{'nessus'}));

# Deep debugging code to dump out all the selected options
if( $options->{'verbose'} >= 4 )
{
  print "Processing based on following program settings:\n";
  while( my ($key, $value) = each %$options )
  {
    if( ref($value) eq "ARRAY" )
    {
      @$value = split(/,/,join(',',@$value));
      print "$key\t@$value\n";
    }
    else
    {
      print "$key\t$value\n";
    }
  }
}

my $report = {};
my $softwarelist = {};

$report = ProcessFile($options->{'nessus'}, $options->{'verbose'});

$softwarelist = ExtractSoftware($report, $options->{'verbose'});

PrintCSV($softwarelist, $options);

#####################
## sub: PrintCSV
##      Chunks out the software list and outputs to CSV
sub PrintCSV
{
  my $softwarelist = shift or die;
  my $options = shift or die;

  my $OUTPUT;

  if( exists( $options->{'out'} ) )
  {
    open( $OUTPUT, ">$options->{'out'}");
  }
  else
  {
    $OUTPUT = *STDOUT;
  }

  print $OUTPUT "Host,Application,Version,Install Date\n";

  foreach my $host (keys %{$softwarelist})
  {
    foreach my $app (keys %{$softwarelist->{$host}})
    {
      print $OUTPUT "\"$host\",\"$app\",\"$softwarelist->{$host}->{$app}->{'Version'}\"";
      print $OUTPUT ",\"$softwarelist->{$host}->{$app}->{'Install Date'}\"" if exists $softwarelist->{$host}->{$app}->{'Install Date'};
      print $OUTPUT "\n";
    }
  }

  close( $OUTPUT );
}

#####################
## sub: ParseInput ( hashref report, logfile, verbosity )
##      Reads in the file and chunks it out into the hash
sub ProcessFile
{
  my $nessus = shift or die;
  my $verbose = shift;

  my $report = csv ( in => $nessus, headers => "auto" );

  return $report;

}

#####################
## sub: ExtractSoftware ( hashref report, hashref args )
##      Processes the report and builds a software inventory
sub ExtractSoftware
{
  my $report = shift or die;
  my $verbose = shift;

  my $softwarelist = {};

  foreach my $host ( @{$report})
  {
    if ( $host->{'Plugin ID'} == '20811')
    {
      my $tmpInstalled = $host->{'Plugin Output'};
      my @installs = split /\n/, $tmpInstalled;

      foreach my $app (@installs)
      {
        # Mozilla Maintenance Service  [version 48.0.1.6073]
        if( $app =~ /([^\[]+)\s+\[version\s+([\d\.]+)\]\s*(?:\[installed on ([\d\/]+)\])?/ )
        {
          $softwarelist->{$host->{'Host'}}->{$1}->{'Version'} = $2;
          $softwarelist->{$host->{'Host'}}->{$1}->{'Install Date'} = $3 if defined $3;
        }
        else
        {
          print "ERR: Could not match: $app\n" if $verbose >= 2;
        }
      }
    }
  }

  return $softwarelist;
}

__END__

# File    : nessus_installed_software.pl
# Author  : Scott Pack
# Created : September 2016
# Purpose : Process an exported Nessus scan to generated Installed
#           Software verision report.

=head1 NAME

nessus_installed_software.pl - Process an exported Nessus scan to generated Installed Software verision report.

=head1 DESCRIPTION

Reads an exported Nessus scan report and enumerates the Installed Software plugin for software version information.

=head1 SYNOPSIS

 nessus_installed_software.pl [options]

 Options:
   -n, --nessus, --report  Full path to the Nessus scan report exported in CSV format (required)
   -s, --software          Application names to report on, can  be provided multiple times.
   -o, --out               Output file name
   -v, --verbose           Be chattier with process output
   -q, --quiet             Only print essential messages
   -h, --help              Brief help message (this one)

=head1 OPTIONS

=over 8

=item B<-n, --nessus, --report>

Full path to the Nessus scan report exported in CSV format

=item B<-s, --software>

Application names to report on, can  be provided multiple times.

=item B<-o, --out>

Output file name

=item B<-v,--verbose>

Be louder with output. Can be given multiple times.

=item B<-q,--quiet>

Suppress all normal and verbose output. Only display errors.

=item B<-h,--help>

Print a brief help message and exits.

=back

=head1 AUTHOR

Scott Pack - L<http://www.google.com/profiles/scott.pack/>

=head1 LICENSE

Copyright (c) 2012 Scott Pack. All rights reserved.
This program is released under Creative Commons Attribution-NonCommercial-NoDerivs 3.0 United States License L<http://creativecommons.org/licenses/by-nc-nd/3.0/us/>.


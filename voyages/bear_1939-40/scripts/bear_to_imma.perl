#!/usr/bin/perl

# Process digitised logbook data from The USS Bear into
#  IMMA records.

use strict;
use warnings;
use lib "/home/hc1300/hadpb/tasks/digitisation/imma/";
use IMMA;
use Getopt::Long;
use FindBin;

my $Ship_name = 'USS Bear';
my ( $Year, $Month, $Day, $Lat, $Lon );

while (<>) {

    if ( $_ !~ /^\s*\d/ ) { next; }    # Discard headers

    my @Fields = split /\t/, $_;

    if ( defined( $Fields[0] ) && $Fields[0] =~ /\d/ ) {
        $Year = $Fields[0];
    }
    if ( defined( $Fields[1] ) && $Fields[1] =~ /\d/ ) {
        $Month = $Fields[1];
    }

    my $Ob = new IMMA;
    $Ob->clear();                      # Why is this necessary?
    push @{ $Ob->{attachments} }, 0;

    $Ob->{YR}  = $Year;
    $Ob->{MO}  = $Month;
    $Ob->{DY}  = $Fields[2];
    $Ob->{HR}  = $Fields[5];
    $Ob->{LAT} = $Fields[3] * -1;

    # Longitude is missing its most significant figure
    if ( $Fields[4] < 80 ) {
        $Ob->{LON} = ( 100 + $Fields[4] ) * -1;
    }
    else {
        $Ob->{LON} = $Fields[4] * -1;
    }
    $Ob->{LI} = 0;    # Degrees and tenths

    # Pressure converted from inches
    $Ob->{SLP} = $Fields[6] * 33.86;

    # Temperatures in F
    if ( defined( $Fields[7] ) && $Fields[7] =~ /\d/ ) {
        $Ob->{SST} = ( $Fields[7] - 32 ) * 5 / 9;
        $Ob->{IT}  = 6;                             # Whole degrees Farenheit
    }

    # Fill in extra metadata
    $Ob->{IM}   = 0;                                # Check with Scott
    $Ob->{ATTC} = 1;                                # Icoads
    $Ob->{TI}   = 0;                                # Nearest hour
    $Ob->{DS}   = undef;                            # Unknown course
    $Ob->{VS}   = undef;                            # Unknown speed
    $Ob->{NID}  = 3;                                # Check with Scott
    $Ob->{II}   = 10;                               # Check with Scott
    $Ob->{ID}   = $Ship_name;
    $Ob->{C1}   = '02';                             # US

    # Add the icoads attachment
    push @{ $Ob->{attachments} }, 1;
    $Ob->{BSI} = undef;
    $Ob->{B10} = undef;    # 10 degree box
    $Ob->{B1}  = undef;    # 1 degree box
    $Ob->{DCK} = 246;      # Deck ID - from Scott
    $Ob->{SID} = 127;      # Source ID - from Scott
    $Ob->{PT}  = 0;        # 'US Navy or "deck" log, or unknown'
    foreach my $Var (qw(DUPS DUPC TC PB WX SX C2)) {
        $Ob->{$Var} = undef;
    }

    # Other elements all missing
    foreach my $Var ( @{ $IMMA::parameters[1] } ) {
        unless ( exists( $Ob->{$Var} ) ) {
            $Ob->{$Var} = undef;
        }
    }

    # Output the IMMA ob
    $Ob->write( \*STDOUT );
}


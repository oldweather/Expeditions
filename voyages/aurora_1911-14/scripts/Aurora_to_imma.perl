#!/usr/bin/perl

# Brocess digitised logbook data from The Aurora into
#  IMMA records.

use strict;
use warnings;
use lib "/home/hc1300/hadpb/tasks/imma/perl_module";
use IMMA;
use Getopt::Long;
use FindBin;

my $Ship_name = 'Aurora';
my ( $Year, $Month, $Day );
my $Last_lon;
my %Map_months = (
    jan => 1,
    feb => 2,
    mar => 3,
    apr => 4,
    may => 5,
    jun => 6,
    jul => 7,
    aug => 8,
    sep => 9,
    oct => 10,
    nov => 11,
    dec => 12
);

while (<>) {
    my @Fields = split /\t/, $_;

    # Discard blank and header lines
    unless ( defined( $Fields[2] ) && $Fields[2] =~ /^\d+$/ ) { next; }

    # Set the year and month if available
    if ( defined( $Fields[0] ) && $Fields[0] =~ /(\d\d\d\d) +(\w+)/ ) {
        $Year = $1;
        $Month = $Map_months{ lc( substr( $2, 0, 3 ) ) };
    }
    elsif(defined( $Fields[0] ) && $Fields[0] =~ /(\w+)/ ) {
        $Month = $Map_months{ lc( substr( $1, 0, 3 ) ) };
    }

    # Set the day if available
    if ( defined( $Fields[1] ) && $Fields[1] =~ /^\d+$/ ) {
        $Day = $Fields[1];
    }

    my $Ob = new IMMA;
    $Ob->clear();    # Why is this necessary?
    push @{ $Ob->{attachments} }, 0;

    # Set the position
    if (   ( defined( $Fields[3] ) && lc( $Fields[3] ) =~ /kembla/ )
        || ( defined( $Fields[4] ) && lc( $Fields[4] ) =~ /kembla/ ) )
    {
        $Ob->{LAT} = -34.4667;
        $Ob->{LON} = 150.9000;
        $Last_lon  = $Ob->{LON};
        $Ob->{LI}  = 6;            # Position from MetaData
    }
    elsif (( defined( $Fields[3] ) && lc( $Fields[3] ) =~ /macquarie/ )
        || ( defined( $Fields[4] ) && lc( $Fields[4] ) =~ /macquarie/ ) )
    {
        $Ob->{LAT} = -54.5;
        $Ob->{LON} = 158.95;
        $Last_lon  = $Ob->{LON};
        $Ob->{LI}  = 6;            # Position from MetaData
    }
    elsif (( defined( $Fields[3] ) && lc( $Fields[3] ) =~ /commonwealth bay/ )
        || ( defined( $Fields[4] ) && lc( $Fields[4] ) =~ /commonwealth bay/ ) )
    {
        $Ob->{LAT} = -66.9;
        $Ob->{LON} = 142.67;
        $Last_lon  = $Ob->{LON};
        $Ob->{LI}  = 6;            # Position from MetaData
    }
    elsif (( defined( $Fields[3] ) && lc( $Fields[3] ) =~ /western base/ )
        || ( defined( $Fields[4] ) && lc( $Fields[4] ) =~ /western base/ ) )
    {
        $Ob->{LAT} = -66.5;        # Approximate
        $Ob->{LON} = 95.00;
        $Last_lon  = $Ob->{LON};
        $Ob->{LI}  = 6;            # Position from MetaData
    }
    elsif (( defined( $Fields[3] ) && lc( $Fields[3] ) =~ /auckland/ )
        || ( defined( $Fields[4] ) && lc( $Fields[4] ) =~ /auckland/ ) )
    {
        $Ob->{LAT} = -50.7;        # Auckland Island, not City
        $Ob->{LON} = 166.1;
        $Last_lon  = $Ob->{LON};
        $Ob->{LI}  = 6;            # Position from MetaData
    }
    elsif (( defined( $Fields[3] ) && lc( $Fields[3] ) =~ /hobart/ )
        || ( defined( $Fields[4] ) && lc( $Fields[4] ) =~ /hobart/ ) )
    {
        $Ob->{LAT} = -42.8;        # City
        $Ob->{LON} = 147.5;
        $Last_lon  = $Ob->{LON};
        $Ob->{LI}  = 6;            # Position from MetaData
    }
    elsif (( defined( $Fields[3] ) && lc( $Fields[3] ) =~ /iron pot/ )
        || ( defined( $Fields[4] ) && lc( $Fields[4] ) =~ /iron pot/ ) )
    {
        $Ob->{LAT} = -43.5;
        $Ob->{LON} = 147.14;
        $Last_lon  = $Ob->{LON};
        $Ob->{LI}  = 6;            # Position from MetaData
    }
    else {                         # Try for numeric
        if ( defined( $Fields[3] ) && $Fields[3] =~ /(\d+) ([\d\.]+)/ )
        {
            $Ob->{LAT} = ( $1 + $2 / 60 ) * -1;
        }
        if ( defined( $Fields[4] ) && $Fields[4] =~ /(\d+) ([\d\.]+)/ )
        {
            $Ob->{LON} = $1 + $2 / 60;
            $Last_lon = $Ob->{LON};
        }
        if ( defined( $Ob->{LAT} ) || defined( $Ob->{LON} ) ) {
            $Ob->{LI} = 4;    # Deg+Min position precision
        }
    }

    # Set the date
    $Ob->{YR} = $Year;
    $Ob->{MO} = $Month;
    $Ob->{DY} = $Day;
    $Ob->{HR} = $Fields[2];
    correct_hour_for_lon_ndl($Ob);

    # Pressure converted from inches
    if ( defined( $Fields[5] ) && $Fields[5] =~ /\d/ ) {
        $Ob->{SLP} = $Fields[5] * 33.86;
    }

    # Temperatures converted from Farenheit
    if ( defined( $Fields[6] ) && $Fields[6] =~ /\d/ ) {
        $Ob->{AT} = ( $Fields[6] - 32 ) * 5 / 9;
    }

    # Fill in extra metadata
    $Ob->{IM}   = 0;          # Check with Scott
    $Ob->{ATTC} = 2;          # icoads and supplemental
    $Ob->{TI}   = 0;          # Nearest hour time precision
    $Ob->{DS}   = undef;      # Unknown course
    $Ob->{VS}   = undef;      # Unknown speed
    $Ob->{NID}  = 3;          # Check with Scott
    $Ob->{II}   = 10;         # Check with Scott
    $Ob->{ID}   = 'Aurora';
    $Ob->{C1}   = '03';       # UK recruited
    if (   defined( $Ob->{AT} )
        || defined( $Ob->{WBT} )
        || defined( $Ob->{DPT} )
        || defined( $Ob->{SST} ) )
    {
        $Ob->{IT} = 4;        # Temps in degF and 10ths
    }

    # Add the icoads attachment
    push @{ $Ob->{attachments} }, 1;
    $Ob->{BSI} = undef;
    $Ob->{B10} = undef;       # 10 degree box
    $Ob->{B1}  = undef;       # 1 degree box
    $Ob->{DCK} = 246;         # Deck ID - from Scott
    $Ob->{SID} = 127;         # Source ID - from Scott
    $Ob->{PT}  = 1;           # 'merchant ship or foreign military'
    foreach my $Var (qw(DUPS DUPC TC PB WX SX C2)) {
        $Ob->{$Var} = undef;
    }

    # Other elements all missing
    foreach my $Var ( @{ $IMMA::parameters[1] } ) {
        unless ( exists( $Ob->{$Var} ) ) {
            $Ob->{$Var} = undef;
        }
    }

    $Ob->write( \*STDOUT );

}

# Correct to UTC from local time.
# This is done independently for each ob - in practise the
# ship probably corrected its time only once each 24 hrs, but I don't know when,
# so I haven't tried to follow this. (This was standard practice - but
# it makes less sense in the polar regions so they might have done something
# different).
# Also, It's apparent from the uncorrected times that the ship
# Did not change its date when crossing the date line, so in doing the
# correction I've converted longitudes west to longitudes east > 180.
sub correct_hour_for_lon_ndl {
    my @Days_in_month = ( 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31 );
    my $Ob            = shift;
    unless ( defined($Last_lon)
        && defined( $Ob->{HR} )
        && defined( $Ob->{DY} )
        && defined( $Ob->{MO} )
        && defined( $Ob->{YR} ) )
    {
        $Ob->{HR} = undef;
        return;
    }
    my $Lon_C = $Last_lon;
    if ( $Lon_C < 0 ) { $Lon_C += 360; }    # No date line
    if ( $Ob->{YR} % 4 == 0
        && ( $Ob->{YR} % 100 != 0 || $Ob->{YR} % 400 == 0 ) )
    {
        $Days_in_month[1] = 29;
    }
    $Ob->{HR} += $Lon_C * 12 / 180;
    if ( $Ob->{HR} < 0 ) {
        $Ob->{HR} += 24;
        $Ob->{DY}--;
        if ( $Ob->{DY} < 0 ) {
            $Ob->{MO}--;
            if ( $Ob->{MO} < 1 ) {
                $Ob->{YR}--;
                $Ob->{MO} = 12;
            }
            $Ob->{DY} = $Days_in_month[ $Ob->{MO} - 1 ];
        }
    }
    if ( $Ob->{HR} > 23.99 ) {
        $Ob->{HR} -= 24;
        if ( $Ob->{HR} < 0 ) { $Ob->{HR} = 0; }
        $Ob->{DY}++;
        if ( $Ob->{DY} > $Days_in_month[ $Ob->{MO} - 1 ] ) {
            $Ob->{DY} = 1;
            $Ob->{MO}++;
            if ( $Ob->{MO} > 12 ) {
                $Ob->{YR}++;
                $Ob->{MO} = 1;
            }
        }
    }
    return 1;
}


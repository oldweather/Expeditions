#!/usr/bin/perl

# Process digitised logbook data from the Uranie into
#  IMMA records.

use strict;
use warnings;
use IMMA;
use Getopt::Long;
use FindBin;

my $Ship_name = 'Uranie';
my ( $Year, $Month, $Day );
my $Last_lon;
my $Lat_flag = 'N';
my $Lon_flag = 'E';

for ( my $i = 0 ; $i < 2987 ; $i++ ) { <>; }    # Skip headers and port data

while (<>) {
    unless ( $_ =~ /^[\s1]/ ) { next; }
    my $Ob = new IMMA;
    $Ob->clear();                               # Why is this necessary?
    push @{ $Ob->{attachments} }, 0;
    my @Fields = split /\t/, $_;
    unless ( @Fields > 4 ) { next; }
    
    if ( defined( $Fields[0] ) && $Fields[0] =~ /\d/ ) {
        $Year = $Fields[0];
    }
    if ( defined( $Fields[1] ) && $Fields[1] =~ /\d/ ) {
        $Month = $Fields[1];
    }
    if ( defined( $Fields[2] ) && $Fields[2] =~ /\d/ ) {
        $Day = $Fields[2];

        #        printf "%04d/%02d/%02d\n",$Year,$Month,$Day
    }
    $Ob->{YR} = $Year;
    $Ob->{MO} = $Month;
    $Ob->{DY} = $Day;

    $Ob->{HR} = $Fields[3] / 100;

    if ( defined( $Fields[4] ) && $Fields[4] =~ /[a-z]/ ) {    # Port name
        ( $Ob->{LAT}, $Ob->{LON} ) = position_from_port( $Fields[3] );
        $Ob->{LI} = 6;    # Position from metadata
    }
    else {
        if ( defined( $Fields[4] )
            && $Fields[4] =~ /(\d+)\s+([\d\.]+)\s*([NS]*)/ )
        {
            $Ob->{LAT} = $1 + $2 / 60;
            if ( defined($3) && ( $3 eq 'N' || $3 eq 'S' ) ) { $Lat_flag = $3; }
            if ( $Lat_flag eq 'S' ) { $Ob->{LAT} *= -1; }
        }
        if ( defined( $Fields[5] )
            && $Fields[5] =~ /(\d+)\s+([\d.]+)\s*([EW]*)/ )
        {
            $Ob->{LON} = $1 + $2 / 60;
            if ( defined($3) && ( $3 eq 'E' || $3 eq 'W' ) ) { $Lon_flag = $3; }
            if ( $Lon_flag eq 'W' ) { $Ob->{LON} *= -1; }
            $Ob->{LON} += 2.33;    # Paris longitudes
            if($Ob->{LON}>180) { $Ob->{LON} -= 360; }
        }
        if ( defined( $Ob->{LAT} ) || defined( $Ob->{LON} ) ) {
            $Ob->{LI} = 4;         # Deg+Min position precision
        }
    }
    if ( defined( $Ob->{LON} ) ) { $Last_lon = $Ob->{LON}; }

    correct_hour_for_lon($Ob);

    # Pressure converted from mm
    if ( defined( $Fields[6] ) && $Fields[6] =~ /(\d+)/ ) {
        $Ob->{SLP} = $Fields[6] * 1.33322387415;
    }

    # Fill in extra metadata
    $Ob->{IM}   = 0;            # Check with Scott
    $Ob->{ATTC} = 0;            # No attachments
    $Ob->{TI}   = 0;            # Nearest hour time precision
    $Ob->{DS}   = undef;        # Unknown course
    $Ob->{VS}   = undef;        # Unknown speed
    $Ob->{NID}  = undef;        # Check with Scott
    $Ob->{II}   = 10;           # Check with Scott
    $Ob->{ID}   = $Ship_name;
    $Ob->{C1}   = '04';         # French
    if (   defined( $Ob->{AT} )
        || defined( $Ob->{WBT} )
        || defined( $Ob->{DPT} )
        || defined( $Ob->{SST} ) )
    {
        $Ob->{IT} = 0;          # Temps in degC and 10ths
    }

    $Ob->write( \*STDOUT );

}

# Correct the date to UTC from local time
# Don't change the day when crossing the date line
sub correct_hour_for_lon {
    my @Days_in_month = ( 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31 );
    my $Ob = shift;
    unless ( defined($Last_lon)
        && defined( $Ob->{HR} )
        && defined( $Ob->{DY} )
        && defined( $Ob->{MO} )
        && defined( $Ob->{YR} ) )
    {
        $Ob->{HR} = undef;
        return;
    }
    if ( $Ob->{YR} % 4 == 0
        && ( $Ob->{YR} % 100 != 0 || $Ob->{YR} % 400 == 0 ) )
    {
        $Days_in_month[1] = 29;
    }
    my $Effective_lon = $Last_lon;
    if($Effective_lon < 0) { $Effective_lon += 360; } # No date line
    $Ob->{HR} += $Effective_lon * 12 / 180;
    if ( $Ob->{HR} < 0 ) {
        $Ob->{HR} += 24;
        $Ob->{DY}--;
        if ( $Ob->{DY} <= 0 ) {
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
    if ( $Ob->{HR} == 23.99 ) { $Ob->{HR} = 23.98; }
    return 1;
}

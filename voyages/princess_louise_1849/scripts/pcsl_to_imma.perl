#!/usr/bin/perl

# Process digitised logbook data from the Princess Louise into
#  IMMA records.

# Two records for each day, as two temperature measurements.

use strict;
use warnings;
use IMMA;
use FindBin;
use Date::Calc qw(Add_Delta_Days Delta_Days Delta_DHMS check_date);

use MarineOb::lmrlib qw(fxtrtc ixdtnd rxltut rxnddt fxeimb fwbptc fwbpgv);

# Load the obs and convert to IMMA
my $Ship_name = 'PcLouise';
my $Last_lat;
my $Last_lon;
my @LL_ymdh;
my ( $Year, $Month, $Day, $Hour );
my $Lon_f  = 'W';
my $Lat_f  = 'N';
my $InPort = 0;

for ( my $i = 0 ; $i < 4 ; $i++ ) { <>; }    # Skip headers

while ( my $Line = <> ) {
    unless ( $Line =~ /\d/ ) { next; }
    my $Ob = new IMMA;
    $Ob->clear();                            # Why is this necessary?
    push @{ $Ob->{attachments} }, 0;
    $Ob->{ID} = $Ship_name;
    my @Fields = split /\t/, $Line;

    if ( defined( $Fields[0] ) && $Fields[0] =~ /\d/ ) { $Year  = $Fields[0]; }
    if ( defined( $Fields[1] ) && $Fields[1] =~ /\d/ ) { $Month = $Fields[1]; }
    if ( defined( $Fields[2] ) && $Fields[2] =~ /\d/ ) { $Day   = $Fields[2]; }
    if ( defined( $Fields[3] ) && $Fields[3] =~ /\d/ ) {
        $Hour = $Fields[3];
        if ( $Hour == 2 ) { $Hour += 12; }
        if ( $Hour == 9 ) { $Hour += 12; }
    }

    #    else { $Ob->{ID} .= "2"; $Hour +=0.01;}    # Second thermometer

    $Ob->{YR} = $Year;
    $Ob->{MO} = $Month;
    $Ob->{DY} = $Day;
    $Ob->{HR} = $Hour;

    if ( defined( $Fields[5] ) ) {
        if ( $Fields[5] =~ /^[Nn]/ ) { $Lat_f = 'N'; }
        if ( $Fields[5] =~ /^[Ss]/ ) { $Lat_f = 'S'; }
    }
    if ( defined( $Fields[4] ) && $Fields[4] =~ /\d/ ) {
        if ( $Fields[4] =~ /(\d+)\D+(\d+)/ ) {
            $Ob->{LAT} = $1 + $2 / 60;
            if ( $Lat_f eq 'S' ) { $Ob->{LAT} *= -1; }
            $Last_lat = $Ob->{LAT};
            @LL_ymdh = ( $Year, $Month, $Day, $Hour );
        }
        else {
            die "Bad latitude $Fields[4]";
        }
    }
    if ( defined( $Fields[7] ) ) {
        if ( $Fields[7] =~ /^[Ww]/ ) { $Lon_f = 'W'; }
        if ( $Fields[7] =~ /^[Ee]/ ) { $Lon_f = 'E'; }
    }
    if ( defined( $Fields[6] ) && $Fields[6] =~ /\d/ ) {
        if ( $Fields[6] =~ /(\d+)\D+(\d+)/ ) {
            $Ob->{LON} = $1 + $2 / 60;
            if ( $Lon_f eq 'W' ) { $Ob->{LON} *= -1; }
            if ( $Ob->{LON} > 180 ) { $Ob->{LON} -= 360; }
            $Last_lon = $Ob->{LON};
        }
        else {
            die "Bad longitude $Fields[5]";
        }
    }
    if ( defined( $Ob->{LAT} ) || defined( $Ob->{LON} ) ) {
        $Ob->{LI} = 4;    # Deg+Min position precision
    }
    elsif ($LL_ymdh[0] == $Year
        && $LL_ymdh[1] == $Month
        && $LL_ymdh[2] == $Day
        && $LL_ymdh[3] == $Hour )
    {
        $Ob->{LON} = $Last_lon;
        $Ob->{LAT} = $Last_lat;
        $Ob->{LI}  = 4;
    }

    # in Rio from 1849/05/27 to 1846/06/05
    elsif (Delta_Days( 1849, 5, 27, $Year, $Month, $Day ) >= 0
        && Delta_Days( 1849, 6, 5, $Year, $Month, $Day ) <= 0 )
    {
        $Ob->{LON} = -43.18;
        $Ob->{LAT} = -22.9;
        $Ob->{LI}  = 6;        # From metadata
    }

    # Convert dates to UTC
    if ( defined($Last_lon) ) {
        my $elon = $Last_lon;
        if ( $elon < 0 ) {
            $elon += 360;
            if ( $elon > 359.99 ) { $elon = 359.99; }
        }
        my ( $uhr, $udy ) = rxltut(
            $Ob->{HR} * 100,
            ixdtnd( $Ob->{DY}, $Ob->{MO}, $Ob->{YR} ),
            $elon * 100
        );
        $Ob->{HR} = $uhr / 100;
        ( $Ob->{DY}, $Ob->{MO}, $Ob->{YR} ) = rxnddt($udy);
    }
    else { $Ob->{HR} = undef; }

    # Temperatures in Reamur?
    if ( defined( $Fields[9] ) && $Fields[9] =~ /\d/ ) {
        $Ob->{AT} = fxtrtc($Fields[9]);
    }

    # Pressure in english inches?
    if ( defined( $Fields[8] ) && $Fields[8] =~ /\d/ ) {
        $Ob->{SLP} = fxeimb( $Fields[8] );
    }

    # Temperature correction
    if (   defined( $Ob->{SLP} )
        && defined( $Ob->{AT} ) )
    {
        $Ob->{SLP} += fwbptc( $Ob->{SLP}, $Ob->{AT} );
    }
    else { $Ob->{SLP} = undef; }

    # Gravity correction
    if ( defined( $Ob->{SLP} ) && defined($Last_lat) ) {
        $Ob->{SLP} += fwbpgv( $Ob->{SLP}, $Last_lat, 2 );
    }

    # Fill in extra metadata
    $Ob->{IM}   = 0;
    $Ob->{ATTC} = 1;        # supd
    $Ob->{TI}   = 0;        # Nearest hour time precision
    $Ob->{DS}   = undef;    # Unknown course
    $Ob->{VS}   = undef;    # Unknown speed
    $Ob->{NID}  = undef;    #
    $Ob->{II}   = 10;       #
    $Ob->{C1}   = '21';     # FRG - closest possible to Hamburg in 1849
    if (   defined( $Ob->{AT} )
        || defined( $Ob->{WBT} )
        || defined( $Ob->{DPT} )
        || defined( $Ob->{SST} ) )
    {
        $Ob->{IT} = 4;      # Temps in degF and 10ths
    }

    # Add the original record as a supplemental attachment
    push @{ $Ob->{attachments} }, 99;
    $Ob->{ATTE} = undef;
    chomp($Line);
    $Ob->{SUPD} = $Line;

    $Ob->write( \*STDOUT );

}

#!/usr/bin/perl

# Process the digitised Scotia expedition data into
#  IMMA records. Version for 1902-3.

use strict;
use warnings;
use IMMA;
use Getopt::Long;
use FindBin;
use Date::Calc qw(Delta_Days Add_Delta_Days);
use MarineOb::lmrlib
  qw(rxltut ixdtnd rxnddt fxtftc fxeimb fwbptc fwbpgv ix32dd fxbfms);

my $Last_lon = -14;
my $Last_lat = 39.5;
my $Lon_flag = 'W';
my $Lat_flag = 'N';

while ( my $Line = <> ) {
    unless ( $Line =~ /^190/ ) { next; }
    my @Fields = split /\t/, $Line;
    my $Ob = new IMMA;
    $Ob->clear();
    push @{ $Ob->{attachments} }, 0;

    # On the Scotia
    $Ob->{ID} = "Scotia";

    # Date
    if ( $Fields[0] =~ /(\d\d\d\d)/ ) {
        $Ob->{YR} = $1;
    }
    if ( $Fields[1] =~ /(\d+)/ ) {
        $Ob->{MO} = $1;
    }
    if ( $Fields[2] =~ /(\d+)/ ) {
        $Ob->{DY} = $1;
    }
    if ( $Fields[3] =~ /(\d+)/ ) {
        $Ob->{HR} = $1 / 100;
    }
    if ( $Ob->{HR} == 24 ) {
        ( $Ob->{YR}, $Ob->{MO}, $Ob->{DY} ) =
          Add_Delta_Days( $Ob->{YR}, $Ob->{MO}, $Ob->{DY}, 1 );
        $Ob->{HR} = 0;
    }

    if ( defined( $Fields[4] ) && $Fields[4] =~ /(\d+)\.(\d+)/ ) {
        $Ob->{LAT} = $1 + $2 / 60;
        if ( $Fields[4] =~ /([NnSs])/ ) { $Lat_flag = uc($1); }
        if ( $Lat_flag eq 'S' ) { $Ob->{LAT} *= -1; }
    }
    if ( defined( $Fields[5] ) && $Fields[5] =~ /(\d+)\.(\d+)/ ) {
        $Ob->{LON} = $1 + $2 / 60;
        if ( $Fields[5] =~ /([EeWw])/ ) { $Lon_flag = uc($1); }
        if ( $Lon_flag eq 'W' ) { $Ob->{LON} *= -1; }
    }
    if ( defined( $Ob->{LAT} ) || defined( $Ob->{LON} ) ) {
        $Ob->{LI} = 4;    # Degrees and minutes
    }
    if (   !defined( $Ob->{LAT} )
        && !defined( $Ob->{LON} )
        && defined( $Fields[4] )
        && $Fields[4] =~ /\w/ )
    {
        ( $Ob->{LAT}, $Ob->{LON} ) = get_position_from_place( $Fields[4] );
    }
    if ( defined( $Ob->{LON} ) ) {
        $Last_lon = $Ob->{LON};
    }
    if ( defined( $Ob->{LAT} ) ) {
        $Last_lat = $Ob->{LAT};
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

    $Ob->{IM}   = 0;        # Check with Scott
    $Ob->{ATTC} = 1;        # Supplemental
    $Ob->{TI}   = 0;        # Nearest hour time precision
    $Ob->{DS}   = undef;    # Unknown course
    $Ob->{VS}   = undef;    # Unknown speed
    $Ob->{NID}  = 3;        # Check with Scott
    $Ob->{II}   = 10;       # Check with Scott

    # Air temperature in Farenheit
    if ( defined( $Fields[7] ) && $Fields[7] =~ /\d/ ) {
        $Ob->{AT} = fxtftc( $Fields[7] );
    }

    # Wet-bulb temperature in Farenheit
    if ( defined( $Fields[8] ) && $Fields[8] =~ /\d/ ) {
        $Ob->{WBT} = fxtftc( $Fields[8] );
    }
    if ( defined( $Ob->{WBT} ) ) { $Ob->{WBTI} = 0; }    # Measured
    if ( defined( $Ob->{WBT} ) || defined( $Ob->{AT} ) ) {
        $Ob->{IT} = 6;
    }                                                    # Whole degrees F

    # Pressure in English inches - already corrected for temperature
    if ( defined( $Fields[6] ) && $Fields[6] =~ /\d/ ) {
        $Ob->{SLP} = fxeimb( $Fields[6] );
    }
    # Gravity correction
    if ( defined( $Ob->{SLP} ) && defined($Last_lat) ) {
        $Ob->{SLP} += fwbpgv( $Ob->{SLP}, $Last_lat, 2 );
    }

    # Wind direction on 32-point compass
    if ( defined( $Fields[13] ) && $Fields[13] =~ /([NSEWX]+)/ ) {
        $Ob->{D} = ix32dd( sprintf "%-4s", $1 );
    }
    if ( defined( $Ob->{D} ) ) { $Ob->{DI} = 1; }        # 32 Pt compass

    # Wind speed on the Beaufort scale
    if ( defined( $Fields[14] ) && $Fields[14] =~ /\d/ ) {
        if ( $Fields[14] =~ /(\d+)\-(\d+)/ ) {
            $Ob->{W} = ( fxbfms($1) + fxbfms($2) ) / 2;
        }
        elsif ( $Fields[14] =~ /(\d+)/ ) {
            $Ob->{W} = fxbfms($1);
        }
    }
    if ( defined( $Ob->{W} ) ) { $Ob->{WI} = 5; }        # Beaufort force

    # Add the original record as a supplemental attachment
    push @{ $Ob->{attachments} }, 99;
    $Ob->{ATTE} = undef;
    chomp($Line);
    $Ob->{SUPD} = $Line;

    # Output the noon ob
    $Ob->write( \*STDOUT );

}

# Return (Lat,Long) given a place name
sub get_position_from_place {
    my $Name = lc(shift);
    if ( $Name =~ /cape dundas/ ) {
        return ( -60.75, -44.5 );
    }
    if ( $Name =~ /cape bennett/ ) {
        return ( -60.6, -45.2 );
    }
    if ( $Name =~ /scotia bay/ ) {
        return ( -60.75, -44.7 );
    }
    if ( $Name =~ /laurie is/ ) {
        return ( -60.8, -44.7 );
    }
    if ( $Name =~ /south orkney/ ) {
        return ( undef, undef );
    }
    warn "Unknown location $Name";
    return ( undef, undef );
}


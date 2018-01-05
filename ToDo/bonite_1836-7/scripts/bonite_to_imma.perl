#!/usr/bin/perl

# Process digitised logbook data from the Bonite into
#  IMMA records.

use strict;
use warnings;
use IMMA;
use Date::Calc qw(Delta_Days);
use MarineOb::lmrlib qw(fxmmmb fwbptc fwbpgv);

my $Ship_name = 'Bonite';
my ( $Year,     $Month,    $Day );
my ( $Last_lon, $Last_lat, $Last_T );
my $Lat_flag = 'N';
my $Lon_flag = 'W';
$Last_lat = 50.4;
$Last_lat = 88.1;

for ( my $i = 0 ; $i < 2 ; $i++ ) { <>; }    # Skip headers

while (<>) {
    my $Line = $_;
    my $Ob   = new IMMA;
    $Ob->clear();
    push @{ $Ob->{attachments} }, 0;
    my @Fields = split /\t/, $_;

    if ( defined( $Fields[0] ) && $Fields[0] =~ /\d/ ) {
        $Year = $Fields[0];
    }
    if ( defined( $Fields[1] ) && $Fields[1] =~ /\d/ ) {
        $Month = $Fields[1];
    }
    if ( defined( $Fields[2] ) && $Fields[2] =~ /\d/ ) {
        $Day = $Fields[2];
    }
    $Ob->{YR} = $Year;
    $Ob->{MO} = $Month;
    $Ob->{DY} = $Day;
    $Ob->{HR} = int( $Fields[3] / 100 ) + ( $Fields[3] % 100 ) / 60;
    if ( $Ob->{HR} == 24 ) { $Ob->{HR} = 23.99; }

    if ( defined( $Fields[4] ) && $Fields[4] =~ /(\d+)\.(\d+)\.(\d+)/ ) {
        $Ob->{LAT} = $1 + $2 / 60 + $3 / 3600;
    }
    if ( defined( $Fields[5] ) && $Fields[5] =~ /[nN]/ ) { $Lat_flag = 'N'; }
    if ( defined( $Fields[5] ) && $Fields[5] =~ /[sS]/ ) { $Lat_flag = 'S'; }
    if ( defined( $Ob->{LAT} ) && $Lat_flag eq 'S' ) { $Ob->{LAT} *= -1; }

    if ( defined( $Fields[6] ) && $Fields[6] =~ /(\d+)\.(\d+)\.(\d+)/ ) {
        $Ob->{LON} = $1 + $2 / 60 + $3 / 3600;
    }
    if ( defined( $Fields[7] ) && $Fields[7] =~ /[eE]/ ) { $Lon_flag = 'E'; }
    if ( defined( $Fields[7] ) && $Fields[7] =~ /[wW]/ ) { $Lon_flag = 'W'; }
    if ( defined( $Ob->{LON} ) && $Lon_flag eq 'W' ) { $Ob->{LON} *= -1; }
    if ( defined( $Ob->{LON} ) ) {
        $Ob->{LON} += 2.35;    # French
        if ( $Ob->{LON} > 180 ) { $Ob->{LON} -= 360; }
    }

    if ( !defined( $Ob->{LAT} ) && defined( $Fields[4] ) && $Fields[4] =~ /\w/ )
    {
        ( $Ob->{LAT}, $Ob->{LON} ) = position_from_port( $Fields[4] );
    }
    if ( defined( $Ob->{LAT} ) ) { $Last_lat = $Ob->{LAT}; }
    if ( defined( $Ob->{LON} ) ) { $Last_lon = $Ob->{LON}; }
    correct_hour_for_lon($Ob);

    if ( defined( $Fields[12] ) && $Fields[12] =~ /\d/ ) {
        $Ob->{AT} = $Fields[12];    # assumed C
    }
    if ( defined( $Fields[13] ) && $Fields[13] =~ /\d/ ) {
        $Ob->{SST} = $Fields[13];    # assumed C
    }

    if ( defined( $Fields[8] ) && $Fields[8] =~ /\d/ ) {
        $Ob->{SLP} = fxmmmb( $Fields[8] );
    }
    if (   defined( $Ob->{SLP} )
        && defined( $Fields[9] )
        && $Fields[9] =~ /\d/ )
    {                                # temperature correction
        $Ob->{SLP} += fwbptc( $Ob->{SLP}, $Fields[9] );
    }
    if ( defined( $Ob->{SLP} ) && defined($Last_lat) ) {    # gravity correction
        $Ob->{SLP} += fwbpgv( $Ob->{SLP}, $Last_lat, 2 );
    }

    # If no barometer - use the sympiesometer
    if (  !defined( $Ob->{SLP} )
        && defined( $Fields[10] )
        && $Fields[10] =~ /\d/ )
    {
        $Ob->{SLP} = fxmmmb( $Fields[10] );
    }

    # Fill in extra metadata
    $Ob->{IM}   = 0;         # C
    $Ob->{ATTC} = 0;         # No attachments - may have supplemental, see below
    $Ob->{TI}   = 0;         # Nearest hour time precision
    $Ob->{DS}   = undef;     # Unknown course
    $Ob->{VS}   = undef;     # Unknown speed
    $Ob->{NID}  = 3;         #
    $Ob->{II}   = 10;        #
    $Ob->{ID}   = $Ship_name;
    $Ob->{C1}   = '04';      #
    if (   defined( $Ob->{AT} )
        || defined( $Ob->{WBT} )
        || defined( $Ob->{DPT} )
        || defined( $Ob->{SST} ) )
    {
        $Ob->{IT} = 0;       # C and tenths
    }

    # Add the remarks as a supplemental attachment
    if ( defined($Line) && $Line =~ /\S/ ) {
        chomp($Line);
        push @{ $Ob->{attachments} }, 99;
        $Ob->{ATTC}++;
        $Ob->{ATTE} = undef;
        $Ob->{SUPD} = $Line;
    }

    $Ob->write( \*STDOUT );

}

# Get a position from a port name
sub position_from_port {
    my $Name = lc(shift);
    $Name =~ s/\s\s/ /g;
    if ( $Name =~ /callao/ ) {
        return ( -12.07, -77.23 );
    }
    if ( $Name =~ /valparaiso/ ) {
        return ( -33.0, -71.6 );
    }
    if ( $Name =~ /honolulu/ ) {
        return ( 21.3, -157.9 );
    }
    if ( $Name =~ /kearakekoua/ ) {
        return ( 19.5, -155.093 );
    }
    if ( $Name =~ /manil+a/ ) {
        return ( 14.58, 120.97 );
    }
    if ( $Name =~ /cobija/ ) {
        return ( -22.0, -73.0 );
    }
    if ( $Name =~ /payta/ ) {
        return ( -5.1, -81.1 );
    }
    if ( $Name =~ /guayaquil|puna/ ) {
        return ( -2.25, -79.9 );
    }
    if ( $Name =~ /macao/ ) {
        return ( 22.1, 113.5 );
    }
    if ( $Name =~ /marivelles/ ) {
        return ( 14.25, 120.5 );
    }
    if ( $Name =~ /cadix/ ) {
        return ( 36.5, -6.2 );
    }
    if ( $Name =~ /rio de janeiro/ ) {
        return ( -22.9, -43.3 );
    }
    if ( $Name =~ /rio de la plata/ ) {
        return ( -35.67, -55.7 );
    }
    if ( $Name =~ /montevideo/ ) {
        return ( -34.9, -56.2 );
    }
    if ( $Name =~ /touranne/ ) {    # Da Nang
        return ( 16.1, 108.2 );
    }
    if ( $Name =~ /singapore/ ) {
        return ( 1.3, 103.8 );
    }
    if ( $Name =~ /malacca/ ) {
        return ( 2.2, 102.5 );
    }
    if ( $Name =~ /penang/ ) {
        return ( 5.5, 100.2 );
    }
    if ( $Name =~ /hougly/ ) {      # Use Kolkatta
        return ( 22.5, 88.4 );
    }
    if ( $Name =~ /diamond harbour/ ) {
        return ( 22.1, 88.1 );
    }
    if ( $Name =~ /pondicherry/ ) {
        return ( 11.9, 79.8 );
    }
    if ( $Name =~ /saint denis/ ) {    # Reunion
        return ( -20.9, 55.5 );
    }
    if ( $Name =~ /st helena/ ) {
        return ( -16.0, -5.7 );
    }
    if ( $Name =~ /brest/ ) {
        return ( 48.5, -4.5 );
    }

    die "Unknown port $Name";

    #return ( undef, undef );
}

# Correct the date to UTC from local time
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
    $Ob->{HR} += $Last_lon * 12 / 180;
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

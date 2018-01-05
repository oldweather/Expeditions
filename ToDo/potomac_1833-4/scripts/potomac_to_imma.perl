#!/usr/bin/perl

# Process digitised logbook data from the Potomac into
#  IMMA records.

use strict;
use warnings;
use IMMA;
use Date::Calc qw(Delta_Days);
use MarineOb::lmrlib qw(fxtftc fxeimb fwbpgv);

my $Ship_name = 'Potomac';
my ( $Year,     $Month,    $Day );
my ( $Last_lon, $Last_lat, $Last_T );
my $Lat_flag = 'S';
my $Lon_flag = 'W';
$Last_lat = -29.32;
$Last_lon = -71.9;

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

    my ( $Lat, $Lon );
    if ( defined( $Fields[3] ) && $Fields[3] =~ /(\d+)\.(\d+)/ ) {
        $Lat = $1 + $2 / 60;
    }
    if ( defined( $Fields[4] ) && $Fields[4] =~ /[nN]/ ) { $Lat_flag = 'N'; }
    if ( defined( $Fields[4] ) && $Fields[4] =~ /[sS]/ ) { $Lat_flag = 'S'; }
    if ( defined($Lat) && $Lat_flag eq 'S' ) { $Lat *= -1; }

    if ( defined( $Fields[5] ) && $Fields[5] =~ /(\d+)\.(\d+)/ ) {
        $Lon = $1 + $2 / 60;
    }
    if ( defined( $Fields[6] ) && $Fields[6] =~ /[eE]/ ) { $Lon_flag = 'E'; }
    if ( defined( $Fields[6] ) && $Fields[6] =~ /[wW]/ ) { $Lon_flag = 'W'; }
    if ( defined($Lon) && $Lon_flag eq 'W' ) { $Lon *= -1; }
    if ( defined($Lon) ) {
    }

    if ( !defined($Lat) && defined( $Fields[3] ) && $Fields[3] =~ /\w/ ) {
        ( $Lat, $Lon ) = position_from_port( $Fields[3] );
    }

    # Fill in extra metadata
    $Ob->{IM}   = 0;         # Check with Scott
    $Ob->{ATTC} = 0;         # No attachments - may have supplemental, see below
    $Ob->{TI}   = 0;         # Nearest hour time precision
    $Ob->{DS}   = undef;     # Unknown course
    $Ob->{VS}   = undef;     # Unknown speed
    $Ob->{NID}  = 3;         # Check with Scott
    $Ob->{II}   = 10;        # Check with Scott
    $Ob->{ID}   = $Ship_name;
    $Ob->{C1}   = '01';      # US recruited
    $Ob->{IT}   = 4;         # F and tenths

    # 8 a.m. ob.
    $Ob->{HR} = 8;
    correct_hour_for_lon($Ob);

    if ( defined( $Fields[7] ) && $Fields[7] =~ /\d/ ) {
        $Ob->{AT} = fxtftc( $Fields[7] );
    }
    if ( defined( $Fields[10] ) && $Fields[10] =~ /\d/ ) {
        $Ob->{SLP} = fxeimb( $Fields[10] );
    }
    if ( defined( $Ob->{SLP} ) && defined($Last_lat) ) {    # gravity correction
        $Ob->{SLP} += fwbpgv( $Ob->{SLP}, $Last_lat, 2 );
    }

    $Ob->write( \*STDOUT );

    # Noon ob.
    $Ob->{AT}  = undef;
    $Ob->{SLP} = undef;
    $Ob->{HR}  = 12;
    correct_hour_for_lon($Ob);

    if ( defined($Lat) ) { $Ob->{LAT} = $Lat; }
    if ( defined($Lon) ) { $Ob->{LON} = $Lon; }

    if ( defined( $Fields[8] ) && $Fields[8] =~ /\d/ ) {
        $Ob->{AT} = fxtftc( $Fields[8] );
    }
    if ( defined( $Fields[13] ) && $Fields[13] =~ /\d/ ) {
        $Ob->{SST} = fxtftc( $Fields[13] );
    }
    if ( defined( $Fields[11] ) && $Fields[11] =~ /\d/ ) {
        $Ob->{SLP} = fxeimb( $Fields[11] );
    }
    if ( defined( $Ob->{SLP} ) && defined($Last_lat) ) {    # gravity correction
        $Ob->{SLP} += fwbpgv( $Ob->{SLP}, $Last_lat, 2 );
    }
    if ( defined($Line) && $Line =~ /\S/ ) {
        chomp($Line);
        push @{ $Ob->{attachments} }, 99;
        $Ob->{ATTC}++;
        $Ob->{ATTE} = undef;
        $Ob->{SUPD} = $Line;
    }

    $Ob->write( \*STDOUT );

    # 8 p.m. ob.
    $Ob->{AT}  = undef;
    $Ob->{SST} = undef;
    $Ob->{SLP} = undef;
    $Ob->{LAT} = undef;
    $Ob->{LON} = undef;
    $Ob->{ATTC}--;
    $Ob->{SUPD} = undef;
    pop @{ $Ob->{attachments} };
    $Ob->{HR} = 20;
    correct_hour_for_lon($Ob);

    if ( defined( $Fields[9] ) && $Fields[9] =~ /\d/ ) {
        $Ob->{AT} = fxtftc( $Fields[9] );
    }
    if ( defined( $Fields[12] ) && $Fields[12] =~ /\d/ ) {
        $Ob->{SLP} = fxeimb( $Fields[12] );
    }
    if ( defined( $Ob->{SLP} ) && defined($Last_lat) ) {    # gravity correction
        $Ob->{SLP} += fwbpgv( $Ob->{SLP}, $Last_lat, 2 );
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
    if ( $Name =~ /guayaquil|puna/ ) {
        return ( -2.25, -79.9 );
    }
    if ( $Name =~ /galapagos/ ) {
        return ( -1.15, -90.5 );
    }
    if ( $Name =~ /payta/ ) {
        return ( -5.1, -81.1 );
    }
    if ( $Name =~ /rio de janeiro/ ) {
        return ( -22.9, -43.13 );
    }
    if ( $Name =~ /boston/ ) {
        return ( 42.4, -71.0 );
    }
    if ( $Name =~ /lambayeq/ ) {
        return ( -6.7, -79.9 );
    }

    die "Unknown port $Name";

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

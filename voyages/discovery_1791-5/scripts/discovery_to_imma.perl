#!/usr/bin/perl

# Process Surgeon Menzis' observations from Vancouver's expedition into
#  IMMA records.

use strict;
use warnings;
use IMMA;
use Getopt::Long;
use FindBin;
use Date::Calc qw(Delta_Days);
use MarineOb::lmrlib qw(rxltut ixdtnd rxnddt fxtftc fxeimb fwbptc fwbpgv);

my $Last_lon = -5;
my $Lon_flag = 'N';
my $Lat_flag = 'W';
my $Last_lat = 50;
my ( $Year, $Month );

for ( my $i = 0 ; $i < 3 ; $i++ ) { <>; }    # Skip headers

while ( my $Line = <> ) {
    my @Fields = apply_qc( split /\t/, $Line );
    my $Ob = new IMMA;
    $Ob->clear();
    push @{ $Ob->{attachments} }, 0;

    # On the Discovery
    $Ob->{ID} = "Discovery";

    # Date
    if ( defined( $Fields[0] ) && $Fields[0] =~ /\d/ ) {
        $Year = $Fields[0];
    }
    $Ob->{YR} = $Year;
    if ( defined( $Fields[1] ) && $Fields[1] =~ /\d/ ) {
        $Month = $Fields[1];
    }
    $Ob->{MO} = $Month;
    if ( defined( $Fields[2] ) && $Fields[2] =~ /\d/ ) {
        $Ob->{DY} = $Fields[2];
    }
    if ( defined( $Fields[3] ) && $Fields[3] =~ /\d/ ) {
        $Ob->{HR} = $Fields[3] / 100;
    }

    if ( defined( $Fields[4] ) && $Fields[4] =~ /(\d+)\s(\d+)/ ) {
        $Ob->{LAT} = $1 + $2 / 60;
    }
    if ( defined( $Fields[4] ) && $Fields[4] =~ /([NS])/ ) {
        $Lat_flag = $1;
    }
    if ( defined( $Ob->{LAT} ) && $Lat_flag eq 'S' ) { $Ob->{LAT} *= -1; }
    if ( defined( $Fields[5] ) && $Fields[5] =~ /(\d+)\s(\d+)/ ) {
        $Ob->{LON} = $1 + $2 / 60;
    }
    if ( defined( $Fields[5] ) && $Fields[5] =~ /([EW])/ ) {
        $Lon_flag = $1;
    }
    if ( defined( $Ob->{LON} ) && $Lon_flag eq 'W' ) { $Ob->{LON} *= -1; }
    if ( defined( $Ob->{LON} ) ) {
        $Last_lon = $Ob->{LON};
    }
    if ( defined( $Ob->{LON} ) && $Ob->{LON} > 180 ) {
        $Ob->{LON} -= 360;
    }
    if ( defined( $Ob->{LAT} ) ) {
        $Last_lat = $Ob->{LAT};
    }

    # Convert dates to UTC
    if (   defined($Last_lon)
        && defined( $Ob->{YR} )
        && defined( $Ob->{MO} )
        && defined( $Ob->{DY} )
        && defined( $Ob->{HR} ) )
    {
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

    $Ob->{IM}   = 0;
    $Ob->{ATTC} = 1;        # Supplemental
    $Ob->{TI}   = 0;        # Nearest hour time precision
    $Ob->{DS}   = undef;    # Unknown course
    $Ob->{VS}   = undef;    # Unknown speed
    $Ob->{NID}  = 3;
    $Ob->{II}   = 10;

    # (Outside) Air temperature in Farenheit
    if ( defined( $Fields[8] ) && $Fields[8] =~ /\d/ ) {
        $Ob->{AT} = fxtftc( $Fields[8] );
    }

    # Pressure in English inches
    if ( defined( $Fields[9] ) && $Fields[9] =~ /\d/ ) {
        $Ob->{SLP} = fxeimb( $Fields[9] );
    }

    # Temperature correction
    if (   defined( $Ob->{SLP} )
        && defined( $Fields[7] )
        && $Fields[7] =~ /\d/ )    # Inside temperature
    {
        $Ob->{SLP} += fwbptc( $Ob->{SLP}, fxtftc( $Fields[7] ) );
    }
    else { $Ob->{SLP} = undef; }

    # Gravity correction
    if ( defined( $Ob->{SLP} ) && defined($Last_lat) ) {
        $Ob->{SLP} += fwbpgv( $Ob->{SLP}, $Last_lat, 2 );
    }

    # Add the original record as a supplemental attachment
    push @{ $Ob->{attachments} }, 99;
    $Ob->{ATTE} = undef;
    chomp($Line);
    $Ob->{SUPD} = $Line;

    # Discard the ob if no location or met data
    unless ( defined( $Ob->{SLP} )
        || defined( $Ob->{AT} )
        || defined( $Ob->{LAT} )
        || defined( $Ob->{LON} ) )
    {
        next;
    }

    # Output the ob
    $Ob->write( \*STDOUT );

}

# Correct some clearly erronious values
sub apply_qc {
    my @Fields = (@_);

    if ( defined( $Fields[5] ) && $Fields[5] eq '297 55' ) {
        $Fields[5] = '197 55';
    }
    if ( defined( $Fields[5] ) && $Fields[5] eq '297 06' ) {
        $Fields[5] = '197 06';
    }
    return @Fields;
}

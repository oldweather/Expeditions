#!/usr/bin/perl

# Process digitised logbook data from the Fury into
#  IMMA records.

use strict;
use warnings;
use IMMA;
use FindBin;
use Date::Calc qw(Add_Delta_Days Delta_Days);

use MarineOb::lmrlib
  qw(rxltut ixdtnd rxnddt fxtftc fxtrtc fxmmmb fxeimb fwbptc fwbpgv fxbfms ix32dd);
use MarineOb::declination qw(magnetic_to_true);
use MarineOb::WindTerms qw(WordsToBeaufort);

# Load the obs and convert to IMMA
my $Ship_name = 'Fury';
my $Last_lat  = 53;
my $Last_lon  = 0;

while ( my $Line = <> ) {
    unless ( $Line =~ /^55/ ) { next; }
    my $Ob = new IMMA;
    $Ob->clear();    # Why is this necessary?
    push @{ $Ob->{attachments} }, 0;
    my @Fields = split /\t/, $Line;

    $Ob->{YR} = $Fields[4];
    $Ob->{MO} = $Fields[5];
    $Ob->{DY} = $Fields[6];
    if ( defined( $Fields[7] ) && $Fields[7] =~ /^(\d\d):/ ) {
        $Ob->{HR} = $1;
    }
    if ( $Ob->{HR} == 0 ) {    # 24, not 0
        ( $Ob->{YR}, $Ob->{MO}, $Ob->{DY} ) =
          Add_Delta_Days( $Ob->{YR}, $Ob->{MO}, $Ob->{DY}, 1 );
    }

    # Latitudes - observations for preference
    if ( defined( $Fields[10] ) && $Fields[10] =~ /\d/ && $Fields[10] != -99 ) {
        $Ob->{LAT} = $Fields[10] + $Fields[11] / 60;
        if ( defined( $Fields[13] ) && lc( $Fields[13] ) eq 's' ) {
            $Ob->{LAT} *= -1;
        }
    }
    elsif (defined( $Fields[14] )
        && $Fields[14] =~ /\d/
        && $Fields[14] != -99 )
    {
        $Ob->{LAT} = $Fields[14] + $Fields[15] / 60;
        if ( defined( $Fields[17] ) && lc( $Fields[17] ) eq 's' ) {
            $Ob->{LAT} *= -1;
        }
    }

    # Longitudes - chronometer for preference
    if ( defined( $Fields[18] ) && $Fields[18] =~ /\d/ && $Fields[18] != -99 ) {
        $Ob->{LON} = $Fields[18] + $Fields[19] / 60;
        if ( defined( $Fields[21] ) && lc( $Fields[21] ) eq 'w' ) {
            $Ob->{LON} *= -1;
        }
    }
    elsif (defined( $Fields[22] )
        && $Fields[22] =~ /\d/
        && $Fields[22] != -99 )
    {
        $Ob->{LON} = $Fields[22] + $Fields[23] / 60;
        if ( defined( $Fields[25] ) && lc( $Fields[25] ) =~ /w/ ) {
            $Ob->{LON} *= -1;
        }
    }

    if ( defined( $Ob->{LAT} ) || defined( $Ob->{LON} ) ) {
        $Ob->{LI} = 4;    # Deg+Min position precision
    }

    if ( defined( $Ob->{LAT} ) ) { $Last_lat = $Ob->{LAT}; }
    if ( defined( $Ob->{LON} ) ) { $Last_lon = $Ob->{LON}; }

    if (   defined($Last_lon)
        && defined( $Ob->{HR} )
        && defined( $Ob->{DY} )
        && defined( $Ob->{MO} )
        && defined( $Ob->{YR} ) )
    {
        my $elon = $Last_lon;
        if ( $elon < 0 ) { $elon += 360; }
        my ( $uhr, $udy ) = rxltut(
            $Ob->{HR} * 100,
            ixdtnd( $Ob->{DY}, $Ob->{MO}, $Ob->{YR} ),
            $elon * 100
        );
        $Ob->{HR} = $uhr / 100;
        ( $Ob->{DY}, $Ob->{MO}, $Ob->{YR} ) = rxnddt($udy);
    }
    else { $Ob->{HR} = undef; }

    # Pressure converted from inches
    if (   defined( $Fields[9] )
        && $Fields[9] =~ /\d/
        && $Fields[9] !~ /\-99/ )
    {
        $Ob->{SLP} = fxeimb( $Fields[9] );
    }

    # No attached thermometer, so no temperature correction
    # Gravity correction
    if ( defined( $Ob->{SLP} ) && defined($Last_lat) ) {
        $Ob->{SLP} += fwbpgv( $Ob->{SLP}, $Last_lat, 2 );
    }

    # Temperatures converted from Farenheit
    if (   defined( $Fields[8] )
        && $Fields[8] =~ /\d/
        && $Fields[8] !~ /\-99/ )
    {
        $Ob->{AT} = fxtftc( $Fields[8] );
    }

    # Fill in extra metadata
    $Ob->{IM}   = 0;
    $Ob->{ATTC} = 1;            # supd
    $Ob->{TI}   = 0;            # Nearest hour time precision
    $Ob->{DS}   = undef;        # Unknown course
    $Ob->{VS}   = undef;        # Unknown speed
    $Ob->{NID}  = undef;        #
    $Ob->{II}   = 10;           #
    $Ob->{ID}   = $Ship_name;
    $Ob->{C1}   = '03';         # UK recruited
    if (   defined( $Ob->{AT} )
        || defined( $Ob->{WBT} )
        || defined( $Ob->{DPT} )
        || defined( $Ob->{SST} ) )
    {
        $Ob->{IT} = 4;          # Temps in degF and 10ths
    }

    # Add the original record as a supplemental attachment
    push @{ $Ob->{attachments} }, 99;
    $Ob->{ATTE} = undef;
    chomp($Line);
    $Ob->{SUPD} = $Line;

    $Ob->write( \*STDOUT );

}


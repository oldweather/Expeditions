#!/usr/bin/perl

# Process digitised logbook data from the Isabella into
#  IMMA records.

use strict;
use warnings;
use IMMA;
use Getopt::Long;
use FindBin;
use Date::Calc qw(Add_Delta_Days);

use MarineOb::lmrlib
  qw(rxltut ixdtnd rxnddt fxtftc fxtrtc fxmmmb fxeimb fwbptc fwbpgv fxbfms ix32dd);
use MarineOb::declination qw(magnetic_to_true);
use MarineOb::WindTerms qw(WordsToBeaufort);

my $Ship_name  = 'Isabella';
my $Last_lon   = -28;
my $Last_lon_f = 'w';
my $Last_lat   = 60;
my $Last_lat_f = 'n';
my $Last_wind_d;

while ( my $Line = <> ) {
    unless ( $Line =~ /^\s+55/ ) { next; }
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
    if ( defined( $Fields[19] ) && $Fields[19] =~ /\d/ ) {
        $Ob->{LAT} = $Fields[19];
        if ( defined( $Fields[20] ) && $Fields[20] =~ /\d/ ) {
            $Ob->{LAT} += $Fields[20] / 60;
        }
        if ( defined( $Fields[21] ) ) {
            $Last_lat_f = lc( $Fields[21] );
        }

    }
    elsif ( defined( $Fields[22] ) && $Fields[22] =~ /\d/ ) {
        $Ob->{LAT} = $Fields[22];
        if ( defined( $Fields[23] ) && $Fields[23] =~ /\d/ ) {
            $Ob->{LAT} += $Fields[23] / 60;
        }
        if ( defined( $Fields[24] ) ) {
            $Last_lat_f = lc( $Fields[24] );
        }

    }
    if ( defined( $Ob->{LAT} ) && $Last_lat_f =~ /s/ ) {
        $Ob->{LAT} *= -1;
    }

    # Longitudes - chronometer for preference
    if ( defined( $Fields[25] ) && $Fields[25] =~ /\d/ ) {
        $Ob->{LON} = $Fields[25];
        if ( defined( $Fields[26] ) && $Fields[26] =~ /\d/ ) {
            $Ob->{LON} += $Fields[26] / 60;
        }
        if ( defined( $Fields[27] ) ) {
            $Last_lon_f = lc( $Fields[27] );
        }
    }
    elsif ( defined( $Fields[28] ) && $Fields[28] =~ /\d/ ) {
        $Ob->{LON} = $Fields[28];
        if ( defined( $Fields[29] ) && $Fields[29] =~ /\d/ ) {
            $Ob->{LON} += $Fields[29] / 60;
        }
        if ( defined( $Fields[30] ) ) {
            $Last_lon_f = lc( $Fields[30] );
        }
    }
    if ( defined( $Ob->{LON} ) && $Last_lon_f =~  /w/ ) {
        $Ob->{LON} *= -1;
    }
    if ( defined( $Ob->{LAT} ) || defined( $Ob->{LON} ) ) {
        $Ob->{LI} = 4;    # Deg+Min position precision
    }

    # Convert ob date and time to UTC
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
    if ( defined( $Fields[13] ) && $Fields[13] =~ /\d/ && $Fields[13] != -999 )
    {
        $Ob->{SLP} = fxeimb( $Fields[13] );
    }

    # Temperature correction
    if (   defined( $Ob->{SLP} )
        && defined( $Fields[12] )
        && $Fields[12] =~ /\d/
        && $Fields[12] != -999 )
    {
        $Ob->{SLP} += fwbptc( $Ob->{SLP}, fxtftc( $Fields[12] ) );
    }
    else { $Ob->{SLP} = undef; }

    # Gravity correction
    if ( defined( $Ob->{SLP} ) && defined($Last_lat) ) {
        $Ob->{SLP} += fwbpgv( $Ob->{SLP}, $Last_lat, 2 );
    }

    # Temperatures converted from Farenheit
    if ( defined( $Fields[10] ) && $Fields[10] =~ /\d/ && $Fields[10] != -999 )
    {
        $Ob->{AT} = fxtftc( $Fields[10] );
    }
    if ( defined( $Fields[11] ) && $Fields[11] =~ /\d/ && $Fields[11] != -999 )
    {
        $Ob->{SST} = fxtftc( $Fields[11] );
    }

    # Wind force
    if ( defined( $Fields[16] ) && $Fields[16] =~ /(\w+)/ ) {
        my $WindE = $Fields[16];
        $WindE =~ s/westerly\s+//;                        # delete unwanted term
        $WindE =~ s/Light and variable airs/light airs/;
        $WindE =~ s/Light variable airs/light airs/;
        $WindE =~ s/Light variable winds/light winds/;
        my $Force;
        if ( $WindE =~ /(\w+)\s+(\w+)/ ) {
            $Force = WordsToBeaufort( $1, $2 );
        }
        else {
            $Force = WordsToBeaufort($WindE);
        }
        if ( defined($Force) ) {
            if ( $Force == -1 ) {
                warn "Unknown wind force term $Fields[16]";
            }
            else {
                $Ob->{W}  = fxbfms($Force);    # Beaufort -> m/s
                $Ob->{WI} = 5;                 # Beaufort force
            }
        }
    }

    # Wind direction
    if ( defined( $Fields[8] ) && $Fields[8] =~ /\S/ ) {
        my $Dirn = $Fields[8];
        $Dirn =~ s/b/x/;
        $Dirn = sprintf "%-4s", uc($Dirn);
        if ( $Dirn eq 'CALM' || $Dirn eq 'CALMS' ) {
            $Ob->{D} = 361;
        }
        elsif ( $Dirn eq 'VARIAXLE' ) {
            $Ob->{D} = 362;
        }
        else {
            ( $Ob->{D}, undef ) = ix32dd($Dirn);
            if ( defined( $Ob->{D} ) ) {
                $Ob->{DI} = 1;    # 32-point compass
            }
            else {
                warn "Unknown wind direction $Dirn - $Fields[8]";
            }
        }
    }

    # Only bother with the record if it contains a position or some met obs.
    unless ( defined( $Ob->{LAT} )
        || defined( $Ob->{LON} )
        || defined( $Ob->{AT} )
        || defined( $Ob->{SST} )
        || defined( $Ob->{SLP} )
        || defined( $Ob->{D} )
        || defined( $Ob->{W} )
        || defined( $Ob->{DPT} ) )
    {
        next;
    }

    # Fill in extra metadata
    $Ob->{IM}   = 0;
    $Ob->{ATTC} = 1;            # supplemental
    $Ob->{TI}   = 0;            # Nearest hour time precision
    $Ob->{DS}   = undef;        # Unknown course
    $Ob->{VS}   = undef;        # Unknown speed
    $Ob->{NID}  = undef;
    $Ob->{II}   = 10;
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


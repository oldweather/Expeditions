#!/usr/bin/perl

# Process digitised logbook data from the Paramour into
#  IMMA records.

use strict;
use warnings;
use IMMA;
use FindBin;
use Date::Calc qw(Add_Delta_Days Delta_Days Delta_DHMS Add_Delta_DHMS);
use IO::File;

use MarineOb::lmrlib
  qw(rxltut ixdtnd rxnddt fxtftc fxtrtc fxmmmb fxeimb fwbptc fwbpgv fxbfms ix32dd);
use MarineOb::declination qw(magnetic_to_true);
use MarineOb::WindTerms qw(WordsToBeaufort);

# Load the obs and convert to IMMA
my $Ship_name = 'Paramore';
my $Last_lat  = 49;
my $Last_lon  = -5;

while ( my $Line = <> ) {
    unless ( $Line =~ /^Paramore/ ) { next; }
    my $Ob = new IMMA;
    $Ob->clear();    # Why is this necessary?
    push @{ $Ob->{attachments} }, 0;
    my @Fields = split /\t/, $Line;
    foreach my $Fi (@Fields) {
        if ( $Fi =~ /\.\d*½/ ) { $Fi =~ s/½/5/; }
        $Fi =~ s/½/\.5/;
        if ( $Fi =~ /\.\d*¼/ ) { $Fi =~ s/¼/25/; }
        $Fi =~ s/¼/\.25/;
    }

    if (   defined( $Fields[1] )
        && $Fields[1] =~ /\d/
        && defined( $Fields[2] )
        && $Fields[2] =~ /\d/
        && defined( $Fields[3] )
        && $Fields[3] =~ /\d/ )
    {
        $Ob->{YR} = $Fields[1];
        $Ob->{MO} = $Fields[2];
        $Ob->{DY} = $Fields[3];

        # Convert from Julian to Gregorian calendar
        if ( $Ob->{YR} == 1700 && $Ob->{MO} == 2 && $Ob->{DY} == 29 ) {
            ( $Ob->{YR}, $Ob->{MO}, $Ob->{DY} ) =
              Add_Delta_Days( $Ob->{YR}, $Ob->{MO}, 28, +11 );
        }
        elsif (
            Delta_Days( $Ob->{YR}, $Ob->{MO}, $Ob->{DY}, 1700, 2, 28 ) <= 0 )
        {
            ( $Ob->{YR}, $Ob->{MO}, $Ob->{DY} ) =
              Add_Delta_Days( $Ob->{YR}, $Ob->{MO}, $Ob->{DY}, +11 );
        }
        else {
            ( $Ob->{YR}, $Ob->{MO}, $Ob->{DY} ) =
              Add_Delta_Days( $Ob->{YR}, $Ob->{MO}, $Ob->{DY}, +10 );
        }
    }

    # Position
    if ( defined( $Fields[4] ) && $Fields[4] =~ /\d/ ) {
        $Ob->{LAT} = $Fields[4];
        if ( defined( $Fields[5] ) && $Fields[5] =~ /\d/ ) {
            $Ob->{LAT} += $Fields[5] / 60;
        }
        if ( defined( $Fields[6] ) && $Fields[6] =~ /[sS]/ ) {
            $Ob->{LAT} *= -1;
        }
        $Last_lat = $Ob->{LAT};
    }
    if ( defined( $Fields[7] ) && $Fields[7] =~ /(\d+)/ ) {
        $Ob->{LON} = $1;
        if ( defined( $Fields[8] ) && $Fields[8] =~ /(\d+)/ ) {
            $Ob->{LON} += $1 / 60;
        }
        if ( defined( $Fields[9] ) && $Fields[9] =~ /[wW]/ ) {
            $Ob->{LON} *= -1;
        }
        $Last_lon = $Ob->{LON};
    }

    # Assume noon
    $Ob->{HR} = 12;

    # Convert to UTC - lmrlib methods don't work pre 1770
    if (   defined($Last_lon)
        && defined( $Ob->{YR} )
        && defined( $Ob->{MO} )
        && defined( $Ob->{DY} ) )
    {
        my $dhr  = int( $Last_lon / 15 );
        my $Null = undef;
        ( $Ob->{YR}, $Ob->{MO}, $Ob->{DY}, $Ob->{HR}, $Null, $Null ) =
          Add_Delta_DHMS( $Ob->{YR}, $Ob->{MO}, $Ob->{DY}, $Ob->{HR}, 0, 0, 0,
            $dhr, 0, 0 );
    }
    else { $Ob->{HR} = undef; }

    # Pressure converted from inches
    if ( defined( $Fields[17] ) && $Fields[17] =~ /\d/ ) {
        $Ob->{SLP} = fxeimb( $Fields[17] );
    }

    # No attached thermometer, so no temperature correction
    # Gravity correction
    if ( defined( $Ob->{SLP} ) && defined($Last_lat) ) {
        $Ob->{SLP} += fwbpgv( $Ob->{SLP}, $Last_lat, 2 );
    }

    # Middleton suggests Halley's thermometer units were 0.238C
    if ( defined( $Fields[16] ) && $Fields[16] =~ /\d/ ) {
        $Ob->{AT} = $Fields[16] * 0.238;

        # Also suggests 0H=0C, but this is clearly wrong here - assume 0H=-4C
        $Ob->{AT} += 4;
    }

    # Wind force
    if ( defined( $Fields[15] ) && $Fields[15] =~ /(\w+)/ ) {
        my $WindE = $Fields[15];
        my $Force;
        if ( $WindE =~ /(\w+)\s+(\w+)/ ) {
            $Force = WordsToBeaufort( $1, $2 );
        }
        else {
            $Force = WordsToBeaufort($WindE);
        }
        if ( defined($Force) ) {
            if ( $Force == -1 ) {
                warn "Unknown wind force term $Fields[15]";
            }
            else {
                $Ob->{W}  = fxbfms($Force);    # Beaufort -> m/s
                $Ob->{WI} = 5;                 # Beaufort force
            }
        }
    }

    # Wind direction
    if ( defined( $Fields[14] ) && $Fields[14] =~ /\S/ ) {
        my @F2 = split /[\s\-]+/, $Fields[14];
        my $Dirn = $F2[$#F2];    # Last entry - closest to noon
        $Dirn =~ s/[bB][yY]*/x/;
        $Dirn = sprintf "%-4s", uc($Dirn);
        if ( $Dirn eq 'CALM' || $Dirn eq 'CALMS' ) {
            $Ob->{D} = 361;
        }
        else {
            ( $Ob->{D}, undef ) = ix32dd($Dirn);
            if ( defined( $Ob->{D} ) ) {
                $Ob->{DI} = 1;    # 32-point compass
            }
            else {
                warn "Unknown wind direction $Dirn - $Fields[14]";
            }
        }
    }

    # Fill in extra metadata
    $Ob->{IM}   = 0;
    $Ob->{ATTC} = 1;              # supd
    $Ob->{TI}   = 0;              # Nearest hour time precision
    $Ob->{DS}   = undef;          # Unknown course
    $Ob->{VS}   = undef;          # Unknown speed
    $Ob->{NID}  = undef;          #
    $Ob->{II}   = 10;             #
    $Ob->{ID}   = $Ship_name;
    $Ob->{C1}   = '03';           # UK recruited
    if (   defined( $Ob->{AT} )
        || defined( $Ob->{WBT} )
        || defined( $Ob->{DPT} )
        || defined( $Ob->{SST} ) )
    {
        $Ob->{IT} = undef;        # Unknown temp units
    }

    # Add the original record as a supplemental attachment
    push @{ $Ob->{attachments} }, 99;
    $Ob->{ATTE} = undef;
    chomp($Line);
    chop($Line);
    $Ob->{SUPD} = $Line;

    # Discard obs with no data
    unless ( defined( $Ob->{LAT} )
        || defined( $Ob->{LON} )
        || defined( $Ob->{AT} )
        || defined( $Ob->{SLP} )
        || defined( $Ob->{WS} ) )
    {
        next;
    }
    $Ob->write( \*STDOUT );

}

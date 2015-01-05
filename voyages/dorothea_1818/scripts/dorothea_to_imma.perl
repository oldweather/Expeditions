#!/usr/bin/perl

# Process digitised logbook data from the Dorothea into
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

my $Ship_name  = 'Dorothea ';
my $Last_lon   = 0;
my $Last_lon_f = 'e';
my $Last_lat   = 62;
my $Last_lat_f = 'n';
my $Last_wind_d;

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
    if ( defined( $Fields[19] ) && $Fields[19] =~ /\d/ ) {
        $Ob->{LAT} = $Fields[19];
        if ( defined( $Fields[20] ) && $Fields[20] =~ /\d/ ) {
            $Ob->{LAT} += $Fields[20] / 60;
        }
        if ( defined( $Fields[22] ) ) {
            $Last_lat_f = lc( $Fields[22] );
        }

    }
    elsif ( defined( $Fields[23] ) && $Fields[23] =~ /\d/ ) {
        $Ob->{LAT} = $Fields[23];
        if ( defined( $Fields[24] ) && $Fields[24] =~ /\d/ ) {
            $Ob->{LAT} += $Fields[24] / 60;
        }
        if ( defined( $Fields[26] ) ) {
            $Last_lat_f = lc( $Fields[26] );
        }

    }
    if ( defined( $Ob->{LAT} ) && $Last_lat_f =~ /s/ ) {
        $Ob->{LAT} *= -1;
    }

    # Longitudes - chronometer for preference
    if ( defined( $Fields[27] ) && $Fields[27] =~ /\d/ ) {
        $Ob->{LON} = $Fields[27];
        if ( defined( $Fields[28] ) && $Fields[28] =~ /\d/ ) {
            $Ob->{LON} += $Fields[28] / 60;
        }
        if ( defined( $Fields[30] ) && $Fields[30] =~ /[eEwW]/ ) {
            $Last_lon_f = lc( $Fields[30] );
        }
    }
    elsif ( defined( $Fields[31] ) && $Fields[31] =~ /\d/ ) {
        $Ob->{LON} = $Fields[31];
        if ( defined( $Fields[32] ) && $Fields[32] =~ /\d/ ) {
            $Ob->{LON} += $Fields[32] / 60;
        }
        if ( defined( $Fields[34] ) && $Fields[34] =~ /[eEwW]/ ) {
            $Last_lon_f = lc( $Fields[34] );
        }
    }
    if ( defined( $Ob->{LON} ) && $Last_lon_f =~ /w/ ) {
        $Ob->{LON} *= -1;
    }
    if ( defined( $Ob->{LAT} ) || defined( $Ob->{LON} ) ) {
        $Ob->{LI} = 4;    # Deg+Min position precision
    }
    if (   ( !defined( $Ob->{LON} ) || !defined( $Ob->{LAT} ) )
        && defined( $Fields[35] )
        && $Fields[35] =~ /\w/ )
    {
        my ( $Lat, $Lon ) = position_from_port( $Fields[35] );
        unless ( defined( $Ob->{LAT} ) ) { $Ob->{LAT} = $Lat; $Ob->{LI} = 4; }
        unless ( defined( $Ob->{LON} ) ) { $Ob->{LON} = $Lon; $Ob->{LI} = 4; }
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
    if ( defined( $Fields[12] ) && $Fields[12] =~ /\d/ && $Fields[12] != -999 )
    {
        $Ob->{SLP} = fxeimb( $Fields[12] );
    }

    # Temperature correction
    if (   defined( $Ob->{SLP} )
        && defined( $Fields[13] )
        && $Fields[13] =~ /\d/
        && $Fields[13] != -999 )
    {
        $Ob->{SLP} += fwbptc( $Ob->{SLP}, fxtftc( $Fields[13] ) );
    }

    # Gravity correction
    if ( defined( $Ob->{SLP} ) && defined($Last_lat) ) {
        $Ob->{SLP} += fwbpgv( $Ob->{SLP}, $Last_lat, 2 );
    }

    # Temperatures converted from Farenheit
    if ( defined( $Fields[14] ) && $Fields[14] =~ /\d/ && $Fields[14] != -999 )
    {
        $Ob->{AT} = fxtftc( $Fields[14] );
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
        $WindE =~ s/^[aA]\s+//;
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

# Get a position from a port name
sub position_from_port {
    my $Name = lc(shift);
    if ( $Name =~ /hakluyt head/ ) {
        return ( 79.78, 10.8 );
    }
    if ( $Name =~ /vogel sang/ ) {
        return ( 79.85, 11.33 );
    }
    if ( $Name =~ /grey hook/ ) {
        return ( 79.81, 14.55 );
    }
    if ( $Name =~ /cloven cliff/ ) {
        return ( 79.85, 11.48 );
    }
    if ( $Name =~ /smeerenburg/ ) {
        return ( 79.66, 11.00 );
    }
    if ( $Name =~ /se point of amsterdam island/ ) {
        return ( 79.66, 11.13 );
    }
    if ( $Name =~ /danes island/ ) {
        return ( 79.66, 10.5 );
    }
    if ( $Name =~ /magdelena hook|magdelena bay/ ) {
        return ( 79.57, 10.80 );
    }
    if ( $Name =~ /prince charles foreland/ ) {    # North point
        return ( 78.92, 10.57 );
    }
    if ( $Name =~ /faro island/ ) {                # North-Eest approach
        return ( 62.37, -6.25 );
    }
    if ( $Name =~ /flamborough head/ ) {           #
        return ( 54.12, -0.08 );
    }
    if ( $Name =~ /dumblelow/ ) {
        return ( undef, undef );
    }
    if ( $Name =~ /blakeney/ ) {                   #
        return ( 53.0, 1.01 );
    }
    if ( $Name =~ /land not in sight/ ) {
        return ( undef, undef );
    }
    if ( $Name =~ /land sbw/ ) {
        return ( undef, undef );
    }
    if ( $Name =~ /foul island shetland/ ) {
        return ( undef, undef );
    }
    die "Unknown location $Name";
}

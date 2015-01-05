#!/usr/bin/perl

# Process digitised logbook data from the Hecla into
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

# Load the positions
open( DIN, "$FindBin::Bin/../as_digitised/ADM_55_62_HMS_Hecla_lats_longs.txt" )
  or die "Can't open positions file";
my %Lats;
my %Longs;
while (<DIN>) {
    unless ( $_ =~ /^55/ ) { next; }
    my @Fields = split /\t/, $_;

    # Latitudes - observations for preference
    if ( defined( $Fields[6] ) && $Fields[6] =~ /\d/ && $Fields[6] != -99 ) {
        $Lats{ $Fields[3] }{ $Fields[4] }{ $Fields[5] } =
          $Fields[6] + $Fields[7] / 60;
        if ( defined( $Fields[8] ) && lc( $Fields[8] ) eq 's' ) {
            $Lats{ $Fields[3] }{ $Fields[4] }{ $Fields[5] } *= -1;
        }
    }
    elsif ( defined( $Fields[9] ) && $Fields[9] =~ /\d/ && $Fields[9] != -99 ) {
        $Lats{ $Fields[3] }{ $Fields[4] }{ $Fields[5] } =
          $Fields[9] + $Fields[10] / 60;
        if ( defined( $Fields[11] ) && lc( $Fields[11] ) eq 's' ) {
            $Lats{ $Fields[3] }{ $Fields[4] }{ $Fields[5] } *= -1;
        }
    }

    # Longitudes - chronometer for preference
    if ( defined( $Fields[12] ) && $Fields[12] =~ /\d/ && $Fields[12] != -99 ) {
        $Longs{ $Fields[3] }{ $Fields[4] }{ $Fields[5] } =
          $Fields[12] + $Fields[13] / 60;
        if ( defined( $Fields[14] ) && lc( $Fields[14] ) =~ 'w' ) {
            $Longs{ $Fields[3] }{ $Fields[4] }{ $Fields[5] } *= -1;
        }
    }
    elsif (defined( $Fields[15] )
        && $Fields[15] =~ /\d/
        && $Fields[15] != -99 )
    {
        $Longs{ $Fields[3] }{ $Fields[4] }{ $Fields[5] } =
          $Fields[15] + $Fields[16] / 60;
        if ( defined( $Fields[17] ) && lc( $Fields[17] ) =~ 'w' ) {
            $Longs{ $Fields[3] }{ $Fields[4] }{ $Fields[5] } *= -1;
        }
    }
    if ( $Fields[18] =~ /East of Winter Island/ ) {
        $Longs{ $Fields[3] }{ $Fields[4] }{ $Fields[5] } -= 83.07;
    }
}
close(DIN);

# Load the obs and convert to IMMA
my $Ship_name = 'Hecla';
my $Last_lat  = 53.5;
my $Last_lon  = 2;

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

    if ( defined( $Ob->{HR} ) && $Ob->{HR} == 12 ) {
        if ( defined( $Lats{ $Ob->{YR} }{ $Ob->{MO} }{ $Ob->{DY} } ) ) {
            $Ob->{LAT} = $Lats{ $Ob->{YR} }{ $Ob->{MO} }{ $Ob->{DY} };
        }
        if ( defined( $Longs{ $Ob->{YR} }{ $Ob->{MO} }{ $Ob->{DY} } ) ) {
            $Ob->{LON} = $Longs{ $Ob->{YR} }{ $Ob->{MO} }{ $Ob->{DY} };
        }
    }
    if ( defined( $Ob->{LAT} ) || defined( $Ob->{LON} ) ) {
        $Ob->{LI} = 4;    # Deg+Min position precision
    }

    if (   Delta_Days( $Ob->{YR}, $Ob->{MO}, $Ob->{DY}, 1821, 10, 4 ) <= 0
        && Delta_Days( $Ob->{YR}, $Ob->{MO}, $Ob->{DY}, 1822, 6, 30 ) >= 0 )
    {

        # In winter quarters off Winter Island
        $Ob->{LAT} = 66.27;
        $Ob->{LON} = -83.07;
        $Ob->{LI}  = 6;        # Position from metadata
    }
    if (   Delta_Days( $Ob->{YR}, $Ob->{MO}, $Ob->{DY}, 1822, 10, 1 ) <= 0
        && Delta_Days( $Ob->{YR}, $Ob->{MO}, $Ob->{DY}, 1823, 8, 12 ) >= 0 )
    {

        # In winter quarters off Igloolik
        $Ob->{LAT} = 69.38;
        $Ob->{LON} = -81.73;
        $Ob->{LI}  = 6;        # Position from metadata
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
    if (   defined( $Fields[10] )
        && $Fields[10] =~ /\d/
        && $Fields[10] !~ /\-99/ )
    {
        $Ob->{SLP} = fxeimb( $Fields[10] );
    }

    # No attached thermometer, so no temperature correction
    # Gravity correction
    if ( defined( $Ob->{SLP} ) && defined($Last_lat) ) {
        $Ob->{SLP} += fwbpgv( $Ob->{SLP}, $Last_lat, 2 );
    }

    # Temperatures converted from Farenheit
    if ( defined( $Fields[8] ) && $Fields[8] =~ /\d/ && $Fields[8] !~ /\-99/ ) {
        $Ob->{AT} = fxtftc( $Fields[8] );
    }
    if ( defined( $Fields[9] ) && $Fields[9] =~ /\d/ && $Fields[9] !~ /\-99/ ) {
        $Ob->{SST} = fxtftc( $Fields[9] );
    }

    # Wind force
    if ( defined( $Fields[12] ) && $Fields[12] =~ /(\w+)/ ) {
        my $WindE = $Fields[12];
        $WindE =~ s/^A\s+//;
        my $Force;
        if ( $WindE =~ /(\w+)\s+(\w+)/ ) {
            $Force = WordsToBeaufort( $1, $2 );
        }
        else {
            $Force = WordsToBeaufort($WindE);
        }
        if ( defined($Force) ) {
            if ( $Force == -1 ) {
                warn "Unknown wind force term $Fields[12]";
            }
            else {
                $Ob->{W}  = fxbfms($Force);    # Beaufort -> m/s
                $Ob->{WI} = 5;                 # Beaufort force
            }
        }
    }

    # Wind direction
    if ( defined( $Fields[11] ) && $Fields[11] =~ /\S/ ) {
        my $Dirn = $Fields[11];
        $Dirn =~ s/[bB]/x/;
        $Dirn =~ s/[^a-zA-Z]//g;
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
                warn "Unknown wind direction $Dirn - $Fields[11]";
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
        $Ob->{IT} = 4;            # Temps in degF and 10ths
    }

    # Add the original record as a supplemental attachment
    push @{ $Ob->{attachments} }, 99;
    $Ob->{ATTE} = undef;
    chomp($Line);
    $Ob->{SUPD} = $Line;

    $Ob->write( \*STDOUT );

}


#!/usr/bin/perl

# Process digitised logbook data from Scoresby into
#  IMMA records.

# Process in three passes - make the records and populate them; but leave
# time as local and give each ob the position of the ship at noon on that day.
# Interpolate the positions and correct the times to UTC in subsequent passes

use strict;
use warnings;
use IMMA;
use FindBin;
use Date::Calc qw(Add_Delta_Days Delta_Days Delta_DHMS check_date);
use IO::File;

use MarineOb::lmrlib
  qw(rxltut ixdtnd rxnddt fxtftc fxtrtc fxmmmb fxeimb fwbptc fwbpgv fxbfms ix32dd);
use MarineOb::declination qw(magnetic_to_true);
use MarineOb::WindTerms qw(WordsToBeaufort);

# Temporary file for holding the records between passes
#my $fh = IO::File->new_tmpfile or die "Unable to create tempfile: $!";
my $fh;
open( $fh, "+>tmp.imma" );

# Load the obs and convert to IMMA
my $Ship_name = 'Scoresby';
my $Last_lat  = 74;
my $Last_lon  = 14;
my $Lon_flag  = 'E';
my $Year;
my $Month;

while ( my $Line = <> ) {
    unless ( $Line =~ /^\s*\d/ ) { next; }
    my $Ob = new IMMA;
    $Ob->clear();    # Why is this necessary?
    push @{ $Ob->{attachments} }, 0;
    my @Fields = split /\t/, $Line;

    if ( defined( $Fields[0] ) && $Fields[0] =~ /\d/ ) { $Year = $Fields[0]; }
    if ( $Year < 1810 ) { next; }    # Earlier obs have no longitudes
    if ( defined( $Fields[1] ) && $Fields[1] =~ /\d/ ) { $Month = $Fields[1]; }

    $Ob->{MO} = $Month;
    $Ob->{YR} = $Year;
    $Ob->{DY} = $Fields[2];
    if ( $Fields[3] =~ /\d/ ) {
        if ( $Fields[3] =~ /(\d+)[\s\.]*(\d*)/ ) {
            $Ob->{LAT} = $1 + $2 / 60;
        }
        else {
            die "Bad latitude $Fields[3]";
        }
    }
    if ( $Fields[4] =~ /\d/ ) {
        if ( $Fields[4] =~ /(\d+)[\s\.]*(\d*)/ ) {
            $Ob->{LON} = $1 + $2 / 60;
        }
        else {
            die "Bad longitude $Fields[4]";
        }
        if ( $Fields[4] =~ /[eE]/ ) { $Lon_flag = 'E'; }
        if ( $Fields[4] =~ /[wW]/ ) { $Lon_flag = 'W'; }
        if ( $Lon_flag eq 'W' ) { $Ob->{LON} *= -1; }
    }

    # 3 a.m. ob with minimum temperature
    $Ob->{HR} = 3;

    # Assign minimum temperature to 3 a.m.
    # Temperatures converted from Farenheit
    if ( defined( $Fields[6] ) && $Fields[6] =~ /\d/ ) {
        $Ob->{AT} = fxtftc( $Fields[6] );
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
        $Ob->{IT} = 6;          # Temps in whole degF
    }

    # Add the original record as a supplemental attachment
    push @{ $Ob->{attachments} }, 99;
    $Ob->{ATTE} = undef;
    chomp($Line);
    chop($Line);
    $Ob->{SUPD} = $Line;

    $Ob->write($fh);

    # Don't want the attachment in the day's subsequent records
    @{ $Ob->{attachments} } = (0);
    $Ob->{SUPD} = undef;

    # 3 PM ob
    if ( defined( $Fields[5] ) && $Fields[5] =~ /\d/ ) {
        foreach (qw(HR AT SST SLP)) { $Ob->{$_} = undef; }
        $Ob->{HR} = 15;

        # Assign maximum temperature to 3 p.m.
        if ( defined( $Fields[5] ) && $Fields[5] =~ /\d/ ) {
            $Ob->{AT} = fxtftc( $Fields[5] );
        }
        $Ob->write($fh);
    }

}

# Done the first pass - now find the positions for each hour

my ( %Lat, %Lon );
seek( $fh, 0, 0 );    # Rewind temporary file
while ( my $Ob = imma_read($fh) ) {
    unless ( defined( $Ob->{YR} )
        && defined( $Ob->{MO} )
        && defined( $Ob->{DY} )
        && defined( $Ob->{LAT} )
        && defined( $Ob->{LON} ) )
    {
        next;
    }
    $Lat{ sprintf "%04d/%02d/%02d", $Ob->{YR}, $Ob->{MO}, $Ob->{DY} }[12] =
      $Ob->{LAT};
    $Lon{ sprintf "%04d/%02d/%02d", $Ob->{YR}, $Ob->{MO}, $Ob->{DY} }[12] =
      $Ob->{LON};
}

# Interpolate to every hour
foreach my $Day ( sort( keys(%Lat) ) ) {
    $Day =~ /(\d\d\d\d).(\d\d).(\d\d)/ or die "Bad day $Day";
    my ( $Yr, $Mo, $Dy ) = ( $1, $2, $3 );
    unless ( check_date( $Yr, $Mo, $Dy ) ) {
        warn "Bad Date: $Yr, $Mo, $Dy";
        next;
    }
    my $Before = sprintf "%04d/%02d/%02d", Add_Delta_Days( $Yr, $Mo, $Dy, -1 );
    my $After  = sprintf "%04d/%02d/%02d", Add_Delta_Days( $Yr, $Mo, $Dy, +1 );
    if ( defined( $Lat{$Before}[12] ) ) {
        for ( my $Hour = 0 ; $Hour < 12 ; $Hour++ ) {
            my $Weight = ( $Hour + 12 ) / 24;
            $Lat{$Day}[$Hour] =
              $Lat{$Day}[12] * $Weight + $Lat{$Before}[12] * ( 1 - $Weight );
            $Lon{$Day}[$Hour] =
              $Lon{$Day}[12] * $Weight + $Lon{$Before}[12] * ( 1 - $Weight );
        }
    }
    if ( defined( $Lat{$After}[12] ) ) {
        for ( my $Hour = 13 ; $Hour < 24 ; $Hour++ ) {
            my $Weight = ( 36 - $Hour ) / 24;
            $Lat{$Day}[$Hour] =
              $Lat{$Day}[12] * $Weight + $Lat{$After}[12] * ( 1 - $Weight );
            $Lon{$Day}[$Hour] =
              $Lon{$Day}[12] * $Weight + $Lon{$After}[12] * ( 1 - $Weight );
        }
    }
}

# Convert the ob positions to those interpolated at the observation hours,
#  And correct the dates to UTC
seek( $fh, 0, 0 );    # Rewind temporary file
while ( my $Ob = imma_read($fh) ) {
    if (   defined( $Ob->{YR} )
        && defined( $Ob->{MO} )
        && defined( $Ob->{DY} )
        && defined( $Ob->{HR} ) )
    {
        my $Day = sprintf "%04d/%02d/%02d", $Ob->{YR}, $Ob->{MO}, $Ob->{DY};
        if ( defined( $Lat{$Day}[ $Ob->{HR} ] ) ) {
            $Ob->{LAT} = $Lat{$Day}[ $Ob->{HR} ];
            $Ob->{LON} = $Lon{$Day}[ $Ob->{HR} ];
        }
        else {
            $Ob->{LAT} = undef;
            $Ob->{LON} = undef;
        }

        if ( defined( $Ob->{LON} ) ) {
            my $elon = $Ob->{LON};
            if ( $elon < 0 ) { $elon += 360; }
            if($elon > 359.99) { $elon=0; }
            my ( $uhr, $udy ) = rxltut(
                $Ob->{HR} * 100,
                ixdtnd( $Ob->{DY}, $Ob->{MO}, $Ob->{YR} ),
                $elon * 100
            );
            $Ob->{HR} = $uhr / 100;
            ( $Ob->{DY}, $Ob->{MO}, $Ob->{YR} ) = rxnddt($udy);
        }
        else { $Ob->{HR} = undef; }
        $Ob->write( \*STDOUT );
    }
}


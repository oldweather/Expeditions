#!/usr/bin/perl

# Process digitised logbook data from the Hecla into
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
my $Ship_name = 'Hecla';
my $Last_lat  = 59.5;
my $Last_lon  = -9.5;
my $Year      = 1819;
my $Month     = 5;

# Flag negative temperatures
my $Tneg = 0;

for ( my $i = 0 ; $i < 7 ; $i++ ) { <>; }    # Skip headers

while ( my $Line = <> ) {
    unless ( $Line =~ /\d/ ) { next; }
    my $Ob = new IMMA;
    $Ob->clear();                            # Why is this necessary?
    push @{ $Ob->{attachments} }, 0;
    my @Fields = split /\t/, $Line;

    if ( defined( $Fields[0] ) && $Fields[0] =~ /\d/ ) { $Year  = $Fields[0]; }
    if ( defined( $Fields[1] ) && $Fields[1] =~ /\d/ ) { $Month = $Fields[1]; }

    $Ob->{YR} = $Year;
    $Ob->{MO} = $Month;
    $Ob->{DY} = $Fields[2];

    if (   defined( $Fields[4] )
        && $Fields[4] =~ /[a-zA-Z]/
        && $Fields[4] !~ /^\s*\d/ )
    {    # Text position
        my $Tpos = $Fields[4] . $Fields[5] . $Fields[6] . $Fields[7];
        if ( lc($Tpos) =~ /winter harbour/ ) {
            $Ob->{LAT} = 74.79;
            $Ob->{LON} = -110.81;
            $Ob->{LI}  = 6;         # Metadata
        }
        else {
            warn "No position for $Tpos";
        }
    }
    else {
        if ( $Fields[4] =~ /\d/ ) {
            if ( $Fields[4] =~ /(\d+)\s+(\d+)\D*(\d*)/ ) {
                $Ob->{LAT} = $1 + $2 / 60;
                if ( defined($3) && $3 =~ /(\d+)/ ) { $Ob->{LAT} += $1 / 3600; }
            }
            else {
                die "Bad latitude $Fields[4]";
            }
        }
        elsif ( $Fields[5] =~ /\d/ ) {
            if ( $Fields[5] =~ /(\d+)\s+(\d+)\D*(\d*)/ ) {
                $Ob->{LAT} = $1 + $2 / 60;
                if ( defined($3) && $3 =~ /(\d+)/ ) { $Ob->{LAT} += $1 / 3600; }
            }
            else {
                die "Bad latitude $Fields[5]";
            }
        }
        if ( $Fields[6] =~ /\d/ ) {
            if ( $Fields[6] =~ /(\d+)\s+(\d+)\D*(\d*)/ ) {
                $Ob->{LON} = $1 + $2 / 60;
                if ( defined($3) && $3 =~ /(\d+)/ ) { $Ob->{LON} += $1 / 3600; }
                $Ob->{LON} *= -1;
            }
            else {
                die "Bad longitude $Fields[6]";
            }
        }
        elsif ( $Fields[7] =~ /\d/ ) {
            if ( $Fields[7] =~ /(\d+)\s+(\d+)\D*(\d*)/ ) {
                $Ob->{LON} = $1 + $2 / 60;
                if ( defined($3) && $3 =~ /(\d+)/ ) { $Ob->{LON} += $1 / 3600; }
                $Ob->{LON} *= -1;
            }
            else {
                die "Bad longitude $Fields[7]";
            }
        }
        if ( defined( $Ob->{LAT} ) || defined( $Ob->{LON} ) ) {
            $Ob->{LI} = 4;    # Deg+Min position precision
        }
    }
    if ( defined( $Ob->{LAT} ) ) { $Last_lat = $Ob->{LAT}; }
    if ( defined( $Ob->{LON} ) ) { $Last_lon = $Ob->{LON}; }

    # The source doesn't distinguish between positive and negative
    #  temperatures - so we need to guess.
    if ( $Fields[11] == $Fields[12] ) {    # Max=Min
        if (
            abs( $Fields[13] - ( $Fields[11] + $Fields[12] ) / 2 ) >
            abs( $Fields[13] - ( $Fields[11] - $Fields[12] ) / 2 ) )
        {
            $Fields[12] *= -1;    # Closer to mean assuming -ve min and +ve max
        }
        else {    # Both +ve or both -ve : assume same as last time
            if ( $Tneg == 1 ) {
                $Fields[11] *= -1;
                $Fields[12] *= -1;
            }
        }
    }
    elsif ( $Fields[11] > $Fields[12] ) {    # Max>Min - Max definitely +ve
        if (
            abs( $Fields[13] - ( $Fields[11] + $Fields[12] ) / 2 ) >
            abs( $Fields[13] - ( $Fields[11] - $Fields[12] ) / 2 ) )
        {
            $Fields[12] *= -1;               # Closer to mean assuming -ve min
        }
    }
    else {                                   # Max<Min - Min definitely -ve
        if (
            abs( $Fields[13] - ( $Fields[11] - $Fields[12] ) / 2 ) >
            abs( $Fields[13] - ( $Fields[11] + $Fields[12] ) / 2 ) )
        {
            $Fields[11] *= -1;               # Closer to mean assuming -ve max
        }
        $Fields[12] *= -1;
    }
    if   ( $Fields[11] < 0 ) { $Tneg = 1; }
    else                     { $Tneg = 0; }

    # 3 a.m. ob
    $Ob->{HR} = 3;

    # Assign minimum temperature to 3 a.m.
    # Temperatures converted from Farenheit
    if ( defined( $Fields[12] ) && $Fields[12] =~ /\d/ ) {
        $Ob->{AT} = fxtftc( $Fields[12] );
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
    chop($Line);
    $Ob->{SUPD} = $Line;

    $Ob->write($fh);

    # Don't want the attachment in the day's subsequent records
    @{ $Ob->{attachments} } = (0);
    $Ob->{SUPD} = undef;

    # 3 PM ob
    if ( defined( $Fields[11] ) && $Fields[11] =~ /\d/ ) {
        foreach (qw(HR AT SST SLP)) { $Ob->{$_} = undef; }
        $Ob->{HR} = 15;

        # Assign maximum temperature to 3 p.m.
        if ( defined( $Fields[11] ) && $Fields[11] =~ /\d/ ) {
            $Ob->{AT} = fxtftc( $Fields[11] );
        }
        # Assign SST to 3 p.m. (Arbitrarily)
        if ( defined( $Fields[14] ) && $Fields[14] =~ /\d/ ) {
            $Ob->{SST} = fxtftc( $Fields[14] );
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


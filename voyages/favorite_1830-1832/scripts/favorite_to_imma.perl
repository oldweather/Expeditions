#!/usr/bin/perl

# Process digitised logbook data from the Favorite into
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

use MarineOb::lmrlib qw(fxtrtc ixdtnd rxltut rxnddt fxfimb fwbptc fwbpgv);

# Temporary file for holding the records between passes
#my $fh = IO::File->new_tmpfile or die "Unable to create tempfile: $!";
my $fh;
open( $fh, "+>tmp.imma" );

# Load the obs and convert to IMMA
my $Ship_name = 'Favorite';
my $Last_lat;
my $Last_lon;
my $Lon_f  = 'W';
my $Lat_f  = 'N';
my $InPort = 0;

for ( my $i = 0 ; $i < 4 ; $i++ ) { <>; }    # Skip headers

while ( my $Line = <> ) {
    unless ( $Line =~ /\d/ ) { next; }
    my $Ob = new IMMA;
    $Ob->clear();                            # Why is this necessary?
    push @{ $Ob->{attachments} }, 0;
    my @Fields = split /\t/, $Line;

    $Ob->{YR} = $Fields[0];
    $Ob->{MO} = $Fields[1];
    $Ob->{DY} = $Fields[2];

    if (   defined( $Fields[3] )
        && $Fields[3] =~ /[a-zA-Z]/
        && $Fields[4] !~ /^\s*\d/ )
    {                                        # Text position
        ( $Ob->{LAT}, $Ob->{LON} ) =
          position_from_port( $Fields[3] . $Fields[4] );
        $Ob->{LI} = 6;                       # Position from metadata
        $InPort = 1;
    }
    elsif ( $Fields[3] =~ /\S+/ ) {
        if ( $Fields[3] =~ /\d/ ) {
            if ( $Fields[3] =~ /(\d+)\D+(\d+)\D+(\d*)/ ) {
                $Ob->{LAT} = $1 + $2 / 60 + $3 / 3600;
                if ( $Fields[3] =~ /.*[sS]/ ) { $Lat_f = 'S'; }
                if ( $Fields[3] =~ /.*[nN]/ ) { $Lat_f = 'N'; }
                if ( $Lat_f eq 'S' ) { $Ob->{LAT} *= -1; }
            }
            else {
                die "Bad latitude $Fields[3]";
            }
        }
        if ( $Fields[4] =~ /\d/ ) {
            if ( $Fields[4] =~ /(\d+)\D+(\d+)\D+(\d+)/ ) {
                $Ob->{LON} = $1 + $2 / 60 + $3 / 3600;
                if ( $Fields[4] =~ /.*[eE]/ ) { $Lon_f = 'E'; }
                if ( $Fields[4] =~ /.*[wW]/ ) { $Lon_f = 'W'; }
                if ( $Lon_f eq 'W' ) { $Ob->{LON} *= -1; }
                $Ob->{LON} += 2.33;    # Paris meridian
                if($Ob->{LON}>180) { $Ob->{LON} -= 360; }
            }
            else {
                die "Bad longitude $Fields[4]";
            }
        }
        if ( defined( $Ob->{LAT} ) || defined( $Ob->{LON} ) ) {
            $Ob->{LI} = 4;             # Deg+Min position precision
            $InPort = 0;
        }
    }
    elsif ( $InPort == 1 ) {           # Still in port, use last location
        $Ob->{LAT} = $Last_lat;
        $Ob->{LON} = $Last_lon;
        $Ob->{LI}  = 6;                # Position from metadata
    }
    if ( defined( $Ob->{LAT} ) ) { $Last_lat = $Ob->{LAT}; }
    if ( defined( $Ob->{LON} ) ) { $Last_lon = $Ob->{LON}; }

    # 6 a.m. ob
    $Ob->{HR} = 6;

    # Temperatures in Reamur
    if ( defined( $Fields[5] ) && $Fields[5] =~ /\d/ ) {
        $Ob->{AT} = fxtrtc($Fields[5]);
    }

    # Pressure converted from Paris lines
    if ( defined( $Fields[11] ) && $Fields[11] =~ /(\d+)\D(\d+)\D(\d+)/ ) {
        $Ob->{SLP} = fxfimb( $1 + $2 / 12 + $3 / 120 );
    }

    # Temperature correction
    if (   defined( $Ob->{SLP} )
        && defined( $Ob->{AT} ) )
    {
        $Ob->{SLP} += fwbptc( $Ob->{SLP}, $Ob->{AT} );
    }
    else { $Ob->{SLP} = undef; }

    # Gravity correction
    if ( defined( $Ob->{SLP} ) && defined($Last_lat) ) {
        $Ob->{SLP} += fwbpgv( $Ob->{SLP}, $Last_lat, 2 );
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
    $Ob->{C1}   = '04';         # French
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

    # 9 AM ob
    foreach (qw(HR AT SST SLP)) { $Ob->{$_} = undef; }
    $Ob->{HR} = 9;

    # Temperatures in Reamur
    if ( defined( $Fields[6] ) && $Fields[6] =~ /\d/ ) {
        $Ob->{AT} = fxtrtc($Fields[6]);
    }

    # Pressure converted from Paris lines
    if ( defined( $Fields[12] ) && $Fields[12] =~ /(\d+)\D(\d+)\D(\d+)/ ) {
        $Ob->{SLP} = fxfimb( $1 + $2 / 12 + $3 / 120 );
    }

    # Temperature correction
    if (   defined( $Ob->{SLP} )
        && defined( $Ob->{AT} ) )
    {
        $Ob->{SLP} += fwbptc( $Ob->{SLP}, $Ob->{AT} );
    }
    else { $Ob->{SLP} = undef; }

    # Gravity correction
    if ( defined( $Ob->{SLP} ) && defined($Last_lat) ) {
        $Ob->{SLP} += fwbpgv( $Ob->{SLP}, $Last_lat, 2 );
    }
    $Ob->write($fh);

    # Noon ob
    foreach (qw(HR AT SST SLP)) { $Ob->{$_} = undef; }
    $Ob->{HR} = 12;

    # Temperatures in Reamur
    if ( defined( $Fields[7] ) && $Fields[7] =~ /\d/ ) {
        $Ob->{AT} = fxtrtc($Fields[7]);
    }

    # Pressure converted from Paris lines
    if ( defined( $Fields[13] ) && $Fields[13] =~ /(\d+)\D(\d+)\D(\d+)/ ) {
        $Ob->{SLP} = fxfimb( $1 + $2 / 12 + $3 / 120 );
    }

    # Temperature correction
    if (   defined( $Ob->{SLP} )
        && defined( $Ob->{AT} ) )
    {
        $Ob->{SLP} += fwbptc( $Ob->{SLP}, $Ob->{AT} );
    }
    else { $Ob->{SLP} = undef; }

    # Gravity correction
    if ( defined( $Ob->{SLP} ) && defined($Last_lat) ) {
        $Ob->{SLP} += fwbpgv( $Ob->{SLP}, $Last_lat, 2 );
    }
    $Ob->write($fh);

    # 3 pm ob
    foreach (qw(HR AT SST SLP)) { $Ob->{$_} = undef; }
    $Ob->{HR} = 15;

    # Temperatures in Reamur
    if ( defined( $Fields[8] ) && $Fields[8] =~ /\d/ ) {
        $Ob->{AT} = fxtrtc($Fields[8]);
    }

    # Pressure converted from Paris lines
    if ( defined( $Fields[14] ) && $Fields[14] =~ /(\d+)\D(\d+)\D(\d+)/ ) {
        $Ob->{SLP} = fxfimb( $1 + $2 / 12 + $3 / 120 );
    }

    # Temperature correction
    if (   defined( $Ob->{SLP} )
        && defined( $Ob->{AT} ) )
    {
        $Ob->{SLP} += fwbptc( $Ob->{SLP}, $Ob->{AT} );
    }
    else { $Ob->{SLP} = undef; }

    # Gravity correction
    if ( defined( $Ob->{SLP} ) && defined($Last_lat) ) {
        $Ob->{SLP} += fwbpgv( $Ob->{SLP}, $Last_lat, 2 );
    }
    $Ob->write($fh);

    # 6 pm ob
    foreach (qw(HR AT SST SLP)) { $Ob->{$_} = undef; }
    $Ob->{HR} = 15;

    # Temperatures in Reamur
    if ( defined( $Fields[9] ) && $Fields[9] =~ /\d/ ) {
        $Ob->{AT} = fxtrtc($Fields[9]);
    }

    # Pressure converted from Paris lines
    if ( defined( $Fields[15] ) && $Fields[15] =~ /(\d+)\D(\d+)\D(\d+)/ ) {
        $Ob->{SLP} = fxfimb( $1 + $2 / 12 + $3 / 120 );
    }

    # Temperature correction
    if (   defined( $Ob->{SLP} )
        && defined( $Ob->{AT} ) )
    {
        $Ob->{SLP} += fwbptc( $Ob->{SLP}, $Ob->{AT} );
    }
    else { $Ob->{SLP} = undef; }

    # Gravity correction
    if ( defined( $Ob->{SLP} ) && defined($Last_lat) ) {
        $Ob->{SLP} += fwbpgv( $Ob->{SLP}, $Last_lat, 2 );
    }
    $Ob->write($fh);

    # midnight ob
    foreach (qw(HR AT SST SLP)) { $Ob->{$_} = undef; }
    $Ob->{HR} = 23.99;

    # Temperatures in Reamur
    if ( defined( $Fields[10] ) && $Fields[10] =~ /\d/ ) {
        $Ob->{AT} = fxtrtc($Fields[10]);
    }

    # Pressure converted from Paris lines
    if ( defined( $Fields[16] ) && $Fields[16] =~ /(\d+)\D(\d+)\D(\d+)/ ) {
        $Ob->{SLP} = fxfimb( $1 + $2 / 12 + $3 / 120 );
    }

    # Temperature correction
    if (   defined( $Ob->{SLP} )
        && defined( $Ob->{AT} ) )
    {
        $Ob->{SLP} += fwbptc( $Ob->{SLP}, $Ob->{AT} );
    }
    else { $Ob->{SLP} = undef; }

    # Gravity correction
    if ( defined( $Ob->{SLP} ) && defined($Last_lat) ) {
        $Ob->{SLP} += fwbpgv( $Ob->{SLP}, $Last_lat, 2 );
    }
    $Ob->write($fh);

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
            my $Lob = $Lon{$Before}[12];
            if ( $Lon{$Day}[12] - $Lon{$Before}[12] > 320 ) { $Lob += 360; }
            if ( $Lon{$Day}[12] - $Lon{$Before}[12] < -320 ) { $Lob -= 360; }
            $Lon{$Day}[$Hour] =
              $Lon{$Day}[12] * $Weight + $Lob * ( 1 - $Weight );
            if ( $Lon{$Day}[$Hour] < -180 ) { $Lon{$Day}[$Hour] += 360; }
            if ( $Lon{$Day}[$Hour] > 180 ) { $Lon{$Day}[$Hour] -= 360; }
        }
    }
    if ( defined( $Lat{$After}[12] ) ) {
        for ( my $Hour = 13 ; $Hour < 24 ; $Hour++ ) {
            my $Weight = ( 36 - $Hour ) / 24;
            $Lat{$Day}[$Hour] =
              $Lat{$Day}[12] * $Weight + $Lat{$After}[12] * ( 1 - $Weight );
            my $Lob = $Lon{$After}[12];
            if ( $Lon{$Day}[12] - $Lon{$After}[12] > 320 ) { $Lob += 360; }
            if ( $Lon{$Day}[12] - $Lon{$After}[12] < -320 ) { $Lob -= 360; }
            $Lon{$Day}[$Hour] =
              $Lon{$Day}[12] * $Weight + $Lob * ( 1 - $Weight );
            if ( $Lon{$Day}[$Hour] < -180 ) { $Lon{$Day}[$Hour] += 360; }
            if ( $Lon{$Day}[$Hour] > 180 ) { $Lon{$Day}[$Hour] -= 360; }
        }
    }
}

# Get rid of the temporary file
unlink 'tmp.imma';

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
        $Ob->write( \*STDOUT );
    }
}

sub position_from_port {
    my $Name = lc(shift);
    if ( $Name =~ /goree/ ) {
        return ( 14.66, -17.4 );
    }
    if ( $Name =~ /bourbon/ ) {    # Mauritius? (not Reunion)
        return ( -20.4, 57.8 );
    }
    if ( $Name =~ /mazulipatnam/ ) {    # Coromandel, India?
        return ( undef, undef );
    }
    if ( $Name =~ /coringui/ ) {
        return ( undef, undef );
    }
    if ( $Name =~ /manille/ ) {         # Manilla
        return ( 14.5, 120.8 );
    }
    if ( $Name =~ /macao/ ) {           # Macau
        return ( 22.2, 113.55 );
    }
    if ( $Name =~ /tourane/ ) {         # Da Nang, Vietnam
        return ( 16.07, 108.22 );
    }
    if ( $Name =~ /tunquin|china sea/ ) {    # Tonkin?
        return ( 20.75, 106.83 );
    }
    if ( $Name =~ /belle/ ) {                # ?
        return ( undef, undef );
    }
    if ( $Name =~ /terempa/ ) {              # Pulau terempa, Indonesia?
        return ( 3.17, 106.25 );
    }
    if ( $Name =~ /java/ ) {                 # at 110 E - assume north coast
        return ( -6.88, 110.13 );
    }
    if ( $Name =~ /hobart/ ) {
        return ( -42.91, 147.33 );
    }
    if ( $Name =~ /port jackson/ ) {
        return ( -33.9, 151.2 );
    }
    if ( $Name =~ /korora-reka/ ) {          # Russel, NZ
        return ( -35.27, 174.12 );
    }
    if ( $Name =~ /valparaiso/ ) {
        return ( -33.05, -71.62 );
    }
    if ( $Name =~ /rio de janeiro/ ) {
        return ( -22.9, -43.13 );
    }
    if ( $Name =~ /toulon/ ) {
        return ( 43.13, 5.92 );
    }
    die "Unknown port $Name";
}

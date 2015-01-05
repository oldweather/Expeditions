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
use Date::Calc qw(Add_Delta_Days Delta_Days Delta_DHMS);
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
my $Year      = 1824;

while ( my $Line = <> ) {
    unless ( $Line =~ /^\s*\d/ ) { next; }
    unless ( $Line =~ /^\s*18/ ) { next; }
    my $Ob = new IMMA;
    $Ob->clear();    # Why is this necessary?
    push @{ $Ob->{attachments} }, 0;
    my @Fields = split /\t/, $Line;

    $Ob->{YR} = $Fields[0];
    $Ob->{MO} = $Fields[1];
    $Ob->{DY} = $Fields[2];

    if ( Delta_Days( $Fields[0], $Ob->{MO}, $Ob->{DY}, 1824, 11, 1 ) <= 0 )
    {                # Second format
        if ( Delta_Days( $Ob->{YR}, $Ob->{MO}, $Ob->{DY}, 1825, 7, 20 ) > 0 ) {

            # In winter quarters off Port Bowen
            $Ob->{LAT} = 73.23;
            $Ob->{LON} = -88.92;
            $Ob->{LI}  = 6;        # Position from metadata
        }
        else {
            $Fields[3] =~ /(\d+)\s+(\d+)\s+(\d+)/ or die "Bad Lat $Fields[3]";
            $Ob->{LAT} = $1 + $2 / 60 + $3 / 3600;
            $Fields[4] =~ /(\d+)\s+(\d+)\s+(\d+)/ or die "Bad Lon $Fields[4]";
            $Ob->{LON} = ($1 + $2 / 60 + $3 / 3600)*-1;
            $Ob->{LI}  = 4;                         # Deg+Min position precision
        }
        $Last_lat = $Ob->{LAT};
        $Last_lon = $Ob->{LON};

        # 3 a.m. ob
        $Ob->{HR} = 3;

        # Pressure converted from inches
        if ( defined( $Fields[5] ) && $Fields[5] =~ /\d/ ) {
            $Ob->{SLP} = fxeimb( $Fields[5] );
        }

        # No attached thermometer, so no temperature correction
        # Gravity correction
        if ( defined( $Ob->{SLP} ) && defined($Last_lat) ) {
            $Ob->{SLP} += fwbpgv( $Ob->{SLP}, $Last_lat, 2 );
        }

        # Assign minimum temperature to 3 a.m.
        # Temperatures converted from Farenheit
        if ( defined( $Fields[18] ) && $Fields[18] =~ /\d/ ) {
            $Ob->{AT} = fxtftc( $Fields[18] );
        }

        if ( defined( $Fields[21] ) && $Fields[21] =~ /\d/ ) {
            $Ob->{SST} = fxtftc( $Fields[21] );
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

        # 4 AM ob
        if ( defined( $Fields[6] ) && $Fields[6] =~ /\d/ ) {
            foreach (qw(HR AT SST SLP)) { $Ob->{$_} = undef; }
            $Ob->{HR}  = 4;
            $Ob->{SLP} = fxeimb( $Fields[6] );
            $Ob->{SLP} += fwbpgv( $Ob->{SLP}, $Last_lat, 2 );
            $Ob->write($fh);
        }

        # 5 AM ob
        if ( defined( $Fields[7] ) && $Fields[7] =~ /\d/ ) {
            foreach (qw(HR AT SST SLP)) { $Ob->{$_} = undef; }
            $Ob->{HR}  = 5;
            $Ob->{SLP} = fxeimb( $Fields[7] );
            $Ob->{SLP} += fwbpgv( $Ob->{SLP}, $Last_lat, 2 );
            $Ob->write($fh);
        }

        # 9 AM ob
        if ( defined( $Fields[8] ) && $Fields[8] =~ /\d/ ) {
            foreach (qw(HR AT SST SLP)) { $Ob->{$_} = undef; }
            $Ob->{HR}  = 9;
            $Ob->{SLP} = fxeimb( $Fields[8] );
            $Ob->{SLP} += fwbpgv( $Ob->{SLP}, $Last_lat, 2 );
            $Ob->write($fh);
        }

        # 10 AM ob
        if ( defined( $Fields[9] ) && $Fields[9] =~ /\d/ ) {
            foreach (qw(HR AT SST SLP)) { $Ob->{$_} = undef; }
            $Ob->{HR}  = 10;
            $Ob->{SLP} = fxeimb( $Fields[9] );
            $Ob->{SLP} += fwbpgv( $Ob->{SLP}, $Last_lat, 2 );
            $Ob->write($fh);
        }

        # 11 AM ob
        if ( defined( $Fields[10] ) && $Fields[10] =~ /\d/ ) {
            foreach (qw(HR AT SST SLP)) { $Ob->{$_} = undef; }
            $Ob->{HR}  = 11;
            $Ob->{SLP} = fxeimb( $Fields[10] );
            $Ob->{SLP} += fwbpgv( $Ob->{SLP}, $Last_lat, 2 );
            $Ob->write($fh);
        }

        # 3 PM ob
        if ( defined( $Fields[11] ) && $Fields[11] =~ /\d/ ) {
            foreach (qw(HR AT SST SLP)) { $Ob->{$_} = undef; }
            $Ob->{HR}  = 15;
            $Ob->{SLP} = fxeimb( $Fields[11] );
            $Ob->{SLP} += fwbpgv( $Ob->{SLP}, $Last_lat, 2 );

            # Assign maximum temperature to 3 p.m.
            if ( defined( $Fields[17] ) && $Fields[17] =~ /\d/ ) {
                $Ob->{AT} = fxtftc( $Fields[17] );
            }
            $Ob->write($fh);
        }

        # 4 PM ob
        if ( defined( $Fields[12] ) && $Fields[12] =~ /\d/ ) {
            foreach (qw(HR AT SST SLP)) { $Ob->{$_} = undef; }
            $Ob->{HR}  = 16;
            $Ob->{SLP} = fxeimb( $Fields[12] );
            $Ob->{SLP} += fwbpgv( $Ob->{SLP}, $Last_lat, 2 );
            $Ob->write($fh);
        }

        # 5 PM ob
        if ( defined( $Fields[13] ) && $Fields[13] =~ /\d/ ) {
            foreach (qw(HR AT SST SLP)) { $Ob->{$_} = undef; }
            $Ob->{HR}  = 17;
            $Ob->{SLP} = fxeimb( $Fields[13] );
            $Ob->{SLP} += fwbpgv( $Ob->{SLP}, $Last_lat, 2 );
            $Ob->write($fh);
        }

        # 9 PM ob
        if ( defined( $Fields[14] ) && $Fields[14] =~ /\d/ ) {
            foreach (qw(HR AT SST SLP)) { $Ob->{$_} = undef; }
            $Ob->{HR}  = 21;
            $Ob->{SLP} = fxeimb( $Fields[14] );
            $Ob->{SLP} += fwbpgv( $Ob->{SLP}, $Last_lat, 2 );
            $Ob->write($fh);
        }

        # 10 PM ob
        if ( defined( $Fields[15] ) && $Fields[15] =~ /\d/ ) {
            foreach (qw(HR AT SST SLP)) { $Ob->{$_} = undef; }
            $Ob->{HR}  = 22;
            $Ob->{SLP} = fxeimb( $Fields[15] );
            $Ob->{SLP} += fwbpgv( $Ob->{SLP}, $Last_lat, 2 );
            $Ob->write($fh);
        }

        # 11 PM ob
        if ( defined( $Fields[16] ) && $Fields[16] =~ /\d/ ) {
            foreach (qw(HR AT SST SLP)) { $Ob->{$_} = undef; }
            $Ob->{HR}  = 23;
            $Ob->{SLP} = fxeimb( $Fields[16] );
            $Ob->{SLP} += fwbpgv( $Ob->{SLP}, $Last_lat, 2 );
            $Ob->write($fh);
        }

    }    # End of second format

    else {    # first format
        if ( Delta_Days( $Ob->{YR}, $Ob->{MO}, $Ob->{DY}, 1824, 9, 27 ) <= 0 ) {

            # In winter quarters off Port Bowen
            $Ob->{LAT} = 73.23;
            $Ob->{LON} = -88.92;
            $Ob->{LI}  = 6;        # Position from metadata
        }
        else {
            $Fields[3] =~ /(\d+)\s+(\d+)\s+(\d+)/ or die "Bad Lat $Fields[3]";
            $Ob->{LAT} = $1 + $2 / 60 + $3 / 3600;
            $Fields[4] =~ /(\d+)\s+(\d+)\s+(\d+)/ or die "Bad Lon $Fields[4]";
            $Ob->{LON} = ($1 + $2 / 60 + $3 / 3600)*-1;
            $Ob->{LI}  = 4;                         # Deg+Min position precision
        }
        $Last_lat = $Ob->{LAT};
        $Last_lon = $Ob->{LON};

        # 3 a.m. ob
        $Ob->{HR} = 3;

        # Pressure converted from inches
        if ( defined( $Fields[5] ) && $Fields[5] =~ /\d/ ) {
            $Ob->{SLP} = fxeimb( $Fields[5] );
        }

        # No attached thermometer, so no temperature correction
        # Gravity correction
        if ( defined( $Ob->{SLP} ) && defined($Last_lat) ) {
            $Ob->{SLP} += fwbpgv( $Ob->{SLP}, $Last_lat, 2 );
        }

        # Assign minimum temperature to 3 a.m.
        # Temperatures converted from Farenheit
        if ( defined( $Fields[10] ) && $Fields[10] =~ /\d/ ) {
            $Ob->{AT} = fxtftc( $Fields[10] );
        }

        if ( defined( $Fields[12] ) && $Fields[12] =~ /\d/ ) {
            $Ob->{SST} = fxtftc( $Fields[12] );
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

        # 9 AM ob
        foreach (qw(HR AT SST SLP)) { $Ob->{$_} = undef; }
        $Ob->{HR} = 9;

        # Pressure converted from inches
        if ( defined( $Fields[6] ) && $Fields[6] =~ /\d/ ) {
            $Ob->{SLP} = fxeimb( $Fields[6] );
        }

        # No attached thermometer, so no temperature correction
        # Gravity correction
        if ( defined( $Ob->{SLP} ) && defined($Last_lat) ) {
            $Ob->{SLP} += fwbpgv( $Ob->{SLP}, $Last_lat, 2 );
        }

        # No AT at 9a.m.

        if ( defined( $Fields[13] ) && $Fields[13] =~ /\d/ ) {
            $Ob->{SST} = fxtftc( $Fields[13] );
        }
        $Ob->write($fh);

        # 3 PM ob
        foreach (qw(HR AT SST SLP)) { $Ob->{$_} = undef; }
        $Ob->{HR} = 15;

        # Pressure converted from inches
        if ( defined( $Fields[7] ) && $Fields[7] =~ /\d/ ) {
            $Ob->{SLP} = fxeimb( $Fields[7] );
        }

        # No attached thermometer, so no temperature correction
        # Gravity correction
        if ( defined( $Ob->{SLP} ) && defined($Last_lat) ) {
            $Ob->{SLP} += fwbpgv( $Ob->{SLP}, $Last_lat, 2 );
        }

        # Assign maximum temperature to 3 p.m.
        if ( defined( $Fields[9] ) && $Fields[9] =~ /\d/ ) {
            $Ob->{AT} = fxtftc( $Fields[9] );
        }

        if ( defined( $Fields[14] ) && $Fields[14] =~ /\d/ ) {
            $Ob->{SST} = fxtftc( $Fields[14] );
        }
        $Ob->write($fh);

        # 9 PM ob
        foreach (qw(HR AT SST SLP)) { $Ob->{$_} = undef; }
        $Ob->{HR} = 21;

        # Pressure converted from inches
        if ( defined( $Fields[8] ) && $Fields[8] =~ /\d/ ) {
            $Ob->{SLP} = fxeimb( $Fields[8] );
        }

        # No attached thermometer, so no temperature correction
        # Gravity correction
        if ( defined( $Ob->{SLP} ) && defined($Last_lat) ) {
            $Ob->{SLP} += fwbpgv( $Ob->{SLP}, $Last_lat, 2 );
        }

        # No AT at 9 p.m.

        if ( defined( $Fields[15] ) && $Fields[15] =~ /\d/ ) {
            $Ob->{SST} = fxtftc( $Fields[15] );
        }
        $Ob->write($fh);

    }    # End of first format

}

# Done the first pass - now find the positions for each hour

my ( %Lat, %Lon );
seek( $fh, 0, 0 );    # Rewind temporary file
while ( my $Ob = imma_read($fh) ) {
    unless ( defined( $Ob->{YR} )
        && defined( $Ob->{MO} )
        && defined( $Ob->{DY} ) )
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
    my ($Yr,$Mo,$Dy) = ($1,$2,$3);
    my $Before = sprintf "%04d/%02d/%02d", Add_Delta_Days( $Yr, $Mo, $Dy, -1 );
    my $After  = sprintf "%04d/%02d/%02d", Add_Delta_Days( $Yr, $Mo, $Dy, +1 );
    if ( defined( $Lat{$Before}[12] ) ) {
        for ( my $Hour = 0 ; $Hour < 12 ; $Hour++ ) {
            my $Weight = ( $Hour + 12 ) / 24;
            $Lat{$Day}[$Hour] =
              $Lat{$Day}[12] * $Weight + $Lat{$Before}[12] * ( 1-$Weight );
            $Lon{$Day}[$Hour] =
              $Lon{$Day}[12] * $Weight + $Lon{$Before}[12] * ( 1-$Weight );
        }
    }
    if ( defined( $Lat{$After}[12] ) ) {
        for ( my $Hour = 13 ; $Hour < 24 ; $Hour++ ) {
            my $Weight = ( 36 - $Hour ) / 24;
            $Lat{$Day}[$Hour] =
              $Lat{$Day}[12] * $Weight + $Lat{$After}[12] * ( 1-$Weight );
            $Lon{$Day}[$Hour] =
              $Lon{$Day}[12] * $Weight + $Lon{$After}[12] * ( 1-$Weight );
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


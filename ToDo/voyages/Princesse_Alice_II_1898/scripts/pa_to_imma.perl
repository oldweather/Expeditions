#!/usr/bin/perl

# Process digitised logbook data from the Princesse Alice II into
#  IMMA records.

use strict;
use warnings;
use MarineOb::IMMA;
use Date::Calc qw(Delta_Days);
use MarineOb::lmrlib qw(rxltut ixdtnd rxnddt fxmmmb fwbptc fwbpgv
                        fxtftc fxbfms ix32dd);

my $Ship_name = 'PcsAlice2';
my ( $Year,     $Month,    $Day );
my ( $Last_lon, $Last_lat, $Last_T );
my $Lat_flag = 'N';
my $Lon_flag = 'W';
$Last_lon = -2.99;
$Last_lat = 53.40;

for ( my $i = 0 ; $i < 3 ; $i++ ) { <>; }    # Skip headers

while (<>) {
    my $Line = $_;
    my $Ob   = new MarineOb::IMMA;
    $Ob->clear();
    push @{ $Ob->{attachments} }, 0;
    my @Fields = split /,/, $_;

    if ( defined( $Fields[0] ) && $Fields[0] =~ /(\d\d\d\d)/ ) {
        $Year = $1;
    if ( defined( $Fields[1] ) && $Fields[1] =~ /(\d+)/ ) {
        $Month = $1;
    }
    if ( defined( $Fields[2] ) && $Fields[2] =~ /(\d+)/ ) {
        $Day = $1;
    }
    if ( defined( $Fields[3] ) && $Fields[3] =~ /(\d+)/ ) {
        $Hour = $1;
    }
    $Ob->{YR} = $Year;
    $Ob->{MO} = $Month;
    $Ob->{DY} = $Day;
    $Ob->{HR} = $Hour;
    if ( $Ob->{HR} == 24 ) { $Ob->{HR} = 23.99; }

    if ( defined( $Fields[13] ) && $Fields[13] =~ /(\d+)/ ) {
        $Ob->{LAT} = $Fields[13];
    }
    if ( defined( $Fields[14] ) && $Fields[14] =~ /(\d+)/ ) {
        $Ob->{LON} = $Fields[14];
    }

    # Convert ob date and time to UTC
    # Start by assuming at UTC
    if (   defined($Last_lon)
        && defined( $Ob->{HR} )
        && defined( $Ob->{DY} )
        && defined( $Ob->{MO} )
        && defined( $Ob->{YR} ) )
    {
        my $elon = 0;   # $Last_lon;
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


    if ( defined( $Fields[10] ) && $Fields[10] =~ /\d/ ) {
        $Ob->{SLP} = $Fields[10];             # in hPa
    }
    # Currently think barometer is an aneroid -> no corrections

    # Fill in extra metadata
    $Ob->{IM}   = 0;         # C
    $Ob->{ATTC} = 0;         # No attachments - may have supplemental, see below
    $Ob->{TI}   = 0;         # Nearest hour time precision
    $Ob->{DS}   = undef;     # Unknown course
    $Ob->{VS}   = undef;     # Unknown speed
    $Ob->{NID}  = 3;         #
    $Ob->{II}   = 10;        #
    $Ob->{ID}   = $Ship_name;
    $Ob->{C1}   = '04';      #
    if (   defined( $Ob->{AT} )
        || defined( $Ob->{WBT} )
        || defined( $Ob->{DPT} )
        || defined( $Ob->{SST} ) )
    {
        $Ob->{IT} = 4;                          # Temps in degF and 10ths
    }

    # Add the original record as a supplemental attachment
    if ( defined($Line) && $Line =~ /\S/ ) {
        chomp($Line);
        push @{ $Ob->{attachments} }, 99;
        $Ob->{ATTC}++;
        $Ob->{ATTE} = undef;
        $Ob->{SUPD} = $Line;
    }

    $Ob->write( \*STDOUT );

}


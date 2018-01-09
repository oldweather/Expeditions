#!/usr/bin/perl

# Process digitised logbook data from the Alligator into
#  IMMA records.

use strict;
use warnings;
use MarineOb::IMMA;
use Date::Calc qw(Delta_Days);
use MarineOb::lmrlib qw(rxltut ixdtnd rxnddt fxtftc fxeimb fwbpgv);

my $Ship_name = 'Alligator';
my ( $Year,     $Month,    $Day );
my ( $Last_lon, $Last_lat, $Last_T );
my $Lat_flag = 'S';
my $Lon_flag = 'W';
$Last_lat = -11.36;
$Last_lon = 132.15;

for ( my $i = 0 ; $i < 2 ; $i++ ) { <>; }    # Skip headers

while (<>) {
    my $Line = $_;
    chomp($Line);
    unless($Line =~ /^1/) { next; }
    my $Ob   = new MarineOb::IMMA;
    $Ob->clear();
    push @{ $Ob->{attachments} }, 0;
    my @Fields = split /\t/, $_;

    if ( defined( $Fields[0] ) && $Fields[0] =~ /\d/ ) {
        $Year = $Fields[0];
    }
    if ( defined( $Fields[1] ) && $Fields[1] =~ /\d/ ) {
        $Month = $Fields[1];
    }
    if ( defined( $Fields[2] ) && $Fields[2] =~ /\d/ ) {
        $Day = $Fields[2];
    }
    $Ob->{YR} = $Year;
    $Ob->{MO} = $Month;
    $Ob->{DY} = $Day;

    $Ob->{LAT} = $Last_lat;
    $Ob->{LON} = $Last_lon;


    # Fill in extra metadata
    $Ob->{IM}   = 0;         # Check with Scott
    $Ob->{ATTC} = 0;         # No attachments - may have supplemental, see below
    $Ob->{TI}   = 0;         # Nearest hour time precision
    $Ob->{DS}   = undef;     # Unknown course
    $Ob->{VS}   = undef;     # Unknown speed
    $Ob->{NID}  = 3;         # Check with Scott
    $Ob->{II}   = 10;        # Check with Scott
    $Ob->{ID}   = $Ship_name;
    $Ob->{C1}   = '02';      # UK recruited
    $Ob->{IT}   = 4;         # F and tenths

    # 4 a.m. ob.
    $Ob->{HR} = 4;
    correct_hour_for_lon($Ob,$Last_lon);

    if ( defined( $Fields[3] ) && $Fields[3] =~ /\d/ ) {
        $Ob->{AT} = fxtftc( $Fields[3] );
    }
    $Ob->write( \*STDOUT );
    # 8 a.m. ob.
    $Ob->{AT}  = undef;
    $Ob->{YR} = $Year;
    $Ob->{MO} = $Month;
    $Ob->{DY} = $Day;
    $Ob->{HR} = 8;
    correct_hour_for_lon($Ob,$Last_lon);

    if ( defined( $Fields[4] ) && $Fields[4] =~ /\d/ ) {
        $Ob->{AT} = fxtftc( $Fields[4] );
    }
    $Ob->write( \*STDOUT );

    # Noon ob.
    $Ob->{AT}  = undef;
    $Ob->{YR} = $Year;
    $Ob->{MO} = $Month;
    $Ob->{DY} = $Day;
    $Ob->{HR}  = 12;
    correct_hour_for_lon($Ob,$Last_lon);

    if ( defined( $Fields[5] ) && $Fields[5] =~ /\d/ ) {
        $Ob->{AT} = fxtftc( $Fields[5] );
    }
    if ( defined( $Fields[9] ) && $Fields[9] =~ /\d/ ) {
        $Ob->{SLP} = fxeimb( $Fields[9] );
    }
    if ( defined( $Ob->{SLP} ) && defined($Last_lat) ) {    # gravity correction
        $Ob->{SLP} += fwbpgv( $Ob->{SLP}, $Last_lat, 2 );
    }
    if ( defined($Line) && $Line =~ /\S/ ) {
        chomp($Line);
        push @{ $Ob->{attachments} }, 99;
        $Ob->{ATTC}++;
        $Ob->{ATTE} = undef;
        $Ob->{SUPD} = $Line;
    }
    $Ob->write( \*STDOUT );

    # 4 p.m. ob.
    $Ob->{AT}  = undef;
    $Ob->{SLP}  = undef;
    $Ob->{YR} = $Year;
    $Ob->{MO} = $Month;
    $Ob->{DY} = $Day;
    $Ob->{HR} = 16;
    correct_hour_for_lon($Ob,$Last_lon);

    if ( defined( $Fields[6] ) && $Fields[6] =~ /\d/ ) {
        $Ob->{AT} = fxtftc( $Fields[6] );
    }
    $Ob->write( \*STDOUT );
    # 8 p.m. ob.
    $Ob->{AT}  = undef;
    $Ob->{YR} = $Year;
    $Ob->{MO} = $Month;
    $Ob->{DY} = $Day;
    $Ob->{HR} = 20;
    correct_hour_for_lon($Ob,$Last_lon);

    if ( defined( $Fields[7] ) && $Fields[7] =~ /\d/ ) {
        $Ob->{AT} = fxtftc( $Fields[7] );
    }
    $Ob->write( \*STDOUT );
    # Midnight ob.
    $Ob->{AT}  = undef;
    $Ob->{YR} = $Year;
    $Ob->{MO} = $Month;
    $Ob->{DY} = $Day;
    $Ob->{HR}  = 23.99;
    correct_hour_for_lon($Ob,$Last_lon);

    if ( defined( $Fields[8] ) && $Fields[8] =~ /\d/ ) {
        $Ob->{AT} = fxtftc( $Fields[8] );
    }
    if ( defined( $Fields[9] ) && $Fields[9] =~ /\d/ ) {
        $Ob->{SLP} = fxeimb( $Fields[9] );
    }
    if ( defined( $Ob->{SLP} ) && defined($Last_lat) ) {    # gravity correction
        $Ob->{SLP} += fwbpgv( $Ob->{SLP}, $Last_lat, 2 );
    }

}


# Correct the date to UTC from local time
sub correct_hour_for_lon {
    my $Ob = shift;
    my $Last_lon = shift;
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
    return 1;
}

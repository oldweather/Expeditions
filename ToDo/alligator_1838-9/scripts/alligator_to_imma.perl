#!/usr/bin/perl

# Process digitised logbook data from the Alligator into
#  IMMA records.

use strict;
use warnings;
use IMMA;
use Date::Calc qw(Delta_Days);
use MarineOb::lmrlib qw(fxtftc fxeimb fwbpgv);

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
    unless($Line =~ /^1/) { next; }
    my $Ob   = new IMMA;
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
    correct_hour_for_lon($Ob);

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
    correct_hour_for_lon($Ob);

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
    correct_hour_for_lon($Ob);

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
    correct_hour_for_lon($Ob);

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
    correct_hour_for_lon($Ob);

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
    correct_hour_for_lon($Ob);

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
    my @Days_in_month = ( 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31 );
    my $Ob = shift;
    unless ( defined($Last_lon)
        && defined( $Ob->{HR} )
        && defined( $Ob->{DY} )
        && defined( $Ob->{MO} )
        && defined( $Ob->{YR} ) )
    {
        $Ob->{HR} = undef;
        return;
    }
    if ( $Ob->{YR} % 4 == 0
        && ( $Ob->{YR} % 100 != 0 || $Ob->{YR} % 400 == 0 ) )
    {
        $Days_in_month[1] = 29;
    }
    $Ob->{HR} += $Last_lon * 12 / 180;
    if ( $Ob->{HR} < 0 ) {
        $Ob->{HR} += 24;
        $Ob->{DY}--;
        if ( $Ob->{DY} <= 0 ) {
            $Ob->{MO}--;
            if ( $Ob->{MO} < 1 ) {
                $Ob->{YR}--;
                $Ob->{MO} = 12;
            }
            $Ob->{DY} = $Days_in_month[ $Ob->{MO} - 1 ];
        }
    }
    if ( $Ob->{HR} > 23.99 ) {
        $Ob->{HR} -= 24;
        if ( $Ob->{HR} < 0 ) { $Ob->{HR} = 0; }
        $Ob->{DY}++;
        if ( $Ob->{DY} > $Days_in_month[ $Ob->{MO} - 1 ] ) {
            $Ob->{DY} = 1;
            $Ob->{MO}++;
            if ( $Ob->{MO} > 12 ) {
                $Ob->{YR}++;
                $Ob->{MO} = 1;
            }
        }
    }
    if ( $Ob->{HR} == 23.99 ) { $Ob->{HR} = 23.98; }
    return 1;
}

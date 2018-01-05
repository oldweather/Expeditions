#!/usr/bin/perl

# Process the digitised Baquedano data into
#  IMMA records.

use strict;
use warnings;
use IMMA;
use Getopt::Long;
use FindBin;
use Date::Calc qw(Delta_Days);

my $Last_lon = 71.5;

for ( my $i = 0 ; $i < 4 ; $i++ ) { <>; }    # Skip headers

while ( my $Line = <> ) {
    my @Fields = split /\t/, $Line;
    my $Ob = new IMMA;
    $Ob->clear();
    push @{ $Ob->{attachments} }, 0;

    $Ob->{ID} = "Baquedano";

    # Date
    $Ob->{YR} = $Fields[3];
    $Ob->{MO} = $Fields[4];
    $Ob->{DY} = $Fields[5];
    $Ob->{HR} = $Fields[6];

    if ( defined( $Fields[21] ) && $Fields[21] =~ /\d/ ) {
        $Ob->{LAT} = $Fields[21] + $Fields[22] / 60;
        if ( defined( $Fields[23] ) && $Fields[23] =~ /S/ ) {
            $Ob->{LAT} *= -1;
        }
    }
    if ( defined( $Fields[27] ) && $Fields[27] =~ /\d/ ) {
        $Ob->{LON} = $Fields[27] + $Fields[28] / 60;
        if ( defined( $Fields[29] ) && $Fields[29] =~ /W/ ) {
            $Ob->{LON} *= -1;
        }
    }
    correct_hour_for_lon($Ob);

    $Ob->{IM}   = 0;        # Check with Scott
    $Ob->{ATTC} = 1;        # Supplemental
    $Ob->{TI}   = 0;        # Nearest hour time precision
    $Ob->{DS}   = undef;    # Unknown course
    $Ob->{VS}   = undef;    # Unknown speed
    $Ob->{NID}  = 3;        # Check with Scott
    $Ob->{II}   = 10;       # Check with Scott

    # Air temperature
    if ( $Fields[13] =~ /\d/ ) {
        $Ob->{AT} = $Fields[13];
    }

    # Sea temperature
    if ( $Fields[14] =~ /\d/ ) {
        $Ob->{SST} = $Fields[14];
    }

    # Pressure
    if ( defined( $Fields[11] ) && $Fields[11] =~ /\d/ ) {
        $Ob->{SLP} = $Fields[11] * 1.33322387415;
    }

    # Add the original record as a supplemental attachment
    push @{ $Ob->{attachments} }, 99;
    $Ob->{ATTE} = undef;
    chomp($Line);
    $Ob->{SUPD} = $Line;

    # Output the noon ob
    $Ob->write( \*STDOUT );

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

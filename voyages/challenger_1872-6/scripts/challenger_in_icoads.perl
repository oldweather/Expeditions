#!/usr/bin/perl -w

# Find IMMA records in ICOADS that are close to
#  one of the new Challenger observations.

use strict;
use warnings;
use IMMA;
use FindBin;
use Date::Calc qw(Day_of_Year Days_in_Year check_date);

# Make a hash table listing all the daily 1x1 degree boxes
#  within 5 degrees and 2 days of a challenger observation.
open( DIN, "$FindBin::Bin/../imma/challenger.imma" )
  or die "Can't get Challenger data";
my %Grids;
while ( my $Ob = imma_read( \*DIN ) ) {
    unless ( defined( $Ob->{LAT} )
        && defined( $Ob->{LON} )
        && defined( $Ob->{YR} )
        && defined( $Ob->{MO} )
        && defined( $Ob->{DY} ) )
    {
        next;
    }
    my $Day = Day_of_Year( $Ob->{YR}, $Ob->{MO}, $Ob->{DY} );
    my $Year_length = Days_in_Year( $Ob->{YR}, 12 );
    if ( $Ob->{LON} < 0 ) { $Ob->{LON} += 360; }
    for ( my $Delta_lat = -2 ; $Delta_lat <= 2 ; $Delta_lat++ ) {
        my $Lat_box = int( $Ob->{LAT} + 90 ) + $Delta_lat;
        if ( $Lat_box < 0 || $Lat_box > 179 ) { next; }
        for ( my $Delta_lon = -2 ; $Delta_lon <= 2 ; $Delta_lon++ ) {
            my $Lon_box = int( $Ob->{LON} ) + $Delta_lon;
            if ( $Lon_box < 0 ) { $Lon_box += 360; }
            if ( $Lon_box > 359 ) { $Lon_box -= 360; }
            for ( my $Delta_day = -2 ; $Delta_day <= 2 ; $Delta_day++ ) {
                my $Year = $Ob->{YR};
                my $DDay = $Day + $Delta_day;
                if ( $DDay > $Year_length ) {
                    $DDay -= $Year_length;
                    $Year++;
                }
                if ( $DDay < 0 ) {
                    $DDay += Days_in_Year( $Ob->{YR} - 1, 12 );
                    $Year--;
                }
                $Grids{ sprintf "%04d%04d%03d%03d",
                    $Year, $DDay, $Lat_box, $Lon_box }
                  = 1;
#                printf "%04d%04d%03d%03d %02d %02d\n",
#                    $Year, $DDay, $Lat_box, $Lon_box, $Ob->{MO}, $Ob->{DY};  
            }
        }
    }
}
close(DIN);
#die;

# Extract all the ICOADS 2.3 obs in one of these grid boxes
while(my $Ob = imma_read(\*STDIN)) {
    unless ( defined( $Ob->{LAT} )
        && defined( $Ob->{LON} )
        && defined( $Ob->{YR} )
        && defined( $Ob->{MO} )
        && defined( $Ob->{DY} )
        && check_date($Ob->{YR},$Ob->{MO},$Ob->{DY} ))
    {
        next;
    }
    if ( $Ob->{LON} < 0 ) { $Ob->{LON} += 360; }
    my $Cell_number = sprintf "%04d%04d%03d%03d",$Ob->{YR},
    Day_of_Year( $Ob->{YR}, $Ob->{MO}, $Ob->{DY} ),
    int($Ob->{LAT} + 90 ),int( $Ob->{LON} );
    if(defined($Grids{$Cell_number})) {
        $Ob->write(\*STDOUT);
    }
}

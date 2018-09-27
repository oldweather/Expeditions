#!/usr/bin/perl -w

# Find IMMA records in ICOADS that are in the Pacific

use strict;
use warnings;
use IMMA;

while ( my $Ob = imma_read( \*STDIN ) ) {
    unless ( defined( $Ob->{LAT} )
        && defined( $Ob->{LON} )
        && defined( $Ob->{YR} )
        && defined( $Ob->{MO} )
        && defined( $Ob->{DY} ) )
    {
        next;
    }
    if ( $Ob->{LON} < 0 ) { $Ob->{LON} += 360; }
    if ( $Ob->{LON} > 130 && $Ob->{LON} < 290 ) {
        $Ob->write( \*STDOUT );
    }
}

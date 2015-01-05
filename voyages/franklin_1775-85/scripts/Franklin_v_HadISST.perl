#!/usr/bin/perl

# Compare the Franklin SST values to the HadISST climatology

use strict;
use warnings;
use IMMA;

# Use the MDS functions to make normals for the data
use lib "$ENV{MDS2}/libraries/normals/source";
use Normals;
use lib "$ENV{MDS2}/libraries/pentads/source";
use Pentads;

# Retrieve normals data for AT and SST
my $SST_Normal = get_normals('SST');

while ( my $Ob = imma_read( \*STDIN ) ) {

    if (   defined( $Ob->{MO} )
        && defined( $Ob->{DY} )
        && defined( $Ob->{LON} )
        && defined( $Ob->{LAT} ) )
    {
        my $Pentad =
          pentad_from_date( sprintf( "%02d/%02d", $Ob->{MO}, $Ob->{DY} ) );
        my $Penday =
          penday_from_date( sprintf( "%02d/%02d", $Ob->{MO}, $Ob->{DY} ) );
        if ( defined( $Ob->{SST} ) ) {
            my $Nm =
              daily_normal( $SST_Normal, $Ob->{LON}, $Ob->{LAT}, $Pentad,
                $Penday );
            if ( defined($Nm) ) {
                printf "%04d/%02d/%02d:%02d %5.1f %5.1f\n", $Ob->{YR},
                  $Ob->{MO}, $Ob->{DY}, $Ob->{HR}, $Ob->{SST}, $Nm;
            }
        }
    }
}

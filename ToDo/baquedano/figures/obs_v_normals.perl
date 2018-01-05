#!/usr/bin/perl

# Compare ship speed,SLP, AT, and SST observations with
#   ice cover, NAT, SLP and and SST normals

use strict;
use warnings;
use IMMA;
use Normals2;
use Date::Calc qw(Delta_DHMS);
use lib "$ENV{MDS2}/libraries/pentads/source";
use Pentads;
use POSIX qw(acos);

my $ICE_normals = get_normals('ICE');
my $SST_normals = get_normals('SST');
my $NAT_normals = get_normals('DAT');
my $SLP_normals = get_normals('PRE');

my $last_ob;
while ( my $ob = imma_read( \*STDIN ) ) {
    if (   !defined($last_ob)
        || !defined( $last_ob->{YR} )
        || !defined( $ob->{YR} )
        || !defined( $last_ob->{MO} )
        || !defined( $ob->{MO} )
        || !defined( $last_ob->{DY} )
        || !defined( $ob->{DY} )
        || !defined( $last_ob->{HR} )
        || !defined( $ob->{HR} )
        || !defined( $last_ob->{LAT} )
        || !defined( $ob->{LAT} )
        || !defined( $last_ob->{LON} )
        || !defined( $ob->{LON} ) )
    {
        $last_ob = $ob;
        next;
    }

    my $dTime = Delta_Seconds( $last_ob, $ob );
    if ( $dTime > 86400 * 5 || $dTime < 1 ) {
        $last_ob = $ob;
        next;
    }
    my $dSpace = Delta_Meters( $ob, $last_ob );
    if ( $dSpace > 500000 ) {
        $last_ob = $ob;
        next;
    }
    my $Speed = $dSpace / $dTime;
    my $ob_pentad =
      pentad_from_date( sprintf "%02d/%02d", $ob->{MO}, $ob->{DY} );
    my $ob_penday =
      penday_from_date( sprintf "%02d/%02d", $ob->{MO}, $ob->{DY} );

    my $ice =
      daily_normal( $ICE_normals, $ob->{LON}, $ob->{LAT}, $ob_pentad,
        $ob_penday );

    printf "%04d/%02d/%02d %02d:00:00 %5.2f ", $ob->{YR}, $ob->{MO}, $ob->{DY},
      $ob->{HR}, $Speed;
    if ( defined($ice) ) {
        if ( $ice > 1 ) { $ice = 1; }
        if ( $ice < 0 ) { $ice = 0; }
        printf "%4.2f ", $ice;
    }
    else { print "  NA "; }

    if ( defined( $ob->{SST} ) ) { printf "%4.1f ", $ob->{SST}; }
    else                         { print "  NA "; }
    my $sst =
      daily_normal( $SST_normals, $ob->{LON}, $ob->{LAT}, $ob_pentad,
        $ob_penday );
    if ( defined($sst) ) { printf "%4.1f ", $sst; }
    else                 { print "  NA "; }

    if ( defined( $ob->{AT} ) ) { printf "%4.1f ", $ob->{AT}; }
    else                        { print "  NA "; }
    my $NAt =
      daily_normal( $NAT_normals, $ob->{LON}, $ob->{LAT}, $ob_pentad,
        $ob_penday );
    if ( defined($NAt) ) { printf "%4.1f ", $NAt; }
    else                 { print "  NA "; }

    if ( defined( $ob->{SLP} ) ) { printf "%6.1f ", $ob->{SLP}; }
    else                         { print "    NA "; }
    my $slp =
      daily_normal( $SLP_normals, $ob->{LON}, $ob->{LAT}, $ob_pentad,
        $ob_penday );
    if ( defined($slp) ) { printf "%6.1f ", $slp; }
    else                 { print "    NA "; }

    if ( defined( $ob->{LAT} ) ) { printf "%5.1f ", $ob->{LAT}; }
    else                         { print "   NA "; }
    if ( defined( $ob->{LON} ) ) { printf "%6.1f ", $ob->{LON}; }
    else                         { print "    NA "; }

    print "\n";

    $last_ob = $ob;

}

# Separation between 2 record locations in meters
# Sperical law of cosines,
#  see http://www.movable-type.co.uk/scripts/latlong.html
sub Delta_Meters {
    my $One = shift;
    my $Two = shift;
    my $ER  = 6371000;           # Earth's radius in m
    my $Rs  = 3.141592 / 180;    # Degrees->Radians scale factor
    my $d =
      acos(
        sin( $One->{LAT} * $Rs ) *
          sin( $Two->{LAT} * $Rs ) +
          cos( $One->{LAT} * $Rs ) *
          cos( $Two->{LAT} * $Rs ) *
          cos( $Two->{LON} * $Rs - $One->{LON} * $Rs ) ) *
      $ER;
    return $d;
}

# Difference between 2 record dates in seconds
sub Delta_Seconds {
    my $First = shift;
    my $Last  = shift;
    my ( $Dd, $Dh, $Dm, $Ds ) = Delta_DHMS(
        $First->{YR},
        $First->{MO},
        $First->{DY},
        int( $First->{HR} ),
        int( ( $First->{HR} - int( $First->{HR} ) ) * 60 ),
        0,
        $Last->{YR},
        $Last->{MO},
        $Last->{DY},
        int( $Last->{HR} ),
        int( ( $Last->{HR} - int( $Last->{HR} ) ) * 60 ),
        0
    );
    return $Dd * 86400 + $Dh * 3600 + $Dm * 60 + $Ds;
}

# Express the date as a real number of years - simplifies plotting
sub Year_Fraction {
    my $ob = shift;
    my ( $Dd, $Dh, $Dm, $Ds ) = Delta_DHMS(
        $ob->{YR}, $ob->{MO}, $ob->{DY},
        int( $ob->{HR} ),
        int( ( $ob->{HR} - int( $ob->{HR} ) ) * 60 ),
        0, $ob->{YR}, 1, 1, 0, 0, 0
    );
    my $Elapsed = $Dd * 86400 + $Dh * 3600 + $Dm * 60 + $Ds;
    ( $Dd, $Dh, $Dm, $Ds ) =
      Delta_DHMS( $ob->{YR}, 12, 31, 23, 59, 59, $ob->{YR}, 1, 1, 0, 0, 0 );
    my $Length = $Dd * 86400 + $Dh * 3600 + $Dm * 60 + $Ds;
    return $ob->{YR} + $Elapsed / $Length;
}


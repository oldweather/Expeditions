#!/usr/bin/perl

# Process the digitised First-Fleet data into
#  IMMA records.

use strict;
use warnings;
use IMMA;
use Getopt::Long;
use FindBin;
use Date::Calc qw(Delta_Days);
use MarineOb::lmrlib qw(rxltut ixdtnd rxnddt fxtftc fxeimb fwbptc fwbpgv);

my $Last_lon = -4;  
my $Last_lat = 50;

for ( my $i = 0 ; $i < 1 ; $i++ ) { <>; }    # Skip headers

while ( my $Line = <> ) {
    my @Fields = apply_qc( split /\t/, $Line );
    my $Ob = new IMMA;
    $Ob->clear();
    push @{ $Ob->{attachments} }, 0;

    # On the Sirius
    $Ob->{ID} = "Sirius";

    # Date
    if ( $Fields[0] =~ /(\d\d)\/(\d\d)\/(\d\d\d\d)/ ) {
        $Ob->{YR} = $3;
        $Ob->{MO} = $2;
        $Ob->{DY} = $1;
        $Ob->{HR} = 12;
    }
    else { die "Bad date format $Fields[0]"; }

    if ( defined( $Fields[1] ) && $Fields[1] =~ /\d/ ) {
        $Ob->{LAT} = $Fields[1];
    }
    if ( defined( $Fields[2] ) && $Fields[2] =~ /\d/ ) {
        $Ob->{LON} = $Fields[2];
    }
    if (   !defined( $Ob->{LAT} )
        && !defined( $Ob->{LON} )
        && defined( $Fields[5] ) )
    {
        ( $Ob->{LAT}, $Ob->{LON} ) = get_position_from_place( $Fields[5] );
    }
    if(defined($Ob->{LON})) {
        $Last_lon = $Ob->{LON};
    }
    if(defined($Ob->{LAT})) {
        $Last_lat = $Ob->{LAT};
    }
    
    # Convert dates to UTC
    if ( defined($Last_lon) ) {
        my $elon = $Last_lon;
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

    $Ob->{IM}   = 0;        # Check with Scott
    $Ob->{ATTC} = 1;        # Supplemental
    $Ob->{TI}   = 0;        # Nearest hour time precision
    $Ob->{DS}   = undef;    # Unknown course
    $Ob->{VS}   = undef;    # Unknown speed
    $Ob->{NID}  = 3;        # Check with Scott
    $Ob->{II}   = 10;       # Check with Scott

    # Air temperature in Farenheit
    if ( defined( $Fields[3] ) && $Fields[3] =~ /\d/ ) {
        $Ob->{AT} = fxtftc( $Fields[3]);
    }

    # Pressure in English inches
    if ( defined( $Fields[4] ) && $Fields[4] =~ /\d/ ) {
        $Ob->{SLP} = fxeimb( $Fields[4]);
    }

    # Barometer corrections deliberately omitted
    
    # Temperature correction
    #if (   defined( $Ob->{SLP} )
    #    && defined( $Ob->{AT} ) )
    #{
     #   $Ob->{SLP} += fwbptc( $Ob->{SLP}, $Ob->{AT} );
    #}
    #else { $Ob->{SLP} = undef; }

    # Gravity correction
    #if ( defined( $Ob->{SLP} ) && defined($Last_lat) ) {
    #    $Ob->{SLP} += fwbpgv( $Ob->{SLP}, $Last_lat, 2 );
    #}

    # Add the original record as a supplemental attachment
    push @{ $Ob->{attachments} }, 99;
    $Ob->{ATTE} = undef;
    chomp($Line);
    $Ob->{SUPD} = $Line;

    # Output the noon ob
    $Ob->write( \*STDOUT );

}

# Return (Lat,Long) given a place name
sub get_position_from_place {
    my $Name = lc(shift);
    if ( $Name =~ /teneriffe/ ) {
        return ( 28.47, -16.23 );
    }
    if ( $Name =~ /rio jameiro/ ) {
        return ( -22.8, -43.15 );
    }
    if ( $Name =~ /table bay/ ) {
        return ( -34.17, 18.44 );
    }
    warn "Unknown location $Name";
    return ( undef, undef );
}

# Correct some clearly erronious values
sub apply_qc {
    my @Fields = (@_);

    if ( $Fields[0] eq '19/05/1787' ) { $Fields[4] = 29.94; }
    if ( $Fields[0] eq '24/05/1787' ) { $Fields[1] = 44.15; }
    if ( $Fields[0] eq '25/09/1787' ) {
        $Fields[2] = -14.27;
        $Fields[4] = 29.93;
    }
    if ( $Fields[0] eq '19/10/1787' ) { $Fields[3] = 67; }
    if ( $Fields[0] eq '07/11/1787' ) { $Fields[4] = 29.9; }
    if ( $Fields[0] eq '21/11/1787' ) { $Fields[4] = 29.88; }
    if ( $Fields[0] eq '28/11/1787' ) {
        $Fields[3] = 62;
        $Fields[4] = 30.08;
    }
    if ( $Fields[0] eq '04/12/1787' ) { $Fields[4] = 29.88; }
    if ( $Fields[0] eq '15/12/1787' ) { $Fields[1] = -40.56; }
    return @Fields;
}

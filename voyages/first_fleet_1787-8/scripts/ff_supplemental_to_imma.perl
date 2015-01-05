#!/usr/bin/perl

# Process the extra digitised First-Fleet data into
#  IMMA records.
# Extra values from after arrival in Botany Bay

use strict;
use warnings;
use IMMA;
use Getopt::Long;
use FindBin;
use Date::Calc qw(Delta_Days);
use MarineOb::lmrlib qw(rxltut ixdtnd rxnddt fxtftc fxeimb fwbptc fwbpgv);

# Position of Port Jackson
my $Last_lat = -33.85;  
my $Last_lon = 151.23;

for ( my $i = 0 ; $i < 1 ; $i++ ) { <>; }    # Skip headers

while ( my $Line = <> ) {
    my @Fields = split /\t/, $Line;
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

        $Ob->{LAT} = $Last_lat;
        $Ob->{LON} = $Last_lon;
    
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
    if ( defined( $Fields[1] ) && $Fields[1] =~ /\d/ ) {
        $Ob->{AT} = fxtftc( $Fields[1]);
    }

    # Pressure in English inches
    if ( defined( $Fields[3] ) && $Fields[3] =~ /\d/ ) {
        $Ob->{SLP} = fxeimb( $Fields[3]);
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


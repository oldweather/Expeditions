#!/usr/bin/perl

# Process digitised logbook data from William Wales Resolution obs into
#  IMMA records. This set has Pressure 2 and Temperature 2.

use strict;
use warnings;
use IMMA;
use Getopt::Long;
use FindBin;
use MarineOb::lmrlib qw(rxltut ixdtnd fxeimb fwbpgv fxtftc rxnddt);

my $Ship_name = 'ResolutW2';
my ( $Year, $Month, $Day );
my $Last_lon;
my $Last_lat;
my $Lat_flag = 'N';
my $Lon_flag = 'W';

for ( my $i = 0 ; $i < 5 ; $i++ ) { <>; }    # Skip headers

while (<>) {
    my $Ob = new IMMA;
    $Ob->clear();                            # Why is this necessary?
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

        #        printf "%04d/%02d/%02d\n",$Year,$Month,$Day
    }
    $Ob->{YR} = $Year;
    $Ob->{MO} = $Month;
    $Ob->{DY} = $Day;

    # Noon obs
    $Ob->{HR} = 12;

    if ( defined( $Fields[3] )
        && $Fields[3] =~ /(\d+)\s+([\d\.]+)\s*([NS]*)/ )
    {
        $Ob->{LAT} = $1 + $2 / 60;
        if ( defined($3) && ( $3 eq 'N' || $3 eq 'S' ) ) { $Lat_flag = $3; }
        if ( $Lat_flag eq 'S' ) { $Ob->{LAT} *= -1; }
    }
    if ( defined( $Fields[4] )
        && $Fields[4] =~ /(\d+)\s+([\d.]+)\s*([EW]*)/ )
    {
        $Ob->{LON} = $1 + $2 / 60;
        if ( defined($3) && ( $3 eq 'E' || $3 eq 'W' ) ) { $Lon_flag = $3; }
        if ( $Lon_flag eq 'W' ) { $Ob->{LON} *= -1; }
        if($Ob->{LON}>180) {$Ob->{LON} -= 360;} 
    }
    if ( defined( $Ob->{LAT} ) || defined( $Ob->{LON} ) ) {
        $Ob->{LI} = 4;    # Deg+Min position precision
    }
    if ( defined( $Ob->{LON} ) ) { $Last_lon = $Ob->{LON}; }

    # Convert ob date and time to UTC
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

    # Pressure converted from inches
    if ( defined( $Fields[6] ) && $Fields[6] =~ /\d/ ) {
        $Ob->{SLP} = fxeimb( $Fields[6] );
    }

    # Gravity correction
    if ( defined( $Ob->{SLP} ) && defined($Last_lat) ) {
        $Ob->{SLP} += fwbpgv( $Ob->{SLP}, $Last_lat, 2 );
    }

    # Temperatures converted from F
    if ( defined( $Fields[8] ) && $Fields[8] =~ /\d/ ) {
        $Ob->{AT} = fxtftc( $Fields[8] );
    }

    # Fill in extra metadata
    $Ob->{IM}   = 0;            # Check with Scott
    $Ob->{ATTC} = 0;            # No attachments
    $Ob->{TI}   = 0;            # Nearest hour time precision
    $Ob->{DS}   = undef;        # Unknown course
    $Ob->{VS}   = undef;        # Unknown speed
    $Ob->{NID}  = undef;        # Check with Scott
    $Ob->{II}   = 10;           # Check with Scott
    $Ob->{ID}   = $Ship_name;
    $Ob->{C1}   = '03';         # UK
    if (   defined( $Ob->{AT} )
        || defined( $Ob->{WBT} )
        || defined( $Ob->{DPT} )
        || defined( $Ob->{SST} ) )
    {
        $Ob->{IT} = 4;          # Temps in degF and 10ths
    }

    $Ob->write( \*STDOUT );

}


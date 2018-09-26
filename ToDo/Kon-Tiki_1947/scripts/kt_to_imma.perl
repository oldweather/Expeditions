#!/usr/bin/perl

# Process digitised logbook data from the Kon-Tiki into
#  IMMA records.

use strict;
use warnings;
use MarineOb::IMMA;
use Date::Calc qw(Delta_Days);
use MarineOb::lmrlib qw(rxltut ixdtnd rxnddt fxmmmb fwbptc fwbpgv
                        fxtftc fxbfms ix32dd);

my $Ship_name = 'Kon-Tiki';
my ( $Year,     $Month,    $Day );
my ( $Last_lon, $Last_lat, $Last_T );
my $Lat_flag = 'N';
my $Lon_flag = 'W';
$Last_lon = -77.13;
$Last_lat = -12.03;

for ( my $i = 0 ; $i < 3 ; $i++ ) { <>; }    # Skip headers

while (<>) {
    my $Line = $_;
    my $Ob   = new MarineOb::IMMA;
    $Ob->clear();
    push @{ $Ob->{attachments} }, 0;
    my @Fields = split /,/, $_;

    if ( defined( $Fields[0] ) && $Fields[0] =~ /(\d\d)\/(\d\d)\/(\d\d\d\d)/ ) {
        $Year = $3;
        $Month = $2;
        $Day = $1;
    }
    $Ob->{YR} = $Year;
    $Ob->{MO} = $Month;
    $Ob->{DY} = $Day;

    if ( defined( $Fields[1] )) {
        if($Fields[1] eq 'Noon') { $Ob->{HR} = 12; }
        if($Fields[1] =~ /(\d\d):(\d\d)/) { $Ob->{HR} = $1+$2/60; }
        if ( $Ob->{HR} == 24 ) { $Ob->{HR} = 23.99; }
    }

    if ( defined( $Fields[8] ) && $Fields[8] =~ /(\d+)\.(\d+)/ ) {
        $Ob->{LAT} = ($1 + $2 / 60.0)*-1;
    }

    if ( defined( $Fields[9] ) && $Fields[9] =~ /(\d+)\.(\d+)/ ) {
        $Ob->{LON} = ($1 + $2 / 60.0)*-1;
        $Last_lon=$Ob->{LON};
    }

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

    if ( defined( $Fields[11] ) && $Fields[11] =~ /\d/ ) {
        $Ob->{AT} = fxtftc($Fields[11]);    # assumed F
    }
    if ( defined( $Fields[12] ) && $Fields[12] =~ /\d/ ) {
        $Ob->{SST} = fxtftc($Fields[12]);    # assumed F
    }
    if ( defined( $Fields[13] ) && $Fields[13] =~ /\w/ ) {
        $Fields[13] =~ s/\.//g; # strip dots
        $Fields[13] =~ s/\s//g; # strip spaces
      ( $Ob->{D}, undef ) = ix32dd(sprintf("%-4s",$Fields[13])); 
                                            # direction to degrees
    }
    if ( defined( $Fields[14] ) && $Fields[14] =~ /\d/ ) {
        $Ob->{W} = fxbfms($Fields[14]);      # Beaufort -> m/s
    }

    if ( defined( $Fields[10] ) && $Fields[10] =~ /\d/ ) {
        $Ob->{SLP} = $Fields[10];             # in hPa
    }
    if (   defined( $Ob->{SLP} )
         && defined( $Ob->{AT} ) ) {           # temperature correction
         $Ob->{SLP} += fwbptc( $Ob->{SLP}, $Ob->{AT} );
    }
    if ( defined( $Ob->{SLP} ) && defined($Last_lat) ) { # gravity correction
        $Ob->{SLP} += fwbpgv( $Ob->{SLP}, $Last_lat, 2 );
    }


    # Fill in extra metadata
    $Ob->{IM}   = 0;         # C
    $Ob->{ATTC} = 0;         # No attachments - may have supplemental, see below
    $Ob->{TI}   = 0;         # Nearest hour time precision
    $Ob->{DS}   = undef;     # Unknown course
    $Ob->{VS}   = undef;     # Unknown speed
    $Ob->{NID}  = 3;         #
    $Ob->{II}   = 10;        #
    $Ob->{ID}   = $Ship_name;
    $Ob->{C1}   = '04';      #
    if (   defined( $Ob->{AT} )
        || defined( $Ob->{WBT} )
        || defined( $Ob->{DPT} )
        || defined( $Ob->{SST} ) )
    {
        $Ob->{IT} = 4;                          # Temps in degF and 10ths
    }

    # Add the original record as a supplemental attachment
    if ( defined($Line) && $Line =~ /\S/ ) {
        chomp($Line);
        push @{ $Ob->{attachments} }, 99;
        $Ob->{ATTC}++;
        $Ob->{ATTE} = undef;
        $Ob->{SUPD} = $Line;
    }

    $Ob->write( \*STDOUT );

}


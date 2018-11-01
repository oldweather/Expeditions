#!/usr/bin/perl

# Process digitised logbook data from the Planet into
#  IMMA records.

use strict;
use warnings;
use MarineOb::IMMA;
use Date::Calc qw(Delta_Days);
use MarineOb::lmrlib qw(rxltut ixdtnd rxnddt fxmmmb fwbptc fwbpgv
                        fxtftc fxbfms ix32dd);

my $Ship_name = 'Planet';
my ( $Year,     $Month,    $Day , $Hour);
my ( $Last_lon, $Last_lat, $Last_T );
my $Lat_flag = 'N';
my $Lon_flag = 'E';
$Last_lon =  5.5;
$Last_lat = 53.67;

for ( my $i = 0 ; $i < 5 ; $i++ ) { <>; }    # Skip headers

while (<>) {
    my $Line = $_;
    my $Ob   = new MarineOb::IMMA;
    $Ob->clear();
    push @{ $Ob->{attachments} }, 0;
    my @Fields = split /\t/, $_;

    if ( defined( $Fields[0] ) && $Fields[0] =~ /(\d\d\d\d)/ ) {
        $Year = $1;
    }
    if ( defined( $Fields[1] ) && $Fields[1] =~ /(\d+)/ ) {
        $Month = $1;
    }
    if ( defined( $Fields[2] ) && $Fields[2] =~ /(\d+)/ ) {
        $Day = $1;
    }
    if ( defined( $Fields[3] ) && $Fields[3] =~ /(\d+)/ ) {
        $Hour = $1/100;
        if($Hour>23.99) { $Hour=23.99; } # Get midnight into previous day
    }
    $Ob->{YR} = $Year;
    $Ob->{MO} = $Month;
    $Ob->{DY} = $Day;
    $Ob->{HR} = $Hour;

    if ( defined( $Fields[4] )) {
        if($Fields[4] =~ /(\d+)\D+(\d+)/ ) {
	    $Ob->{LAT} = ($1 + $2 / 60.0);
	    if( $Fields[4] =~ /[sS]/ ) { $Lat_flag = 'S'; }
	    if( $Fields[4] =~ /[nN]/ ) { $Lat_flag = 'N'; }
	    if( $Lat_flag eq 'S') { $Ob->{LAT} = $Ob->{LAT}*-1; }
        } elsif($Fields[4] =~ /\w/) {
            ($Ob->{LAT},$Ob->{LON})=position_from_port($Fields[4]);
        }
        $Last_lat=$Ob->{LAT};
    }

    if ( defined( $Fields[5] ) && $Fields[5] =~ /(\d+)\D+(\d+)/ ) {
        $Ob->{LON} = ($1 + $2 / 60.0);
	if( $Fields[5] =~ /[wW]/ ) { $Lon_flag = 'W'; }
	if( $Fields[5] =~ /[eE]/ ) { $Lon_flag = 'E'; }
	if( $Lon_flag eq 'W') { $Ob->{LON} = $Ob->{LON}*-1; }
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

    if ( defined( $Fields[7] ) && $Fields[7] =~ /\d/ ) {
        $Ob->{AT} = $Fields[7];    # in C
    }
    if ( defined( $Fields[8] ) && $Fields[8] =~ /\d/ ) {
        $Ob->{SST} = $Fields[8];  
    }

    if ( defined( $Fields[6] ) && $Fields[6] =~ /\d/ ) {
        $Ob->{SLP} = fxmmmb($Fields[6]);  # in mm
    }

    # Better agreement with reanalysis assuming pressures are already corrected.

    #if (   defined( $Ob->{SLP} )
    #     && defined( $Ob->{AT} ) ) {           # temperature correction
    #     $Ob->{SLP} += fwbptc( $Ob->{SLP}, $Ob->{AT} );
    #}
    #if ( defined( $Ob->{SLP} ) && defined($Last_lat) ) { # gravity correction
    #    $Ob->{SLP} += fwbpgv( $Ob->{SLP}, $Last_lat, 2 );
    #}

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

# Get a position from a port name
sub position_from_port {
    my $Name = shift;
    if ( $Name =~ /Porto Grande/ ) {
        return ( 16.89, -25.01 );
    }
    if ( $Name =~ /Freetown/ ) {
        return ( 8.47, -13.23 );
    }
    if ( $Name =~ /Jamestown/ ) {
        return ( -15.93, -5.72 );
    }
    if ( $Name =~ /Durban/ ) {
        return ( -29.86, 31.02 );
    }
    if ( $Name =~ /Tamatave/ ) {
        return ( -18.14, 49.40 );
    }
    if ( $Name =~ /Port Louis/ ) {
        return ( -20.16, 57.50 );
    }
    if ( $Name =~ /Mathurin-Bucht/ ) {
        return ( -19.68, 63.42 );
    }
    if ( $Name =~ /Colombo/ ) {
        return ( 6.93, 79.86 );
    }
    if ( $Name =~ /Lugo-Bigo-Bucht/ ) {
        return ( undef, undef );
    }
    if ( $Name =~ /Padang/ ) {
        return ( -0.95, 100.42 );
    }
    if ( $Name =~ /Batavia/ ) {
        return ( -6.18, 106.83 );
    }
    if ( $Name =~ /Makassar/ ) {
        return ( -5.15, 119.43 );
    }
    if ( $Name =~ /Amboina/ ) {
        return ( -3.63, 128.11 );
    }
    if ( $Name =~ /Andrew-Hafen/ ) {
        return ( undef, undef );
    }
    if ( $Name =~ /Bird Isl/ ) {
        return ( undef, undef );
    }
    if ( $Name =~ /Herbertshohe/ ) {
        return ( -4.35, 152.27 );
    }
    if ( $Name =~ /Nusa-Hafen/ ) {
        return ( -2.58, 150.80 );
    }
    if ( $Name =~ /Yap/ ) {
        return ( 9.56, 138.14 );
    }
    if ( $Name =~ /Korror Hafen/ ) {
        return ( 7.34, 134.49 );
    }
    if ( $Name =~ /Manila/ ) {
        return ( 14.5, 120.8  );
    }
    if ( $Name =~ /Tathong Channel/ ) {
        return ( 22.25, 114.25 );
    }
    die "Unknown port $Name";
    #return ( undef, undef );
}

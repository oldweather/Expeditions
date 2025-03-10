#!/usr/bin/perl

# Process digitised logbook data from the Challenger into
#  IMMA records.

use strict;
use warnings;
use lib "/home/hc1300/hadpb/tasks/imma/perl_module";
use IMMA;
use Getopt::Long;
use FindBin;

my $Ship_name = 'Challengr';
my ( $Year, $Month, $Day );
my $Last_lon;
my $Lat_flag = 'N';
my $Lon_flag = 'E';

while (<>) {
    my $Ob = new IMMA;
    $Ob->clear();    # Why is this necessary?
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
    }
    $Ob->{YR} = $Year;
    $Ob->{MO} = $Month;
    $Ob->{DY} = $Day;
    if ( defined( $Fields[3] ) && $Fields[3] =~ /\d/ ) {
        $Ob->{HR} = $Fields[3] / 100;
    }
    correct_hour_for_lon($Ob);

    if ( defined( $Fields[4] ) && $Fields[4] =~ /[a-z]/ ) {    # Port name
        ( $Ob->{LAT}, $Ob->{LON} ) = position_from_port( $Fields[4] );
        $Ob->{LI} = 6;    # Position from metadata
    }
    else {
        if ( defined( $Fields[4] ) && $Fields[4] =~ /(\d+)\s+(\d+)\s*([NS]*)/ )
        {
            $Ob->{LAT} = $1 + $2 / 60;
            if ( defined($3) && ( $3 eq 'N' || $3 eq 'S' ) ) { $Lat_flag = $3; }
            if ( $Lat_flag eq 'S' ) { $Ob->{LAT} *= -1; }
        }
        if ( defined( $Fields[5] ) && $Fields[5] =~ /(\d+)\s+(\d+)\s*([EW]*)/ )
        {
            $Ob->{LON} = $1 + $2 / 60;
            if ( defined($3) && ( $3 eq 'E' || $3 eq 'W' ) ) { $Lon_flag = $3; }
            if ( $Lon_flag eq 'W' ) { $Ob->{LON} *= -1; }
        }
        if ( defined( $Ob->{LAT} ) || defined( $Ob->{LON} ) ) {
            $Ob->{LI} = 4;    # Deg+Min position precision
        }
    }
    if ( defined( $Ob->{LON} ) ) { $Last_lon = $Ob->{LON}; }

    # Pressure converted from inches
    if ( defined( $Fields[6] ) && $Fields[6] =~ /\d/ ) {
        $Ob->{SLP} = $Fields[6] * 33.86;
    }

    # Temperatures converted from Farenheit
    if ( defined( $Fields[7] ) && $Fields[7] =~ /\d/ ) {
        $Ob->{AT} = ( $Fields[7] - 32 ) * 5 / 9;
    }
    if ( defined( $Fields[8] ) && $Fields[8] =~ /\d/ ) {
        $Ob->{WBT} = ( $Fields[8] - 32 ) * 5 / 9;
    }
    if ( defined( $Fields[9] ) && $Fields[9] =~ /\d/ ) {
        $Ob->{SST} = ( $Fields[9] - 32 ) * 5 / 9;
    }

    # Fill in extra metadata
    $Ob->{IM}   = 0;            # Check with Scott
    $Ob->{ATTC} = 1;            # icoads
    $Ob->{TI}   = 0;            # Nearest hour time precision
    $Ob->{DS}   = undef;        # Unknown course
    $Ob->{VS}   = undef;        # Unknown speed
    $Ob->{NID}  = undef;            # Check with Scott
    $Ob->{II}   = 10;           # Check with Scott
    $Ob->{ID}   = $Ship_name;
    $Ob->{C1}   = '03';         # UK recruited
    if (   defined( $Ob->{AT} )
        || defined( $Ob->{WBT} )
        || defined( $Ob->{DPT} )
        || defined( $Ob->{SST} ) )
    {
        $Ob->{IT} = 4;          # Temps in degF and 10ths
    }

    # Add the icoads attachment
#    push @{ $Ob->{attachments} }, 1;
#    $Ob->{BSI} = undef;
#    $Ob->{B10} = undef;         # 10 degree box
#    $Ob->{B1}  = undef;         # 1 degree box
#    $Ob->{DCK} = 999;           # Deck ID - from Scott
#    $Ob->{SID} = 999;           # Source ID - from Scott
#    $Ob->{PT}  = 1;             # 'merchant ship or foreign military'
#    foreach my $Var (qw(DUPS DUPC TC PB WX SX C2)) {
#        $Ob->{$Var} = undef;
#    }

    # Other elements all missing
#    foreach my $Var ( @{ $IMMA::parameters[1] } ) {
#        unless ( exists( $Ob->{$Var} ) ) {
#            $Ob->{$Var} = undef;
#        }
#    }

    $Ob->write( \*STDOUT );

}

# Get a position from a port name
sub position_from_port {
    my $Name = lc(shift);
    if ( $Name =~ /sheerness/ ) {
        return ( 51.4, 0.8 );
    }
    if ( $Name =~ /dungeness/ ) {
        return ( 50.91, 0.98 );
    }
    if ( $Name =~ /beachy head/ ) {
        return ( 50.73, 0.25 );
    }
    if ( $Name =~ /downs/ ) {
        return ( undef, undef );
    }
    if ( $Name =~ /portsmouth/ ) {
        return ( 50.8, -1.1 );
    }
    if ( $Name =~ /spithead/ ) {
        return ( 50.8, -1.1, );
    }
    if ( $Name =~ /tagus/ ) {
        return ( undef, undef );
    }
    if ( $Name =~ /lisbon/ ) {
        return ( 38.7, -9.1 );
    }
    if ( $Name =~ /gibraltar/ ) {
        return ( 36.1, -5.3 );
    }
    if ( $Name =~ /madeira/ ) {
        return ( 32.6, -16.9 );    # Funchal bay
    }
    if ( $Name =~ /tenerife/ ) {
        return ( 28.5, -16.25 );    # Santa Cruz
    }
    if ( $Name =~ /santa cruz/ ) {
        return ( 28.5, -16.25 );
    }
    if ( $Name =~ /st thomas/ ) {
        return ( 18.33, -64.98 );
    }
    if ( $Name =~ /bermuda/ ) {
        return ( 32.3, -64.8 );
    }
    if ( $Name =~ /halifax/ ) {
        return ( 44.6, -63.6 );
    }
    if ( $Name =~ /fayal/ ) {
        return ( 38.55, -28.77 );
    }
    if ( $Name =~ /delgada/ ) {
        return ( 37.73, -25.66 );
    }
    if ( $Name =~ /funchal/ ) {
        return ( 32.6, -16.9 );
    }
    if ( $Name =~ /st vincent/ ) {
        return ( 16.8, -25.0 );
    }
    if ( $Name =~ /porto grande/ ) {
        return ( 16.8, -25.0 );
    }
    if ( $Name =~ /porto praya/ ) {
        return ( 14.9, -23.5 );
    }
    if ( $Name =~ /st paul's rocks/ ) {
        return ( 0.92, -29.37 );
    }
    if ( $Name =~ /san antonio bay/ ) {    # On Fernando Noronha
        return ( -3.85, -32.42 );
    }
    if ( $Name =~ /fernando noronha/ ) {
        return ( -3.85, -32.42 );
    }
    if ( $Name =~ /bahia/ ) {
        return ( -12.98, -38.51 );
    }
    if ( $Name =~ /tristan|inaccessible|nightingale/ ) {
        return ( -37.1, -12.3 );
    }
    if ( $Name =~ /simon's bay/ ) {
        return ( -34.2, 18.4 );
    }
    if ( $Name =~ /table bay/ ) {
        return ( -33.9, 18.4 );
    }
    if ( $Name =~ /kerguelen|bets[yt]|royal sound|island harbour/ ) {
        return ( -49.34, 70.2 );
    }
    if ( $Name =~ /greenland harbour|cascade beach|hopeful harbour/ ) {
        return ( -49.34, 70.2 );    # more Kerguelen
    }
    if (
        $Name =~ /fuller's harbour|christmas harbour|prince of wales foreland/ )
    {
        return ( -49.34, 70.2 );    # still more Kerguelen
    }
    if ( $Name =~ /heard island|corinthian bay/ ) {
        return ( -53.1, 73.7 );
    }
    if ( $Name =~ /melbourne|hobson|phillip/ ) {
        return ( -37.8, 145.0 );
    }
    if ( $Name =~ /sydney|jackson|farm cove|watson/ ) {
        return ( -33.9, 151.2 );
    }
    if ( $Name =~ /hardy/ ) {
        return ( undef, undef );
    }
    if ( $Name =~ /queen charlotte|ship cove/ ) {
        return ( -41.18, 174.19 );
    }
    if ( $Name =~ /nicholson/ ) {
        return ( -41.3, 174.83 );
    }
    if ( $Name =~ /wellington/ ) {
        return ( -41.3, 174.8 );
    }
    if ( $Name =~ /tongatabu/ ) {
        return ( -21.17, -175.17 );
    }
    if ( $Name =~ /ngaola|ngaloa/ ) {
        return ( -19.08, 178.18 );
    }
    if ( $Name =~ /levuka/ ) {
        return ( -18.13, 178.57 );
    }
    if ( $Name =~ /api island/ ) {    # Vanautu?
        return ( undef, undef );
    }
    if ( $Name =~ /raine island/ ) {
        return ( -11.6, 144.3 );
    }
    if ( $Name =~ /albany/ ) {
        return ( -10.73, 142.58 );
    }
    if ( $Name =~ /hammond/ ) {
        return ( -10.55, 142.18 );
    }
    if ( $Name =~ /dobbo/ ) {
        return ( undef, undef );
    }
    if ( $Name =~ /ki doulan/ ) {
        return ( undef, undef );
    }
    if ( $Name =~ /banda harbour/ ) {
        return ( undef, undef );
    }
    if ( $Name =~ /amboina/ ) {
        return ( -3.71, 128.2 );
    }
    if ( $Name =~ /ternate/ ) {
        return ( 0.77, 127.39 );
    }
#    if ( $Name =~ /samboangan/ ) {
#        return ( 9.88, 123.87 );
#    }
    if ( $Name =~ /samboangan/ ) { 
        return ( undef, undef );
    }
    if ( $Name =~ /ilo ilo/ ) {
        return ( 11.0, 122.67 );
    }
    if ( $Name =~ /manila/ ) {
        return ( 14.5, 120.8 );
    }
    if ( $Name =~ /hong kong/ ) {
        return ( 22.3, 114.2 );
    }
    if ( $Name =~ /zebu/ ) {
        return ( undef, undef );
    }
    if ( $Name =~ /malanipa/ ) {
        return ( 6.88, 122.27 );
    }
    if ( $Name =~ /port isabella/ ) {
        return ( undef, undef );
    }
    if ( $Name =~ /humboldt bay/ ) {
        return ( -2.58, 140.75 );
    }
    if ( $Name =~ /nares harbour/ ) { # Made-up. NW of Manus Island
        return ( -1.95, 147.18 );
    }
    if ( $Name =~ /yokohama/ ) {
        return ( 35.5, 139.7 );
    }
    if ( $Name =~ /yoi*koska/ ) {
        return ( 35.27, 139.67 );
    }
    if ( $Name =~ /kaneda/ ) {
        return ( 35.17, );
    }
    if ( $Name =~ /oosima/ ) {
        return ( undef, undef );
    }
    if ( $Name =~ /kobe/ ) {
        return ( 34.7, 135.1 );
    }
    if ( $Name =~ /sakate/ ) {
        return ( 34.45, 134.32 );
    }
    if ( $Name =~ /miwara/ ) {
        return ( 34.4, 132.83 );
    }
    if ( $Name =~ /honolulu/ ) {
        return ( 21.3, -157.9 );
    }
    if ( $Name =~ /hilo/ ) {
        return ( 19.72, -155.08 );
    }
    if ( $Name =~ /papiete|tahiti/ ) {
        return ( -17.52, -149.56 );
    }
    if ( $Name =~ /cumberland bay/ ) {
        return ( -33.62, -78.82 );
    }
    if ( $Name =~ /valparaiso/ ) {
        return ( -33.0, -71.6 );
    }
    if ( $Name =~ /hale cove/ ) {
        return ( -47.93, -74.62 );    # Orlebar Island
    }
    if ( $Name =~ /gr[ea]y harbour/ ) {
        return ( undef, undef );
    }
    if ( $Name =~ /port grappler/ ) {
        return ( -49.42, -74.32 );
    }
    if ( $Name =~ /tom bay/ ) {
        return ( undef, undef );
    }
    if ( $Name =~ /pu[oe]rto bueno/ ) {
        return ( -50.98, -74.22 );
    }
    if ( $Name =~ /isthmus harbour/ ) {
        return ( undef, undef );
    }
    if ( $Name =~ /port churruca/ ) {
        return ( undef, undef );
    }
    if ( $Name =~ /port famine/ ) {
        return ( -53.63, -70.93 );
    }
    if ( $Name =~ /sandy point/ ) {    # Punta Arenas
        return ( -53.1, -70.9 );
    }
    if ( $Name =~ /elizabeth island/ ) {    # Isla Isabel
        return ( -52.88, -70.70 );          # Doubtful, several possibilities
    }
    if ( $Name =~ /port stanley/ ) {
        return ( -51.7, -57.9 );
    }
    if ( $Name =~ /port louis/ ) {
        return ( -51.55, -58.13 );
    }
    if ( $Name =~ /monte video/ ) {
        return ( -34.9, -56.2 );
    }
    if ( $Name =~ /ascension/ ) {
        return ( -8.0, -14.4 );
    }
    if ( $Name =~ /vigo/ ) {
        return ( 43.57, -6.63 );
    }
    die "Unknown port $Name";
}

# Correct the date to UTC from local time
# This version not used here - kept in for historical reasons.
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

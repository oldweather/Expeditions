#!/usr/bin/perl

# Process digitised logbook data from the Investigator into
#  IMMA records.

use strict;
use warnings;
use IMMA;
use Getopt::Long;
use FindBin;
use Date::Calc qw(Delta_DHMS);

my $Ship_name = 'Investiga';
my ( $Year, $Month, $Day );
my $Last_lon;
my $Lat_flag = 'N';
my $Lon_flag = 'E';

for ( my $i = 0 ; $i < 8 ; $i++ ) { <>; }    # Skip headers

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
    if ( defined( $Fields[3] ) && $Fields[3] =~ /\d/ ) {
        $Ob->{HR} = int( $Fields[3] / 100 ) + ( $Fields[3] % 100 ) / 60;
    }

    if ( defined( $Fields[4] ) && $Fields[4] =~ /[a-z]/ ) {    # Port name
        ( $Ob->{LAT}, $Ob->{LON} ) = position_from_port( $Fields[4] );
        $Ob->{LI} = 6;    # Position from metadata
    }
    else {
        if ( defined( $Fields[4] )
            && $Fields[4] =~ /(\d+)\s+(\d+)\s*([NS]*)/ )
        {
            $Ob->{LAT} = $1 + $2 / 60;
            if ( defined($3) && ( $3 eq 'N' || $3 eq 'S' ) ) { $Lat_flag = $3; }
            if ( $Lat_flag eq 'S' ) { $Ob->{LAT} *= -1; }
        }
        if ( defined( $Fields[5] )
            && $Fields[5] =~ /(\d+)\s+(\d+)\s*([EW]*)/ )
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

    correct_hour_for_lon($Ob);

    # Fix a couple of points where Flinders was out in his longitude
    correctLongitude($Ob);

    # Pressure converted from inches
    if ( defined( $Fields[6] ) && $Fields[6] =~ /\d/ ) {
        $Ob->{SLP} = $Fields[6] * 33.86;
    }

    # Temperatures converted from Farenheit
    if ( defined( $Fields[7] ) && $Fields[7] =~ /\d/ ) {
        $Ob->{AT} = ( $Fields[7] - 32 ) * 5 / 9;
    }
    if ( defined( $Fields[8] ) && $Fields[8] =~ /\d/ ) {
        $Ob->{SST} = ( $Fields[8] - 32 ) * 5 / 9;
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

# Get a position from a port name
sub position_from_port {
    my $Name = lc(shift);
    if ( $Name =~ /spithead/ ) {
        return ( 50.8, -1.1, );
    }
    if ( $Name =~ /funchal/ ) {
        return ( 32.6, -16.9 );
    }
    if ( $Name =~ /false bay/ ) {
        return ( -34.22, 18.63 );
    }
    if ( $Name =~ /king georges sound/ ) {
        return ( -35.03, 117.95 );
    }
    if ( $Name =~ /princess royal harbour/ ) {
        return ( -35.0, 117.9 );
    }
    if ( $Name =~ /d.entrecasteaux archipelago/ ) {
        return ( undef, undef );

        # At ( -9.65, 150.7 ) - but Flinders used the name for somewhere else
    }
    if ( $Name =~ /memory cove/ ) {
        return ( -34.96, 135.99 );
    }
    if ( $Name =~ /kangaroo island/ ) {
        return ( -35.83, 137.33 );
    }
    if ( $Name =~ /westernport/ ) {
        return ( -38.33, 145.25 );
    }
    if ( $Name =~ /port jackson/ ) {
        return ( -33.9, 151.2 );
    }
    if ( $Name =~ /no. \d port/ ) {
        return ( undef, undef );
    }
    if ( $Name =~ /east coast/ ) {
        return ( undef, undef );
    }
    if ( $Name =~ /keppel bay/ ) {
        return ( -23.38, 150.88 );
    }
    if ( $Name =~ /shoal-water bay/ ) {
        return ( -22.17, 150.22 );
    }
    if ( $Name =~ /thirsty sound/ ) {
        return ( -22.27, 149.90 );
    }
    if ( $Name =~ /broad sound/ ) {
        return ( -22.17, 149.75 );
    }
    if ( $Name =~ /northern northumberland isles/ ) {
        return ( -21.0, 150.0 );
    }
    if ( $Name =~ /between a and b isles/ ) {    # What imaginative names.
        return ( undef, undef );
    }
    if ( $Name =~ /c vanderlin/ ) {
        return ( -15.58, 137 );
    }
    if ( $Name =~ /groote eyland/ ) {
        return ( -14.0, 136.67 );
    }
    if ( $Name =~ /arnhem/ ) {
        return ( -12.35, 136.97 );
    }
    if ( $Name =~ /coupang bay, timor/ ) {
        return ( undef, undef );
    }
    if ( $Name =~ /goose bay/ ) {
        return ( undef, undef );
    }

    die "Unknown port $Name";
    return ( undef, undef );
}

# Correct the date to UTC from local time
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

# Apply arbitrary corrections for longitude
sub correctLongitude {
    my $ob = shift;
    unless ( defined( $ob->{YR} )
        && defined( $ob->{MO} )
        && defined( $ob->{DY} )
        && defined( $ob->{HR} )
        && defined( $ob->{LON} ) )
    {
        return;
    }

    # Going into Sydney in 1803
    if (
        deltaS(
            "1803/06/01:00:00:00",
            sprintf(
                "%04d/%02d/%02d:%02d:%02d:%02d",
                $ob->{YR}, $ob->{MO}, $ob->{DY}, int( $ob->{HR} ),
                0, 0
            )
        ) > 0
        && deltaS(
            sprintf(
                "%04d/%02d/%02d:%02d:%02d:%02d",
                $ob->{YR}, $ob->{MO}, $ob->{DY}, int( $ob->{HR} ),
                0, 0
            ),
            "1803/06/09:22:00:00"
        ) >= 0
      )
    {
        $ob->{LON} += ( 151.2 - 149.29 ) * deltaS(
            "1803/06/01:00:00:00",
            sprintf(
                "%04d/%02d/%02d:%02d:%02d:%02d",
                $ob->{YR}, $ob->{MO}, $ob->{DY}, int( $ob->{HR} ),
                0, 0
            )
        ) / deltaS( "1803/06/01:00:00:00", "1803/06/09:22:00:00" );

    }

    # Going round Cape York peninsula in 1802
    if (
        deltaS(
            "1802/10/20:00:00:00",
            sprintf(
                "%04d/%02d/%02d:%02d:%02d:%02d",
                $ob->{YR}, $ob->{MO}, $ob->{DY}, int( $ob->{HR} ),
                0, 0
            )
        ) > 0
        && deltaS(
            sprintf(
                "%04d/%02d/%02d:%02d:%02d:%02d",
                $ob->{YR}, $ob->{MO}, $ob->{DY}, int( $ob->{HR} ),
                0, 0
            ),
            "1802/10/31:22:00:00"
        ) >= 0
      )
    {
        $ob->{LON} += ( 141.5 - 145.27 ) * deltaS(
            "1802/10/20:00:00:00",
            sprintf(
                "%04d/%02d/%02d:%02d:%02d:%02d",
                $ob->{YR}, $ob->{MO}, $ob->{DY}, int( $ob->{HR} ),
                0, 0
            )
        ) / deltaS( "1802/10/20:00:00:00", "1802/10/31:22:00:00" );

    }
    if (
        deltaS(
            "1802/10/31:22:00:00",
            sprintf(
                "%04d/%02d/%02d:%02d:%02d:%02d",
                $ob->{YR}, $ob->{MO}, $ob->{DY}, int( $ob->{HR} ),
                0, 0
            )
        ) > 0
        && deltaS(
            sprintf(
                "%04d/%02d/%02d:%02d:%02d:%02d",
                $ob->{YR}, $ob->{MO}, $ob->{DY}, int( $ob->{HR} ),
                0, 0
            ),
            "1802/11/30:22:00:00"
        ) >= 0
      )
    {
        my $Fraction = deltaS(
            "1802/10/31:22:00:00",
            sprintf(
                "%04d/%02d/%02d:%02d:%02d:%02d",
                $ob->{YR}, $ob->{MO}, $ob->{DY}, int( $ob->{HR} ),
                0, 0
            )
        ) / deltaS( "1802/10/31:22:00:00", "1802/11/30:22:00:00" );
        $ob->{LON} +=
          ( 140.0 - 142.33 ) * $Fraction +
          ( 141.5 - 145.27 ) * ( 1 - $Fraction );

    }

}

# Calculate difference in s between two dates
sub deltaS {
    my $D1 = shift;
    my $D2 = shift;
    unless ( $D1 =~ /(\d\d\d\d)\/(\d\d)\/(\d\d):(\d\d):(\d\d):(\d\d)/ ) {
        die "Bad date $D1";
    }
    my %Date1 = (
        year   => $1,
        month  => $2,
        day    => $3,
        hour   => $4,
        minute => $5,
        second => $6
    );
    unless ( $D2 =~ /(\d\d\d\d)\/(\d\d)\/(\d\d):(\d\d):(\d\d):(\d\d)/ ) {
        die "Bad date $D2";
    }
    my %Date2 = (
        year   => $1,
        month  => $2,
        day    => $3,
        hour   => $4,
        minute => $5,
        second => $6
    );
    my @Dhms = Delta_DHMS(
        $Date1{year},   $Date1{month},  $Date1{day},    $Date1{hour},
        $Date1{minute}, $Date1{second}, $Date2{year},   $Date2{month},
        $Date2{day},    $Date2{hour},   $Date2{minute}, $Date2{second}
    );
    return $Dhms[3] + $Dhms[2] * 60 + $Dhms[1] * 3600 + $Dhms[0] * 86400;
}

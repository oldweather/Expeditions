#!/usr/bin/perl

# Process digitised logbook data from the Vincennes into
#  IMMA records.

use strict;
use warnings;
use IMMA;
use Getopt::Long;
use FindBin;
use ObservationsCorrections;
use Date::Calc qw(Delta_Days);

my $Ship_name = 'Vincennes';
my ( $Year,     $Month,    $Day );
my ( $Last_lon, $Last_lat, $Last_T );
my $Lat_flag = 'N';
my $Lon_flag = 'W';
$Last_lat = 35.0;

for ( my $i = 0 ; $i < 8 ; $i++ ) { <>; }    # Skip headers

while (<>) {
    my $Ob = new IMMA;
    $Ob->clear();                            # Why is this necessary?
    push @{ $Ob->{attachments} }, 0;
    my @Fields = split /\t/, $_;

    unless ( defined( $Fields[3] ) && $Fields[3] =~ /\d/ ) {
        next;
    }                                        # Skip daily mean lines

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
    $Ob->{HR} = int( $Fields[3] / 100 ) + ( $Fields[3] % 100 ) / 60;

    # Parse lines differently at different points in the file

    my ( $Lat, $Long, $Bar, $Attached, $AT, $SST, $WindS, $WindD, $Remarks );
    if (   Delta_Days( $Year, $Month, $Day, 1838, 12, 7 ) <= 0
        && Delta_Days( $Year, $Month, $Day, 1839, 1, 3 ) >= 0 )
    {    # Enaxadous Island
        $Lat      = 'Enxados';
        $Long     = 'Island';
        $Bar      = $Fields[4];
        $Attached = $Fields[5];
        $AT       = $Fields[8];
        $SST      = $Fields[10];
        $WindD    = $Fields[15];
        $WindS    = $Fields[16];
        $Remarks  = $Fields[19];
    }
    elsif (Delta_Days( $Year, $Month, $Day, 1839, 3, 13 ) <= 0
        && Delta_Days( $Year, $Month, $Day, 1839, 4, 11 ) >= 0 )
    {    # Orange Harbour
        $Lat      = 'Orange';
        $Long     = 'Harbour';
        $Bar      = $Fields[4];
        $Attached = $Fields[5];
        $AT       = $Fields[8];
        $SST      = $Fields[10];
        $WindD    = $Fields[15];
        $WindS    = $Fields[16];
        $Remarks  = $Fields[19];
    }
    elsif (Delta_Days( $Year, $Month, $Day, 1839, 5, 19 ) <= 0
        && Delta_Days( $Year, $Month, $Day, 1839, 5, 31 ) >= 0 )
    {    # Valparaiso
        $Lat      = 'Valparaiso';
        $Long     = undef;
        $Bar      = $Fields[4];
        $Attached = $Fields[5];
        $AT       = $Fields[8];
        $SST      = $Fields[10];
        $WindD    = $Fields[15];
        $WindS    = $Fields[16];
        $Remarks  = $Fields[19];
    }
    elsif (Delta_Days( $Year, $Month, $Day, 1839, 6, 21 ) <= 0
        && Delta_Days( $Year, $Month, $Day, 1839, 7, 2 ) >= 0 )
    {    # San Lorenzo
        $Lat      = 'San Lorenzo';
        $Long     = undef;
        $Bar      = $Fields[4];
        $Attached = $Fields[5];
        $AT       = $Fields[8];
        $SST      = $Fields[10];
        $WindD    = $Fields[15];
        $WindS    = $Fields[16];
        $Remarks  = $Fields[19];
    }
    elsif (Delta_Days( $Year, $Month, $Day, 1839, 7, 31 ) <= 0
        && Delta_Days( $Year, $Month, $Day, 1839, 8, 29 ) >= 0 )
    {    # At sea, odd measurements
        $Lat      = $Fields[4];
        $Long     = $Fields[5];
        $Bar      = $Fields[11];
        $Attached = $Fields[6];
        $AT       = $Fields[6];
        $SST      = $Fields[7];
        $WindD    = $Fields[13];
        $WindS    = $Fields[14];
        $Remarks  = $Fields[17];
    }
    elsif (Delta_Days( $Year, $Month, $Day, 1839, 9, 1 ) <= 0
        && Delta_Days( $Year, $Month, $Day, 1839, 9, 8 ) >= 0 )
    {    # At sea, odd measurements
        $Lat      = $Fields[4];
        $Long     = $Fields[5];
        $Bar      = $Fields[11];
        $Attached = $Fields[6];
        $AT       = $Fields[6];
        $SST      = $Fields[7];
        $WindD    = $Fields[13];
        $WindS    = $Fields[14];
        $Remarks  = $Fields[17];
    }
    elsif (Delta_Days( $Year, $Month, $Day, 1839, 9, 12 ) <= 0
        && Delta_Days( $Year, $Month, $Day, 1839, 9, 18 ) >= 0 )
    {    # Tahiti
        $Lat      = $Fields[4];
        $Long     = $Fields[5];
        $Bar      = $Fields[6];
        $Attached = $Fields[7];
        $AT       = $Fields[8];
        $SST      = $Fields[14];
        $WindD    = $Fields[17];
        $WindS    = $Fields[18];
        $Remarks  = $Fields[21];
    }
    elsif (Delta_Days( $Year, $Month, $Day, 1839, 9, 29 ) <= 0
        && Delta_Days( $Year, $Month, $Day, 1839, 10, 8 ) >= 0 )
    {    # At sea, odd measurements
        $Lat      = $Fields[4];
        $Long     = $Fields[5];
        $Bar      = $Fields[11];
        $Attached = $Fields[6];
        $AT       = $Fields[6];
        $SST      = $Fields[7];
        $WindD    = $Fields[13];
        $WindS    = $Fields[14];
        $Remarks  = $Fields[17];
    }
    elsif (Delta_Days( $Year, $Month, $Day, 1839, 10, 13 ) <= 0
        && Delta_Days( $Year, $Month, $Day, 1839, 10, 23 ) >= 0 )
    {    # Tutuila
        $Lat      = $Fields[4];
        $Long     = $Fields[5];
        $Bar      = $Fields[6];
        $Attached = $Fields[7];
        $AT       = $Fields[11];
        $SST      = $Fields[13];
        $WindD    = $Fields[16];
        $WindS    = $Fields[17];
        $Remarks  = $Fields[20];
    }
    elsif (Delta_Days( $Year, $Month, $Day, 1839, 11, 3 ) <= 0
        && Delta_Days( $Year, $Month, $Day, 1839, 11, 8 ) >= 0 )
    {    # Apia
        $Lat      = $Fields[4];
        $Long     = $Fields[5];
        $Bar      = $Fields[6];
        $Attached = $Fields[7];
        $AT       = $Fields[11];
        $SST      = $Fields[12];
        $WindD    = $Fields[15];
        $WindS    = $Fields[16];
        $Remarks  = $Fields[19];
    }
    elsif (Delta_Days( $Year, $Month, $Day, 1839, 12, 5 ) <= 0
        && Delta_Days( $Year, $Month, $Day, 1839, 12, 23 ) >= 0 )
    {    # Sydney
        $Lat      = 'Sydney';
        $Long     = "";
        $Bar      = $Fields[4];
        $Attached = $Fields[5];
        $AT       = $Fields[9];
        $SST      = $Fields[10];
        $WindD    = $Fields[13];
        $WindS    = $Fields[14];
        $Remarks  = $Fields[17];
    }
    elsif (Delta_Days( $Year, $Month, $Day, 1840, 5, 18 ) <= 0
        && Delta_Days( $Year, $Month, $Day, 1840, 6, 25 ) >= 0 )
    {    # Ovoalu
        $Lat      = $Fields[4];
        $Long     = $Fields[5];
        $Bar      = $Fields[6];
        $Attached = $Fields[7];
        $AT       = $Fields[10];
        $SST      = $Fields[12];
        $WindD    = $Fields[15];
        $WindS    = $Fields[16];
        $Remarks  = $Fields[19];
    }
    elsif (Delta_Days( $Year, $Month, $Day, 1840, 10, 12 ) <= 0
        && Delta_Days( $Year, $Month, $Day, 1840, 11, 30 ) >= 0 )
    {    # Honolulu
        $Lat      = 'Honolulu';
        $Long     = '';
        $Bar      = $Fields[4];
        $Attached = $Fields[5];
        $AT       = $Fields[9];
        $SST      = $Fields[11];
        $WindD    = $Fields[14];
        $WindS    = $Fields[15];
        $Remarks  = $Fields[18];
    }
    elsif (Delta_Days( $Year, $Month, $Day, 1841, 1, 31 ) <= 0
        && Delta_Days( $Year, $Month, $Day, 1841, 2, 28 ) >= 0 )
    {    # Hilo Bay
        $Lat      = 'Hilo';
        $Long     = 'Bay';
        $Bar      = $Fields[4];
        $Attached = $Fields[5];
        $AT       = $Fields[8];
        $SST      = $Fields[9];
        $WindD    = $Fields[12];
        $WindS    = $Fields[13];
        $Remarks  = $Fields[16];
    }
    elsif (Delta_Days( $Year, $Month, $Day, 1841, 5, 21 ) <= 0
        && Delta_Days( $Year, $Month, $Day, 1841, 7, 15 ) >= 0 )
    {    # Fort Nisqually
        $Lat      = 'Fort';
        $Long     = 'Nisqually';
        $Bar      = $Fields[4];
        $Attached = $Fields[5];
        $AT       = $Fields[9];
        $SST      = $Fields[10];
        $WindD    = $Fields[13];
        $WindS    = $Fields[14];
        $Remarks  = $Fields[17];
    }
    elsif (Delta_Days( $Year, $Month, $Day, 1841, 8, 23 ) <= 0
        && Delta_Days( $Year, $Month, $Day, 1841, 10, 22 ) >= 0 )
    {    # Sausalito
        $Lat      = 'Sausalito';
        $Long     = '';
        $Bar      = $Fields[4];
        $Attached = $Fields[5];
        $AT       = $Fields[9];
        $SST      = $Fields[10];
        $WindD    = $Fields[13];
        $WindS    = $Fields[14];
        $Remarks  = $Fields[17];
    }
    elsif (Delta_Days( $Year, $Month, $Day, 1841, 7, 20 ) <= 0
        && Delta_Days( $Year, $Month, $Day, 1841, 7, 21 ) >= 0 )
    {    # Odd period in Puget sound
        $Lat      = $Fields[4];
        $Long     = $Fields[5];
        $Bar      = $Fields[8];
        $Attached = $Fields[6];
        $AT       = $Fields[6];
        $SST      = undef;
        $WindD    = $Fields[11];
        $WindS    = $Fields[12];
        $Remarks  = $Fields[15];
    }
    else {    # Standard at sea
        $Lat      = $Fields[4];
        $Long     = $Fields[5];
        $Bar      = $Fields[9];
        $Attached = $Fields[6];
        $AT       = $Fields[6];
        $SST      = $Fields[7];
        $WindD    = $Fields[11];
        $WindS    = $Fields[12];
        $Remarks  = $Fields[15];
    }

    # Set the position
    if ( defined($Lat) && $Lat =~ /[a-z]/ ) {    # Port name
        unless ( defined($Long) ) { $Long = ""; }
        ( $Ob->{LAT}, $Ob->{LON} ) = position_from_port( $Lat . " " . $Long );
        $Ob->{LI} = 6;                           # Position from metadata
    }
    else {
        if ( defined($Lat)
            && $Lat =~ /(\d+)[\s\.]+(\d+)\s*([NS]*)/ )
        {
            $Ob->{LAT} = $1 + $2 / 60;
            if ( defined($3) && ( $3 eq 'N' || $3 eq 'S' ) ) { $Lat_flag = $3; }
            if ( $Lat_flag eq 'S' ) { $Ob->{LAT} *= -1; }
        }
        if ( defined($Long)
            && $Long =~ /(\d+)[\s\.]+(\d+)\s*([EW]*)/ )
        {
            $Ob->{LON} = $1 + $2 / 60;
            if ( defined($3) && ( $3 eq 'E' || $3 eq 'W' ) ) { $Lon_flag = $3; }
            if ( $Lon_flag eq 'W' ) { $Ob->{LON} *= -1; }
        }
        if ( defined( $Ob->{LAT} ) || defined( $Ob->{LON} ) ) {
            $Ob->{LI} = 4;    # Deg+Min position precision
        }
        if ( defined($Long) && lc($Long) =~ /east/ ) { $Lon_flag = 'E'; }
        if ( defined($Long) && lc($Long) =~ /west/ ) { $Lon_flag = 'W'; }
    }
    if ( defined( $Ob->{LON} ) ) { $Last_lon = $Ob->{LON}; }
    if ( defined( $Ob->{LAT} ) ) { $Last_lat = $Ob->{LAT}; }

    # Set time to UTC
    correct_hour_for_lon($Ob);

    # Temperatures converted from Farenheit
    if ( defined($AT) && $AT =~ /\d/ ) {
        $Ob->{AT} = ( $AT - 32 ) * 5 / 9;
        $Last_T = $Ob->{AT};
    }
    if ( defined($SST) && $SST =~ /\d/ ) {
        $Ob->{SST} = ( $SST - 32 ) * 5 / 9;
    }

    # Pressure converted from inches
    if ( defined($Bar) && $Bar =~ /\d/ ) {
        $Ob->{SLP} = $Bar * 33.86;
        if ( !defined($Attached) || $Attached !~ /\d/ ) {
            $Attached = $Last_T;
        }
        else {
            $Attached = ( $Attached - 32 ) * 5 / 9;
        }
        $Ob->{SLP} =
          barometer_temperature_correction( $Ob->{SLP}, $Attached );
        $Ob->{SLP} = barometer_gravity_correction( $Ob->{SLP}, $Last_lat );
    }

    # Fill in extra metadata
    $Ob->{IM}   = 0;         # Check with Scott
    $Ob->{ATTC} = 0;         # No attachments - may have supplemental, see below
    $Ob->{TI}   = 0;         # Nearest hour time precision
    $Ob->{DS}   = undef;     # Unknown course
    $Ob->{VS}   = undef;     # Unknown speed
    $Ob->{NID}  = 3;         # Check with Scott
    $Ob->{II}   = 10;        # Check with Scott
    $Ob->{ID}   = $Ship_name;
    $Ob->{C1}   = '02';      # US recruited
    if (   defined( $Ob->{AT} )
        || defined( $Ob->{WBT} )
        || defined( $Ob->{DPT} )
        || defined( $Ob->{SST} ) )
    {
        $Ob->{IT} = 4;       # Temps in degF and 10ths
    }

    # Add the remarks as a supplemental attachment
    if ( defined($Remarks) && $Remarks =~ /\S/ ) {
        chomp($Remarks);
        push @{ $Ob->{attachments} }, 99;
        $Ob->{ATTC}++;
        $Ob->{ATTE} = undef;
        $Ob->{SUPD} = $Remarks;
    }

    $Ob->write( \*STDOUT );

}

# Get a position from a port name
sub position_from_port {
    my $Name = lc(shift);
    $Name =~ s/\s\s/ /g;
    if ( $Name =~ /funchal/ ) {
        return ( 32.6, -16.9 );
    }
    if ( $Name =~ /porto praya/ ) {
        return ( 14.9, -23.5 );
    }
    if ( $Name =~ /porto praya/ ) {
        return ( 14.9, -23.5 );
    }
    if ( $Name =~ /rio harbour|rio de janeiro/ ) {
        return ( -22.9, -43.13 );
    }
    if ( $Name =~ /enxados/ ) {    # Use Rio
        return ( -22.9, -43.13 );
    }
    if ( $Name =~ /raza island/ ) {
        return ( -23.06, -43.13 );
    }
    if ( $Name =~ /rio negro/ ) {    # Ambigious
        return ( undef, undef );
    }
    if ( $Name =~ /orange harbour/ ) {    # Somewhere in Tierra del Fuiego
        return ( -55.5, -68.5 );
    }
    if ( $Name =~ /scapenham bay/ ) {     # Somewhere in Tierra del Fuiego
        return ( -55.5, -68.5 );
    }
    if ( $Name =~ /valparaiso/ ) {
        return ( -33.0, -71.6 );
    }
    if ( $Name =~ /san lorenzo/ ) {
        return ( -12.08, -77.25 );
    }
    if ( $Name =~ /callao/ ) {
        return ( -12.07, -77.23 );
    }
    if ( $Name =~ /matavai bay|papawa cove/ ) {
        return ( undef, undef );
    }
    if ( $Name =~ /papiete|tahiti|papieti/ ) {
        return ( -17.52, -149.56 );
    }
    if ( $Name =~ /pago pago|tutuila/ ) {
        return ( -14.28, -170.7 );
    }
    if ( $Name =~ /sydney|jackson|farm cove|watson/ ) {
        return ( -33.9, 151.2 );
    }
    if ( $Name =~ /bay of islands|new zealand/ ) {
        return ( -36.28, 174.16 );
    }
    if ( $Name =~ /edoa/ )
    {    # Ship? no land anywhere near apparent position (south of Midway)
        return ( undef, undef );
    }
    if ( $Name =~ /tonga taboo/ ) {
        return ( -21.17, -175.17 );
    }
    if ( $Name =~ /ovolau/ ) {
        return ( -17.7, 178.8 );
    }
    if ( $Name =~ /direction island/ )
    {    # Not Keeling-Cocos or Bearing island - near Fiji
        return ( undef, undef );
    }
    if ( $Name =~ /mbua bay/ ) {
        return ( -16.82, 178.58 );
    }
    if ( $Name =~ /naloa|tavea/ ) {    # Fiji
        return ( undef, undef );
    }
    if ( $Name =~ /mali island/ ) {
        return ( -16.34, 179.35 );
    }
    if ( $Name =~ /apia harbour/ ) {
        return ( -13.83, -171.83 );
    }
    if ( $Name =~ /savu savu/ ) {
        return ( -16.75, 179.35 );
    }
    if ( $Name =~ /muthuata/ ) {
        return ( -16.5, 179.25 );
    }
    if ( $Name =~ /honolulu|sandwich/ ) {
        return ( 21.3, -157.9 );
    }
    if ( $Name =~ /hilo/ ) {
        return ( 19.72, -155.08 );
    }
    if ( $Name =~ /lahaina/ ) {
        return ( 20.89, -156.67 );
    }
    if ( $Name =~ /kahoolawe/ ) {
        return ( 20.55, -156.6 );
    }
    if ( $Name =~ /de fuca/ ) {
        return ( 48.3, -124.05 );
    }
    if ( $Name =~ /port discovery/ ) {
        return ( 48.42, -123.23 );
    }
    if ( $Name =~ /port townsend/ ) {
        return ( 48.12, -122.78 );
    }
    if ( $Name =~ /admiralty inlet/ ) {
        return ( 48.18, -122.73 );
    }
    if ( $Name =~ /port lawrence/ ) {
        return ( undef, undef );
    }
    if ( $Name =~ /pilot.s cove/ ) {
        return ( undef, undef );
    }
    if ( $Name =~ /appletree cove/ ) {
        return ( 47.79, -122.5 );
    }
    if ( $Name =~ /port madison/ ) {
        return ( 47.73, -122.53 );
    }
    if ( $Name =~ /nisqually/ ) {
        return ( 47.11, -122.64 );
    }
    if ( $Name =~ /puget sound/ ) {
        return ( 47.6, -122.45 );
    }
    if ( $Name =~ /new dungeness/ ) {
        return ( 48.18, -123.11 );
    }
    if ( $Name =~ /scarborough harbour/ ) {    # Not Yorkshire, Ontario or Maine
        return ( undef, undef );
    }
    if ( $Name =~ /off columbia/ ) {
        return ( 46.28, -124.05 );
    }
    if ( $Name =~ /san francisco/ ) {
        return ( 37.75, -122.6 );
    }
    if ( $Name =~ /yerba buena/ ) {
        return ( 37.81, -122.37 );
    }
    if ( $Name =~ /sausalito/ ) {
        return ( 37.86, -122.49 );
    }
    if ( $Name =~ /manil+a/ ) {
        return ( 14.58, 120.97 );
    }
    if ( $Name =~ /soung harbour/ ) {
        return ( undef, undef );
    }
    if ( $Name =~ /singapore/ ) {
        return ( 1.37, 103.8 );
    }
    if ( $Name =~ /straits of rhio and banca/ )
    {    # Between Sumatra (Riau) and Bangka island?
        return ( undef, undef );
    }
    if ( $Name =~ /straits of sunda/ ) {
        return ( -6, 105.8 );
    }
    if ( $Name =~ /table bay|cape of good hope/ ) {
        return ( -33.9, 18.4 );
    }
    if ( $Name =~ /st. helena|jamestown roads/ ) {
        return ( -15.92, -5.71 );
    }
    if ( $Name =~ /new york/ ) {
        return ( 40.66, -74.05 );
    }
    if ( $Name =~
        /at sea|sailed|went to sea|proceeded|anchored|underway|under way|^\s*harbour|^\s*river/
      )
    {
        return ( undef, undef );
    }
    die "Unknown port $Name";

    #return ( undef, undef );
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

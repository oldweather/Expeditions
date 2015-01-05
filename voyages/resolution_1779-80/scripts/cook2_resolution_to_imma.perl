#!/usr/bin/perl

# Process digitised logbook data from Cook's Resolution obs into
#  IMMA records. The records contain two thermometers, so these
#  IMMA records only keep the output of the second thermometer,
#  all the other data is in the other record

use strict;
use warnings;
use IMMA;
use Getopt::Long;
use FindBin;
use Date::Calc qw(Decode_Month);
use MarineOb::lmrlib
  qw(rxltut ixdtnd rxnddt fxeimb fwbpgv fxtftc ix32dd ixdcdd fxbfms);
use MarineOb::declination qw(magnetic_to_true);
use MarineOb::WindTerms qw(WordsToBeaufort);

my $Ship_name = 'Resoluti2';
my ( $Year, $Month, $Day, $Hour );
my $Last_lon;
my $Last_lat;
my $Lat_flag = 'N';
my $Lon_flag = 'E';
my $Last;    # Previous ob.

for ( my $i = 0 ; $i < 4 ; $i++ ) { <>; }    # Skip headers

while (<>) {

    my @Fields = split /\t/, $_;
    my $String = $_;

    if ( $_ =~ /^\s*(\d\d\d\d)\s+(...)/ ) {
        $Year  = $1;
        $Month = Decode_Month($2);
        if ( $Month == 0 ) { die "Bad month $2"; }
        next;
    }
    my $Ob = new IMMA;
    $Ob->clear();    # Why is this necessary?
    push @{ $Ob->{attachments} }, 0;

    if ( defined( $Fields[0] ) && $Fields[0] =~ /\d+/ ) {
        $Day  = $Fields[0];
        $Hour = 12;           # Noon by default
    }
    else { next; }

    $Ob->{YR} = $Year;
    $Ob->{MO} = $Month;
    $Ob->{DY} = $Day;
    $Ob->{HR} = $Hour;

    if ( defined( $Fields[6] ) && $Fields[6] =~ /[a-z]/ ) {    # Port name
        ( $Ob->{LAT}, $Ob->{LON} ) =
          position_from_port( $Fields[6] . $Fields[7] );
        $Ob->{LI} = 6;    # Position from metadata
    }
    else {
        if ( defined( $Fields[6] )
            && $Fields[6] =~ /(\d+)\s+([\d\.]+)\s*([NS]*)/ )
        {
            $Ob->{LAT} = $1 + $2 / 60;
            if ( defined($3) && ( $3 eq 'N' || $3 eq 'S' ) ) { $Lat_flag = $3; }
            if ( $Lat_flag eq 'S' ) { $Ob->{LAT} *= -1; }
        }
        if ( defined( $Fields[7] )
            && $Fields[7] =~ /(\d+)\s+([\d.]+)\s*([EW]*)/ )
        {
            $Ob->{LON} = $1 + $2 / 60;
            if ( defined($3) && ( $3 eq 'E' || $3 eq 'W' ) ) { $Lon_flag = $3; }
            if ( $Lon_flag eq 'W' ) { $Ob->{LON} *= -1; }
            if($Ob->{LON}>180) { $Ob->{LON} -= 360; }
        }
        if ( defined( $Ob->{LAT} ) || defined( $Ob->{LON} ) ) {
            $Ob->{LI} = 4;    # Deg+Min position precision
        }
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


    # Temperatures converted from F
    if ( defined( $Fields[5] ) && $Fields[5] =~ /\d/ ) {
        $Ob->{AT} = fxtftc( $Fields[5] );
    }

    # Fill in extra metadata
    $Ob->{IM}   = 0;
    $Ob->{ATTC} = 0;                            # No attachments
    $Ob->{TI}   = undef;                        # Unknown time precision
    $Ob->{DS}   = undef;                        # Unknown course
    $Ob->{VS}   = undef;                        # Unknown speed
    $Ob->{NID}  = undef;
    $Ob->{II}   = 10;
    $Ob->{ID}   = $Ship_name;
    $Ob->{C1}   = '03';                         # UK
    if (   defined( $Ob->{AT} )
        || defined( $Ob->{WBT} )
        || defined( $Ob->{DPT} )
        || defined( $Ob->{SST} ) )
    {
        $Ob->{IT} = 4;                          # Temps in degF and 10ths
    }

    # Add the original record
    chomp($String);
    $Ob->{ATTC}++;
    push @{ $Ob->{attachments} }, 99;
    $Ob->{ATTE} = undef;
    $Ob->{SUPD} = $String;

    $Last = $Ob;
    $Ob->write( \*STDOUT );

}

# Get a position from a port name
sub position_from_port {
    my $Name = lc(shift);
    if ( $Name =~ /st\s*peter|kamtfchatka/ ) {    # Petropavlosk
        return ( 53.05, 158.57, );
    }
    if ( $Name =~ /table\s*bay|in\s*the\s*bay/ ) {
        return ( -33.9, 18.45, );
    }
    if ( $Name =~ /adventure\s*bay/ ) {
        return ( -43.35, 147.33, );
    }
    if ( $Name =~ /charlotte\s*sound/ ) {
        return ( -41.24, 174.09, );
    }
    if ( $Name =~ /annamocka/ ) {
        return ( -20.23, -174.8, );
    }
    if ( $Name =~ /apie/ ) {
        return ( -19.7, -174.5, );
    }
    if ( $Name =~ /tongotaboo/ ) {
        return ( -21.1, -175.2, );
    }
    if ( $Name =~ /middleburgh/ ) {
        return ( undef, undef, );
    }
    if ( $Name =~ /oitiphea|Otaheite|matavi bay/ ) {    # Tahiti
        return ( -17.78, -149.34, );
    }
    if ( $Name =~ /emio|huaheine|ulietea|bolabola/ ) {    #
        return ( undef, undef, );
    }
    if ( $Name =~ /turtle/ ) {                            # not near Fiji
        return ( undef, undef, );
    }
    if ( $Name =~ /sandwich\s*i|oeyhee/ ) {               # Hawaii
        return ( 20, -156, );
    }
    if ( $Name =~ /king\s*george/ ) {    # Not in south Australia?
        return ( undef, undef, );
    }
    if ( $Name =~ /sandwich\s*sound/ ) {    # Prince William Sound
        return ( 60.81, -148.44, );
    }
    if ( $Name =~ /samgonooda/ ) {
        return ( undef, undef, );
    }
    if ( $Name =~ /keragegooa/ ) {          # Hawaii - Death of Cook
        return ( 19.47, -155.93, );
    }
    if ( $Name =~ /ohimea|atowooi/ ) {      # Hawaii somewhere
        return ( undef, undef, );
    }
    if ( $Name =~ /cape town/ ) {
        return ( -33.92, 17.37, );
    }
    if ( $Name =~ /macao/ ) {   
        return ( 22.24, 113.55, );
    }
    if ( $Name =~ /pulo\s*condore/ ) {   
        return ( 8.67, 106.62, );
    }
    if ( $Name =~ /falfe\s*bay/ ) { # false bay
        return ( -34.22, 18.63 );
    }
    if ( $Name =~ /strumnefs/ ) { # Orkney
        return ( 58.96, -3.29 );
    }

    die "Unknown port $Name";
    return ( undef, undef );
}

#!/usr/bin/perl

# Process digitised logbook data from La Perouse's Boussole obs into
#  IMMA records.

use strict;
use warnings;
use IMMA;
use Getopt::Long;
use FindBin;
use Date::Calc qw(Decode_Month);
use MarineOb::lmrlib
  qw(rxltut ixdtnd rxnddt fxfimb fwbpgv fxtftc ix32dd ixdcdd fxbfms fxtrtc);
use MarineOb::declination qw(magnetic_to_true);
use MarineOb::WindTerms qw(WordsToBeaufort);

my $Ship_name = 'Boussole';
my ( $Year, $Month, $Day, $Hour );
my $Last_lon;
my $Last_lat;
my $Lat_flag = 'N';
my $Lon_flag = 'W';
my $Last;    # previous ob
$Year  = 1785;
$Month = 8;

for ( my $i = 0 ; $i < 10 ; $i++ ) { <>; }    # Skip headers

while (<>) {
    my $String = $_;
    chomp($String);
    my @Fields = split /\t/, $_;
    if(scalar(@Fields)<4) { next; }
    if ( $Fields[0] =~ /\d/ ) { $Year  = $Fields[0]; }
    if ( $Fields[1] =~ /\d/ ) { $Month = $Fields[1]; }
    if ( $Fields[2] =~ /\d/ ) { $Day   = $Fields[2]; }
        if ( lc( $Fields[3] ) =~ /\d+.*n/ ) { $Lat_flag = 'N'; }
        if ( lc( $Fields[3] ) =~ /\d+.*s/ ) { $Lat_flag = 'S'; }
        if ( lc( $Fields[4] ) =~ /\d+.*w/ ) { $Lon_flag = 'W'; }
        if ( lc( $Fields[4] ) =~ /\d+.*e/ ) { $Lon_flag = 'E'; }

        my $Lat;
        if ( $Fields[3] =~ /(\d+)\s+(\d+)/ ) {
            $Lat = $1 + $2 / 60;
        }
        if ( $Fields[3] =~ /(\d+)\s+(\d+)\s+(\d+)/ ) {
            $Lat += $3 / 3600;
        }
        if ( defined($Lat) && $Lat_flag eq 'S' ) {
            $Lat *= -1;
        }
        if ( defined($Lat) ) { $Last_lat = $Lat; }

        my $Lon;
        if ( $Fields[4] =~ /(\d+)\s+(\d+)/ ) {
            $Lon = $1 + $2 / 60;
        }
        if ( $Fields[4] =~ /(\d+)\s+(\d+)\s+(\d+)/ ) {
            $Lon += $3 / 3600;
        }
        if ( defined($Lon) && $Lon_flag eq 'W' ) {
            $Lon *= -1;
        }
        if ( defined($Lon) ) {
            $Lon += 2.34;    # French
            if($Lon>180) { $Lon -= 360; }
            $Last_lon = $Lon;
        }
    

    my $Ob = new IMMA;
    $Ob->clear();
    push @{ $Ob->{attachments} }, 0;
    $Ob->{YR} = $Year;
    $Ob->{MO} = $Month;
    $Ob->{DY} = $Day;

    # Fill in extra metadata
    $Ob->{IM}   = 0;            #
    $Ob->{ATTC} = 0;            # No attachments
    $Ob->{TI}   = undef;        # Unknown time precision
    $Ob->{DS}   = undef;        # Unknown course
    $Ob->{VS}   = undef;        # Unknown speed
    $Ob->{NID}  = undef;        #
    $Ob->{II}   = 10;           #
    $Ob->{ID}   = 'Boussole';
    $Ob->{C1}   = '04';         # France

    # Noon position, temperature, and usually pressure
    #  Add the original record as supplement.

    $Ob->{HR} = 12;
    $Ob = toUTC($Ob);
    if ( defined($Lat) ) { $Ob->{LAT} = $Lat; }
    if ( defined($Lon) ) { $Ob->{LON} = $Lon; }
    if ( defined( $Fields[8] )
        && $Fields[8] =~ /(\d+)\s(\d+)\s(\d+)/ )
    {
        my $PInches = $1 + $2 / 12 + $3 / 144;

        # Convert from Paris inches and lines
        $Ob->{SLP} = fxfimb($PInches);

        # Gravity correction
        if ( defined( $Ob->{SLP} ) && defined($Last_lat) ) {
            $Ob->{SLP} += fwbpgv( $Ob->{SLP}, $Last_lat, 2 );
        }
    }
    if ( defined( $Fields[7] ) && $Fields[7] =~ /(\d+)/ ) {
        $Ob->{AT} = fxtrtc($Fields[7]); # Assumed Reamur 
    }
    $Ob->{ATTC}++;
    push @{ $Ob->{attachments} }, 99;
    $Ob->{ATTE} = undef;
    $Ob->{SUPD} = $String;
    $Ob->write( \*STDOUT );

}

# Convert ob date and time to UTC
sub toUTC {
    my $Ob = shift;
    if (   defined($Last_lon)
        && defined( $Ob->{HR} )
        && defined( $Ob->{DY} )
        && defined( $Ob->{MO} )
        && defined( $Ob->{YR} ) )
    {
        my $elon = $Last_lon;
        if ( $elon < 0 ) { $elon += 360; }
        if ( $elon > 359.98 ) { $elon = 359.98; }
        my ( $uhr, $udy ) = rxltut(
            $Ob->{HR} * 100,
            ixdtnd( $Ob->{DY}, $Ob->{MO}, $Ob->{YR} ),
            $elon * 100
        );
        $Ob->{HR} = $uhr / 100;
        ( $Ob->{DY}, $Ob->{MO}, $Ob->{YR} ) = rxnddt($udy);
    }
    else { $Ob->{HR} = undef; }
    return ($Ob);
}


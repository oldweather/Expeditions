#!/usr/bin/perl 

# Convert an IMMA file into KML - simple version

use strict;
use warnings;
use IMMA;
use Getopt::Long;
use Date::Calc qw(Delta_Days);

my $Title = "ICOADS 2.3 Observations";

# Group the IMMA data by ship and sort by date
my %Ships;
while ( my $Record = imma_read( \*STDIN ) ) {
    unless ( $Record =~ /\d/ ) { next; }    # Don't bother woith blank lines
    unless ( defined( $Record->{LAT} ) && defined( $Record->{LON} ) ) {
        next;
    }
    if ( defined( $Record->{ID} ) ) {
        push @{ $Ships{ $Record->{ID} } }, $Record;
    }
    else { push @{ $Ships{' '} }, $Record; }
}
for my $Ship ( keys %Ships ) {
    @{ $Ships{$Ship} } = sort by_date @{ $Ships{$Ship} };
}

# Output the KML file header
print "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n";
print "<kml xmlns=\"http://earth.google.com/kml/2.2\">\n";
print "  <Document>\n";
print "    <name>$Title</name>\n";
print "    <open>0</open>\n";

# All these icons will be green
my $HTML_base = "http://brohan.org/philip/kml";
print "<Style id=\"Ship\">\n";
print " <IconStyle>\n";
print "  <Icon>\n";
print "   <href>markers/green.png</href>\n";
print " </Icon>\n";
print " </IconStyle>\n";
print "</Style>\n";

#foreach my $Ship (sort { scalar(@{$Ships{$a}}) <=> scalar(@{$Ships{$b}}) } ( keys %Ships ));
foreach my $Ship ( sort ( keys %Ships ) ) {
    if ( $Ship eq ' ' ) { next; }    # Leave nameless ships until later
    makePlacemarks($Ship);
}
if ( defined( $Ships{' '} ) ) {
    makePlacemarks(' ');             # Nameless ships
}

# KML file footer
print "</Document>\n";
print "</kml>\n";

# Sort IMMA records by date
sub by_date {
    my $aYR = $a->{YR};
    unless ( defined($aYR) ) { $aYR = 0; }
    my $aMO = $a->{MO};
    unless ( defined($aMO) ) { $aMO = 0; }
    my $aDY = $a->{DY};
    unless ( defined($aDY) ) { $aDY = 0; }
    my $aHR = $a->{HR};
    unless ( defined($aHR) ) { $aHR = 0; }
    my $bYR = $b->{YR};
    unless ( defined($bYR) ) { $bYR = 0; }
    my $bMO = $b->{MO};
    unless ( defined($bMO) ) { $bMO = 0; }
    my $bDY = $b->{DY};
    unless ( defined($bDY) ) { $bDY = 0; }
    my $bHR = $b->{HR};
    unless ( defined($bHR) ) { $bHR = 0; }
    return $aYR <=> $bYR
      or $aMO <=> $bMO
      or $aDY <=> $bDY
      or $aHR <=> $bHR;
}

# Make the placemarks for a ship
sub makePlacemarks {
    my $Ship = shift;
    print "   <Folder>\n";
    print "     <name>$Ship</name>\n";
    print "     <visibility>0</visibility>\n";
    print "     <open>0</open>\n";

    # One placemark for each IMMA record with a position
    for ( my $i = 0 ; $i < scalar( @{ $Ships{$Ship} } ) ; $i++ ) {
        unless ( defined( $Ships{$Ship}[$i]->{LAT} )
            && defined( $Ships{$Ship}[$i]->{LON} ) )
        {
            next;
        }
        if ( $Ships{$Ship}[$i]->{LON} > 180 ) {
            $Ships{$Ship}[$i]->{LON} -= 360;
        }
        print "      <Placemark>\n";
        my $Style_name = "Ship";

        print "        <styleUrl>\#$Style_name</styleUrl>\n";
        print "        <Point>\n";
        print
          "          <coordinates>$Ships{$Ship}[$i]->{LON},$Ships{$Ship}[$i]->{LAT},0</coordinates>\n";
        print "        </Point>\n";
        my $Ts;

        if ( defined( $Ships{$Ship}[$i]->{YR} ) ) {
            $Ts = sprintf "%04d", $Ships{$Ship}[$i]->{YR};
            if ( defined( $Ships{$Ship}[$i]->{MO} ) ) {
                $Ts .= sprintf "-%02d", $Ships{$Ship}[$i]->{MO};
                if ( defined( $Ships{$Ship}[$i]->{DY} ) ) {
                    $Ts .= sprintf "-%02d", $Ships{$Ship}[$i]->{DY};
                    if ( defined( $Ships{$Ship}[$i]->{HR} ) ) {
                        $Ts .= sprintf "T%02d", int( $Ships{$Ship}[$i]->{HR} );
                        my $Minute =
                          ( $Ships{$Ship}[$i]->{HR} -
                              int( $Ships{$Ship}[$i]->{HR} ) ) * 60;
                        $Ts .= sprintf ":%02d", int($Minute);
                        my $Second = ( $Minute - int($Minute) );
                        $Ts .= sprintf ":%02dZ", $Second;
                    }
                }
            }
        }
        if ( defined($Ts) ) {
            print "        <TimeStamp>\n";
            print "          <when>$Ts</when>\n";
            print "        </TimeStamp>\n";
        }
        print "      </Placemark>\n";

    }
    print "   </Folder>\n";

}


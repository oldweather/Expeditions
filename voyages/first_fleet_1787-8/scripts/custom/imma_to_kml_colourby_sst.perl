#!/usr/bin/perl 

# Convert an IMMA file into KML

use strict;
use warnings;
use IMMA;
use Getopt::Long;
use Date::Calc qw(Delta_Days Add_Delta_Days Days_in_Month Day_of_Year);

my $Title = "IMMA data";
GetOptions( "title=s" => \$Title, );

# Time range for DAT
my %Start_date;
my %End_date;

# Group the IMMA data by ship and sort by date
my %Ships;
while ( my $Record = imma_read( \*STDIN ) ) {
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
    my $Record = $Ships{$Ship}[0];
    if (
        !defined( $Start_date{yr} )
        || Delta_Days(
            $Start_date{yr}, $Start_date{mo}, $Start_date{dy},
            $Record->{YR},   $Record->{MO},   $Record->{DY}
        ) < 0
      )
    {
        $Start_date{yr} = $Record->{YR};
        $Start_date{mo} = $Record->{MO};
        $Start_date{dy} = $Record->{DY};
    }
    $Record = $Ships{$Ship}[ $#{ $Ships{$Ship} } ];
    if (
        !defined( $End_date{yr} )
        || Delta_Days(
            $End_date{yr}, $End_date{mo}, $End_date{dy},
            $Record->{YR}, $Record->{MO}, $Record->{DY}
        ) > 0
      )
    {
        $End_date{yr} = $Record->{YR};
        $End_date{mo} = $Record->{MO};
        $End_date{dy} = $Record->{DY};
    }

}

# Output the KML file header
print "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n";
print "<kml xmlns=\"http://earth.google.com/kml/2.2\">\n";
print "  <Document>\n";
print "    <name>$Title</name>\n";
print "    <open>0</open>\n";

# Make styles for the placemarks - use the RB diverging icon colours
my $HTML_base = "markers";
for ( my $i = 1 ; $i <= 19 ; $i++ ) {
    my $Style_name = sprintf "Ship_%02d", $i;
    my $Icon_href = sprintf "%s/rb_diverging_%02d.png", $HTML_base, $i;
    print "<Style id=\"$Style_name\">\n";
    print " <IconStyle>\n";
    print "  <Icon>\n";
    print "   <href>$Icon_href</href>\n";
    print " </Icon>\n";
    print " </IconStyle>\n";
    print "</Style>\n";
}

# Add a default style for unnamed ships
print "<Style id=\"Ship_other\">\n";
print " <IconStyle>\n";
print "  <Icon>\n";
printf
  "   <href>%s/grey.png</href>\n", $HTML_base;
print " </Icon>\n";
print " </IconStyle>\n";
print "</Style>\n";

# Add a style for ship route lines
print "<Style id=\"Ship_route\">\n";
print "  <LineStyle>\n";
print "    <color>ff777777</color>\n";
print "    <width>2</width>\n";
print "  </LineStyle>\n";
print "</Style>\n";

# One folder per named ship

#foreach my $Ship (sort { scalar(@{$Ships{$a}}) <=> scalar(@{$Ships{$b}}) } ( keys %Ships ));
foreach my $Ship ( sort ( keys %Ships ) ) {
    if ( $Ship eq ' ' ) { next; }    # Leave nameless ships until later
    makePlacemarks($Ship);
}
if ( defined( $Ships{' '} ) ) {
    makePlacemarks(' ');             # Nameless ships
}

# Add the DAT
print "   <Folder>\n";
print "     <name>DAT</name>\n";
print "     <visibility>0</visibility>\n";
print "     <open>0</open>\n";
for ( my $yr = $Start_date{yr} ; $yr <= $End_date{yr} ; $yr++ ) {
    for ( my $p = 1 ; $p <= 73 ; $p++ ) {
        my @Dm = pentad_getdates($p);
        my ( $yr2, $mo2, $dy2 ) = Add_Delta_Days( $yr, $Dm[3], $Dm[2], 1 );
        if (
            $yr == $Start_date{yr}
            && ( $Dm[3] < $Start_date{mo}
                || ( $Dm[3] == $Start_date{mo} && $Dm[2] < $Start_date{dy} ) )
          )
        {
            next;
        }
        if (
            $yr == $End_date{yr}
            && ( $Dm[1] > $End_date{mo}
                || ( $Dm[1] == $End_date{mo} && $Dm[0] > $End_date{dy} ) )
          )
        {
            next;
        }

        print "   <GroundOverlay>\n";
        print "     <visibility>0</visibility>\n";
        print "     <open>0</open>\n";
        printf "      <name>%04d/%02d/%02d</name>\n", $yr, $Dm[1], $Dm[0];
        print "       <TimeSpan>\n";
        printf "         <begin>%04d-%02d-%02dT00:00Z</begin>\n", $yr, $Dm[1],
          $Dm[0];
        printf "         <end>%04d-%02d-%02dT00:01Z</end>\n", $yr2, $mo2, $dy2;
        print "       </TimeSpan>\n";
        print "      <Icon>\n";
        printf "      <href>images/DAT_%03d.png</href>\n", $p - 1;
        print "      </Icon>\n";
        print "      <LatLonBox>\n";
        print "        <north>50.0</north>\n";
        print "        <south>-50.0</south>\n";
        print "        <east>160</east>\n";
        print "        <west>-70</west>\n";
        print "        <rotation>0.0</rotation>\n";
        print "      </LatLonBox>\n";
        print "    </GroundOverlay>\n";
    }
}
print "   </Folder>\n";

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
        my $Style_name;
        if ( defined( $Ships{$Ship}[$i]->{AT} ) ) {
            my $iIndex = 18 * ( ( $Ships{$Ship}[$i]->{AT}) / 30 ) + 1;
            if ( $iIndex > 18 ) { $iIndex = 18; }
            if ( $iIndex < 1 )  { $iIndex = 1; }
            $Style_name = sprintf "Ship_%02d", $iIndex;
        }
        else {
            $Style_name = "Ship_other";
        }
        print "        <styleUrl>\#$Style_name</styleUrl>\n";
        print "        <description>\n";
        print makeDescription( $Ships{$Ship}[$i] );
        print "\n        </description>\n";
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

        # Add a route link if no discontinuity in position
        if (   $Ship ne ' '
            && $i > 0
            && areClose( $Ships{$Ship}[$i], $Ships{$Ship}[ $i - 1 ] ) )
        {
            print "      <Placemark>\n";
            print "        <styleUrl>\#Ship_route</styleUrl>\n";
            print "        <LineString>\n";
            print "          <coordinates>";
            my $Record = $Ships{$Ship}[ $i - 1 ];
            print "$Record->{LON},$Record->{LAT},0 ";
            $Record = $Ships{$Ship}[$i];
            print "$Record->{LON},$Record->{LAT},0";
            print "</coordinates>\n";
            print "        </LineString>\n";

            if ( defined($Ts) ) {
                print "        <TimeStamp>\n";
                print "          <when>$Ts</when>\n";
                print "        </TimeStamp>\n";
            }
            print "      </Placemark>\n";
        }
    }
    print "   </Folder>\n";

}

# Are two ships close enough to draw a route line linking their positions
sub areClose {
    return 1;
    my $First  = shift;
    my $Second = shift;
    unless ( defined( $First->{YR} )
        && defined( $Second->{YR} )
        && defined( $First->{MO} )
        && defined( $Second->{MO} )
        && defined( $First->{DY} )
        && defined( $Second->{DY} ) )
    {
        return;
    }

    #    my $deltaT = abs(
    #        Delta_Days(
    #            $First->{YR},  $First->{MO},  $First->{DY},
    #            $Second->{YR}, $Second->{MO}, $Second->{DY}
    #        )
    #    );
    #   if ( $deltaT > 2 ) { return; }
    if ( abs( $First->{LAT} - $Second->{LAT} ) > 5 ) { return; }
    my $Diff_lon = $First->{LON} - $Second->{LON};
    if ( abs($Diff_lon) > 5 ) {
        return;
    }

    return 1;
}

# Make the HTML to go in the description element for a placemark
# this is what appears in the pop-up window when the icon is
#  selected
sub makeDescription {
    my $Record      = shift;
    my $Attachment  = 0;
    my $Description = "<![CDATA[";
    $Description .= "<table cellpadding=3 bgcolor=grey>";
    for ( my $i = 0 ;
        $i < scalar( @{ $IMMA::parameters[$Attachment] } ) ; $i++ )
    {
        if ( $i % 4 == 0 ) { $Description .= "<tr>"; }

        #;. $IMMA::parameters[$Attachment][$i] . ":</td>";
        if ( defined( $Record->{ $IMMA::parameters[$Attachment][$i] } ) ) {
            $Description .= "<td bgcolor=lightgrey>";
            $Description .= sprintf "<pre>%-5s%10s</pre></td>",
              $IMMA::parameters[$Attachment][$i] . ":",
              $Record->{ $IMMA::parameters[$Attachment][$i] };
        }
        else {

#            $Description .= sprintf "<td bgcolor=grey align=\"right\">%10s</td>", "N/A";
            $Description .= "<td bgcolor=grey>";
            $Description .= sprintf "<pre>%-5s%10s</pre></td>",
              $IMMA::parameters[$Attachment][$i] . ":", "N/A";
        }
        if (   $i % 4 == 4
            || $i == scalar( @{ $IMMA::parameters[$Attachment] } ) - 1 )
        {
            $Description .= "</tr>";
        }
    }
    $Description .= "</table>";
    $Description .= "]]>";
    return $Description;
}

sub pentad_getdates {
    my @Ranges =
      qw(01/01-05/01 06/01-10/01 11/01-15/01 16/01-20/01 21/01-25/01 26/01-30/01
      31/01-04/02 05/02-09/02 10/02-14/02 15/02-19/02 20/02-24/02 25/02-01/03
      02/03-06/03 07/03-11/03 12/03-16/03 17/03-21/03 22/03-26/03 27/03-31/03
      01/04-05/04 06/04-10/04 11/04-15/04 16/04-20/04 21/04-25/04 26/04-30/04
      01/05-05/05 06/05-10/05 11/05-15/05 16/05-20/05 21/05-25/05 26/05-30/05
      31/05-04/06 05/06-09/06 10/06-14/06 15/06-19/06 20/06-24/06 25/06-29/06
      30/06-04/07 05/07-09/07 10/07-14/07 15/07-19/07 20/07-24/07 25/07-29/07
      30/07-03/08 04/08-08/08 09/08-13/08 14/08-18/08 19/08-23/08 24/08-28/08
      29/08-02/09 03/09-07/09 08/09-12/09 13/09-17/09 18/09-22/09 23/09-27/09
      28/09-02/10 03/10-07/10 08/10-12/10 13/10-17/10 18/10-22/10 23/10-27/10
      28/10-01/11 02/11-06/11 07/11-11/11 12/11-16/11 17/11-21/11 22/11-26/11
      27/11-01/12 02/12-06/12 07/12-11/12 12/12-16/12 17/12-21/12 22/12-26/12
      27/12-31/12);
    my $Pentad = shift;

    unless ( defined($Pentad) && $Pentad >= 1 && $Pentad <= 73 ) {
        die "Bad pentad";
    }
    $Ranges[ $Pentad - 1 ] =~ /(\d\d)\/(\d\d)\-(\d\d)\/(\d\d)/;
    return ( $1, $2, $3, $4 );
}

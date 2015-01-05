#!/usr/bin/perl 

# Convert an IMMA file into KML
# Options to colour icons, add SST, AT, wind speed or sea-ice fields
# Give the ship points a longer dwell time and use semi-transparent ice
#  To be viewed with a point time (not a range).

use strict;
use warnings;
use IMMA;
use Getopt::Long;
use Date::Calc
  qw(Delta_Days Add_Delta_Days Days_in_Month Day_of_Year check_date);

my $Title       = "IMMA data";
my $ColourBy    = 'ship';
my $Startcolour = 11;            # 0-11 - only used when colourby is ship
my $AddSST      = 0;
my $AddAT       = 0;
my $AddWS       = 0;
my $AddIce      = 0;
my $Lines        = 1;    # Link subsequent points for the same ship with a line?
my $Descriptions = 1;    # Add the core data as a description?
my $Min;                 # Value to ba associated with coldest colour
my $Max;                 # Value to be associated with warmest colour
GetOptions(
    "title=s"       => \$Title,
    "colourby=s"    => \$ColourBy,
    "startcolour=i" => \$Startcolour,
    "descriptions!" => \$Descriptions,
    "sst!"          => \$AddSST,
    "at!"           => \$AddAT,
    "ws!"           => \$AddWS,
    "ice!"          => \$AddIce,
    "lines!"        => \$Lines,
    "min"           => \$Min,
    "max"           => \$Max
) or die "Bad Options";

$ColourBy = lc($ColourBy);
if (   $ColourBy ne 'ship'
    && $ColourBy ne 'sst'
    && $ColourBy ne 'at'
    && $ColourBy ne 'ws' )
{
    die "--colourby must be one of: ship, sst, at and ws";
}
if ( $Startcolour < 0 || $Startcolour > 11 ) {
    die "--startcolour muyst be in the range 0-11";
}

# Time range
my %Start_date;
my %End_date;

# Style control variables
my %CatStyles;
my $NextColour = $Startcolour;

# Range of data for colouring
# Defaults are consistent with climatology images
unless ( defined($Min) ) {
    if ( $ColourBy eq 'sst' ) { $Min = -2; }
    if ( $ColourBy eq 'at' )  { $Min = -5; }
    if ( $ColourBy eq 'ws' )  { $Min = 0; }
}
unless ( defined($Max) ) {
    if ( $ColourBy eq 'sst' ) { $Max = 35; }
    if ( $ColourBy eq 'at' )  { $Max = 35; }
    if ( $ColourBy eq 'ws' )  { $Max = 15; }
}

# Group the IMMA data by ship and sort by date
my %Ships;
while ( my $Record = imma_read( \*STDIN ) ) {
    unless ( defined( $Record->{LAT} )
        && defined( $Record->{LON} )
        && defined( $Record->{YR} )
        && defined( $Record->{MO} )
        && defined( $Record->{DY} )
        && check_date( $Record->{YR}, $Record->{MO}, $Record->{DY} ) )
    {
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
        || !defined( $Record->{YR} )
        || !defined( $Record->{MO} )
        || !defined( $Record->{DY} )
        || !check_date( $Record->{YR}, $Record->{MO}, $Record->{DY} )
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

# Add the style information
addStyles();

# One folder per named ship
print " <Folder>\n";
print "   <name>Observations</name>\n";
print "   <visibility>1</visibility>\n";
print "   <open>0</open>\n";

foreach my $Ship ( sort ( keys %Ships ) ) {
    if ( $Ship eq ' ' ) { next; }    # Leave nameless ships until later
    makePlacemarks($Ship);
}
if ( defined( $Ships{' '} ) ) {
    makePlacemarks(' ');             # Nameless ships
}
print " </Folder>\n";

# Add the climatologies
if ( $AddSST || $AddAT || $AddWS || $AddIce ) {
    print " <Folder>\n";
    print "   <name>Climatologies</name>\n";
    print "   <visibility>0</visibility>\n";
    print "   <open>0</open>\n";
    if ($AddSST) { AddClimate('sst'); }
    if ($AddAT)  { AddClimate('at'); }
    if ($AddWS)  { AddClimate('ws'); }
    if ($AddIce) { AddClimate('ice'); }
    print " </Folder>\n";
}

# Close the KML file
print "</Document>\n";
print "</kml>\n";

# Add climatological background images
sub AddClimate {
    my $Var = shift;
    print "   <Folder>\n";
    my ( $Name, $Base_url );
    if ( $Var eq 'sst' ) {
        $Name = "Sea Temperature";
        $Base_url =
          "http://philip.brohan.org.kml.s3.amazonaws.com/climatology_images/images/sst_global_m2_to_35";
    }
    if ( $Var eq 'at' ) {
        $Name = "Air Temperature";
        $Base_url =
          "http://philip.brohan.org.kml.s3.amazonaws.com/climatology_images/images/nat_global_m5_to_35";
    }
    if ( $Var eq 'ws' ) {
        $Name = "Wind Speed";
        $Base_url =
          "http://philip.brohan.org.kml.s3.amazonaws.com/climatology_images/images/ws_global_0_to_15";
    }
    if ( $Var eq 'ice' ) {
        $Name = "Sea Ice";
        $Base_url =
          "http://philip.brohan.org.kml.s3.amazonaws.com/climatology_images/images/ice_global_st";
    }
    print "     <name>$Name</name>\n";
    print "     <visibility>0</visibility>\n";
    print "     <open>0</open>\n";
    for ( my $yr = $Start_date{yr} ; $yr <= $End_date{yr} ; $yr++ ) {
        for ( my $p = 1 ; $p <= 73 ; $p++ ) {
            my @Dm = pentad_getdates($p);
            my ( $yr2, $mo2, $dy2 ) = Add_Delta_Days( $yr, $Dm[3], $Dm[2], 1 );
            if (
                $yr == $Start_date{yr}
                && ( $Dm[3] < $Start_date{mo}
                    || ( $Dm[3] == $Start_date{mo} && $Dm[2] < $Start_date{dy} )
                )
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
            printf "         <begin>%04d-%02d-%02dT00:00Z</begin>\n", $yr,
              $Dm[1], $Dm[0];
            printf "         <end>%04d-%02d-%02dT00:01Z</end>\n", $yr2, $mo2,
              $dy2;
            print "       </TimeSpan>\n";
            print "      <Icon>\n";
            printf "      <href>$Base_url/%03d.png</href>\n", $p - 1;
            print "      </Icon>\n";
            print "      <LatLonBox>\n";
            print "        <north>90.0</north>\n";
            print "        <south>-90.0</south>\n";
            print "        <east>180</east>\n";
            print "        <west>-180</west>\n";
            print "        <rotation>0.0</rotation>\n";
            print "      </LatLonBox>\n";
            print "    </GroundOverlay>\n";
        }
    }
    print "   </Folder>\n";
}

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
        my $Style_name = getStyle( $Ships{$Ship}[$i] );
        print "        <styleUrl>\#$Style_name</styleUrl>\n";
        if ($Descriptions) {
            print "        <description>\n";
            print makeDescription( $Ships{$Ship}[$i] );
            print "\n        </description>\n";
        }
        print "        <Point>\n";
        print
          "          <coordinates>$Ships{$Ship}[$i]->{LON},$Ships{$Ship}[$i]->{LAT},0</coordinates>\n";
        print "        </Point>\n";
        print "       <TimeSpan>\n";
        printf "         <begin>%04d-%02d-%02dT00:00Z</begin>\n",
          Add_Delta_Days(
            $Ships{$Ship}[$i]->{YR},
            $Ships{$Ship}[$i]->{MO},
            $Ships{$Ship}[$i]->{DY}, -1
          );
        printf "         <end>%04d-%02d-%02dT00:01Z</end>\n",
          Add_Delta_Days(
            $Ships{$Ship}[$i]->{YR},
            $Ships{$Ship}[$i]->{MO},
            $Ships{$Ship}[$i]->{DY}, 1
          );
        print "       </TimeSpan>\n";
        print "      </Placemark>\n";

        # Add a route link if selected and less than 1 month apart
        if ( $Lines && $Ship ne ' ' && $i > 0 ) {
            if (
                   defined( $Ships{$Ship}[ $i - 1 ]->{YR} )
                && defined( $Ships{$Ship}[ $i - 1 ]->{MO} )
                && defined( $Ships{$Ship}[ $i - 1 ]->{DY} )
                && check_date(
                    $Ships{$Ship}[ $i - 1 ]->{YR},
                    $Ships{$Ship}[ $i - 1 ]->{MO},
                    $Ships{$Ship}[ $i - 1 ]->{DY}
                )
                && defined( $Ships{$Ship}[$i]->{YR} )
                && defined( $Ships{$Ship}[$i]->{MO} )
                && defined( $Ships{$Ship}[$i]->{DY} )
                && check_date(
                    $Ships{$Ship}[$i]->{YR}, $Ships{$Ship}[$i]->{MO},
                    $Ships{$Ship}[$i]->{DY}
                )
                && abs(
                    Delta_Days(
                        $Ships{$Ship}[ $i - 1 ]->{YR},
                        $Ships{$Ship}[ $i - 1 ]->{MO},
                        $Ships{$Ship}[ $i - 1 ]->{DY},
                        $Ships{$Ship}[$i]->{YR},
                        $Ships{$Ship}[$i]->{MO},
                        $Ships{$Ship}[$i]->{DY}
                    )
                ) < 30
              )
            {
                print "      <Placemark>\n";
                print "        <styleUrl>\#RouteLine</styleUrl>\n";
                print "        <LineString>\n";
                print "          <tessellate>1</tessellate>\n";
                print "          <coordinates>";
                my $Record = $Ships{$Ship}[ $i - 1 ];
                print "$Record->{LON},$Record->{LAT},0 ";
                $Record = $Ships{$Ship}[$i];
                print "$Record->{LON},$Record->{LAT},0";
                print "</coordinates>\n";
                print "        </LineString>\n";

                print "       <TimeSpan>\n";
                printf "         <begin>%04d-%02d-%02dT00:00Z</begin>\n",
                  Add_Delta_Days(
                    $Ships{$Ship}[$i]->{YR},
                    $Ships{$Ship}[$i]->{MO},
                    $Ships{$Ship}[$i]->{DY}, -1
                  );
                printf "         <end>%04d-%02d-%02dT00:01Z</end>\n",
                  Add_Delta_Days(
                    $Ships{$Ship}[$i]->{YR},
                    $Ships{$Ship}[$i]->{MO},
                    $Ships{$Ship}[$i]->{DY}, 1
                  );
                print "       </TimeSpan>\n";
                print "      </Placemark>\n";
            }
        }
    }
    print "   </Folder>\n";

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

# Make styles for the placemarks
sub addStyles {
    my $HTML_base = "http://philip.brohan.org.kml.s3.amazonaws.com/icons";

    # Default style for unnamed ships
    print "<Style id=\"Unstyled\">\n";
    print " <IconStyle>\n";
    print "  <Icon>\n";
    print "   <href>$HTML_base/base/grey_19px.png</href>\n";
    print " </Icon>\n";
    print " </IconStyle>\n";
    print " <BalloonStyle>\n";
    print " <text>\$[description]</text>\n";
    print " </BalloonStyle>\n";
    print "</Style>\n";

    # RGB diverging for colouring by temperature or speed
    for ( my $i = 0 ; $i <= 17 ; $i++ ) {
        my $Style_name = sprintf "RBD_%02d", $i;
        my $Icon_href = sprintf "%s/sets/blue_red_diverging_19px/%02d.png",
          $HTML_base, $i;
        print "<Style id=\"$Style_name\">\n";
        print " <IconStyle>\n";
        print "  <Icon>\n";
        print "   <href>$Icon_href</href>\n";
        print " </Icon>\n";
        print " </IconStyle>\n";
        print " <BalloonStyle>\n";
        print " <text>\$[description]</text>\n";
        print " </BalloonStyle>\n";
        print "</Style>\n";
    }

    # Categorical for colouring by ship
    for ( my $i = 0 ; $i <= 11 ; $i++ ) {
        my $Style_name = sprintf "Categorical_%02d", $i;
        my $Icon_href = sprintf "%s/sets/categorical_19px/%02d.png", $HTML_base,
          $i;
        print "<Style id=\"$Style_name\">\n";
        print " <IconStyle>\n";
        print "  <Icon>\n";
        print "   <href>$Icon_href</href>\n";
        print " </Icon>\n";
        print " </IconStyle>\n";
        print " <BalloonStyle>\n";
        print " <text>\$[description]</text>\n";
        print " </BalloonStyle>\n";
        print "</Style>\n";
    }

    # Polyline style for linking obs.
    print "<Style id=\"RouteLine\">\n";
    print " <LineStyle>\n";
    print "  <color>eeeeeeff</color>\n";
    print "  <width>1</width>\n";
    print " </LineStyle>\n";
    print "</Style>\n";
}

sub getStyle {
    my $Ob = shift;
    my $Style_name;
    if ( $ColourBy eq 'ship' ) {
        unless ( defined( $Ob->{ID} ) ) { return "Unstyled"; }
        if ( defined( $CatStyles{ $Ob->{ID} } ) ) {
            return sprintf "Categorical_%02d", $CatStyles{ $Ob->{ID} };
        }
        $CatStyles{ $Ob->{ID} } = $NextColour;
        $NextColour--;
        if ( $NextColour < 0 ) { $NextColour = 11; }
        return sprintf "Categorical_%02d", $CatStyles{ $Ob->{ID} };
    }
    my $Value;
    if ( $ColourBy eq 'sst' ) { $Value = $Ob->{SST}; }
    if ( $ColourBy eq 'at' )  { $Value = $Ob->{AT}; }
    if ( $ColourBy eq 'ws' )  { $Value = $Ob->{W}; }
    unless ( defined($Value) ) { return "Unstyled"; }
    my $Index = ( $Value - $Min ) / ( $Max - $Min );
    $Index = int( $Index * 18 + 0.5 );

    if ( $Index > 17 ) {
        $Index = 17;
    }
    if ( $Index < 0 ) { $Index = 0; }
    return sprintf "RBD_%02d", $Index;
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

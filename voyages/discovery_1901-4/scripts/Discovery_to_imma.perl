#!/usr/bin/perl

# Brocess digitised logbook data from The Discovery into
#  IMMA records.

use strict;
use warnings;
use lib "/home/hc1300/hadpb/tasks/digitisation/imma/";
use IMMA;
use Getopt::Long;
use FindBin;

my $Ship_name = 'Discovery';
my ( $Year, $Month, $Day );
my $isMorning = 1;

while (<>) {
    my @Fields = split /\t/, $_;
    unless ( $Fields[2] =~ /^\d+$/ ) {
        next;
    }    # Discard all coment and mean lines
    my $Ob = new IMMA;
    $Ob->clear();    # Why is this necessary?
    push @{ $Ob->{attachments} }, 0;

    # Position always fixed - frozen in the ice
    $Ob->{LAT} = -77.83;    # Set to position of Hut Point
    $Ob->{LON} = 166.38;
    $Ob->{LI}  = 6;         # Position from Metadata
                            # Get the date if available
    if ( defined( $Fields[0] ) && $Fields[0] =~ /(\d\d\d\d) (\d+)/ ) {
        $Year  = $1;
        $Month = $2;
    }
    elsif ( defined( $Fields[0] ) && $Fields[0] =~ /\d/ ) {
        $Year = $Fields[0];
    }
    if ( defined( $Fields[1] ) && $Fields[1] =~ /\d/ ) { $Day = $Fields[1]; }

    # Set the Date/Time fields and correct for Longitude
    my $Hour = $Fields[2];
    if ( $isMorning != 1 ) {    # afternoon
        if ( $Hour != 24 ) { $Hour += 12; }
        else { $isMorning = 1; }    # Morning henceforth
    }
    else {                          # Morning
        if ( $Hour == 12 ) { $isMorning = 0; }
    }
    $Ob->{YR} = $Year;
    $Ob->{MO} = $Month;
    $Ob->{DY} = $Day;
    $Ob->{HR} = $Hour;
    correct_hour_for_lon($Ob);

    # Pressure converted from inches
    if ( defined( $Fields[3] )
        && $Fields[3] =~ /\S/ )
    {
        my $Value = $Fields[3];
        $Value =~ s/[^\d+\-.]//g;
        if ( $Value =~ /\d/ ) {
            $Ob->{SLP} = $Value * 33.86;
        }
    }

    # Temperatures converted from Farenheit
    if ( defined( $Fields[6] )
        && $Fields[6] =~ /\S/ )
    {
        my $Value = $Fields[6];
        $Value =~ s/[^\d+\-.]//g;
        if ( $Value =~ /\d/ ) {
            $Ob->{AT} = ( $Value - 32 ) * 5 / 9;
        }
    }
    if ( defined( $Fields[7] )
        && $Fields[7] =~ /\S/ )
    {
        my $Value = $Fields[7];
        $Value =~ s/[^\d+\-.]//g;
        if ( $Value =~ /\d/ ) {
            $Ob->{WBT} = ( $Value - 32 ) * 5 / 9;
        }
    }

    # Winds converted from compass dir and Beaufort force
    if ( defined( $Fields[9] ) ) {
        my $Value = $Fields[9];
        $Value =~ s/"//g;
        if ( $Value =~ /\S/ ) {
            my $Compass;
            my $Beaufort;
            if ( $Value =~ /(.*),\s*(\d.*)/ ) {
                $Compass  = $1;
                $Beaufort = $2;
            }
            else {
                $Compass = $Value;
            }
            $Compass = lc($Compass);
            $Ob->{D} = compass_to_degrees($Compass);    # Wind direction
            if ( defined( $Ob->{D} ) ) {
                $Ob->{DI} = 1;    # Winds on 32 point compass
            }
            if ( defined($Beaufort) ) {    # Wind speed
                if ( $Beaufort =~ /(\d+)-(\d+)/ ) {  # range of Beaufort numbers
                    $Ob->{W} =
                      ( beaufort_to_mps($1) + beaufort_to_mps($2) ) / 2;
                }
                else {
                    $Ob->{W} = beaufort_to_mps($Beaufort);
                }
                if ( defined( $Ob->{W} ) ) {
                    $Ob->{WI} = 5;                   # Beaufort wind force
                }
            }
        }
    }

    # Fill in extra metadata
    $Ob->{IM}   = 0;             # Check with Scott
    $Ob->{ATTC} = 2;             # icoads and supplemental
    $Ob->{TI}   = 0;             # Nearest hour time precision
    $Ob->{DS}   = undef;         # Unknown course
    $Ob->{VS}   = 0;             # Frozen in
    $Ob->{NID}  = 3;             # Check with Scott
    $Ob->{II}   = 10;            # Check with Scott
    $Ob->{ID}   = 'Discovery';
    $Ob->{C1}   = '03';          # UK recruited
    if (   defined( $Ob->{AT} )
        || defined( $Ob->{WBT} )
        || defined( $Ob->{DPT} )
        || defined( $Ob->{SST} ) )
    {
        $Ob->{IT} = 4;           # Temps in degF and 10ths
    }

    # Add the icoads attachment
    push @{ $Ob->{attachments} }, 1;
    $Ob->{BSI} = undef;
    $Ob->{B10} = undef;          # 10 degree box
    $Ob->{B1}  = undef;          # 1 degree box
    $Ob->{DCK} = 246;            # Deck ID - from Scott
    $Ob->{SID} = 127;            # Source ID - from Scott
    $Ob->{PT}  = 9;              # 'ship overwintering in ice'
    foreach my $Var (qw(DUPS DUPC TC PB WX SX C2)) {
        $Ob->{$Var} = undef;
    }

    # Other elements all missing
    foreach my $Var ( @{ $IMMA::parameters[1] } ) {
        unless ( exists( $Ob->{$Var} ) ) {
            $Ob->{$Var} = undef;
        }
    }

    # Add the original data as a supplemental attachment
    push @{ $Ob->{attachments} }, 99;
    $Ob->{ATTE} = undef;
    $Ob->{SUPD} = "";

    # Year & Month
    if ( defined( $Fields[0] ) && $Fields[0] =~ /\S/ ) {
        $Ob->{SUPD} .= sprintf "%12s", $Fields[0];
    }
    else { $Ob->{SUPD} .= "            "; }

    # Day
    if ( defined( $Fields[1] ) && $Fields[1] =~ /\S/ ) {
        $Ob->{SUPD} .= sprintf " %2d", $Fields[1];
    }
    else { $Ob->{SUPD} .= "   "; }

    # Hour
    if ( defined( $Fields[2] ) && $Fields[2] =~ /\S/ ) {
        $Ob->{SUPD} .= sprintf " %2d", $Fields[2];
    }
    else { $Ob->{SUPD} .= "   "; }

    # Pressure
    if ( defined( $Fields[3] ) && $Fields[3] =~ /\S/ ) {
        $Ob->{SUPD} .= sprintf " %6s", $Fields[3];
    }
    else { $Ob->{SUPD} .= "       "; }

    # Cape Armitage
    if ( defined( $Fields[4] ) && $Fields[4] =~ /\S/ ) {
        $Ob->{SUPD} .= sprintf " %5s", $Fields[4];
    }
    else { $Ob->{SUPD} .= "      "; }

    # Temperatures
    if ( defined( $Fields[5] ) && $Fields[5] =~ /\S/ ) {
        $Ob->{SUPD} .= sprintf " %5s", $Fields[5];
    }
    else { $Ob->{SUPD} .= "      "; }
    if ( defined( $Fields[6] ) && $Fields[6] =~ /\S/ ) {
        $Ob->{SUPD} .= sprintf " %5s", $Fields[6];
    }
    else { $Ob->{SUPD} .= "      "; }
    if ( defined( $Fields[7] ) && $Fields[7] =~ /\S/ ) {
        $Ob->{SUPD} .= sprintf " %5s", $Fields[7];
    }
    else { $Ob->{SUPD} .= "      "; }
    if ( defined( $Fields[8] ) && $Fields[8] =~ /\S/ ) {
        $Ob->{SUPD} .= sprintf " %4s", $Fields[8];
    }
    else { $Ob->{SUPD} .= "      "; }

    # Wind force and direction
    if ( defined( $Fields[9] ) && $Fields[9] =~ /\S/ ) {
        $Ob->{SUPD} .= sprintf " %-13s", $Fields[9];
    }
    else { $Ob->{SUPD} .= "              "; }

    # Annemometer
    if ( defined( $Fields[10] ) && $Fields[10] =~ /\S/ ) {
        $Ob->{SUPD} .= sprintf " %3s", $Fields[10];
    }
    else { $Ob->{SUPD} .= "    "; }

    # P. Tube
    if ( defined( $Fields[11] ) && $Fields[11] =~ /\S/ ) {
        $Ob->{SUPD} .= sprintf " %5s", $Fields[11];
    }
    else { $Ob->{SUPD} .= "      "; }

    # Weather
    if ( defined( $Fields[12] ) && $Fields[12] =~ /\S/ ) {
        $Ob->{SUPD} .= sprintf " %-35s", $Fields[12];
    }
    else { $Ob->{SUPD} .= "                                    "; }

    # Sunshine field is always blank
    # Clouds Upper
    if ( defined( $Fields[14] ) && $Fields[14] =~ /\S/ ) {
        $Ob->{SUPD} .= sprintf " %-26s", $Fields[14];
    }
    else { $Ob->{SUPD} .= "                           "; }

    # Clouds Lower
    if ( defined( $Fields[15] ) && $Fields[15] =~ /\S/ ) {
        $Ob->{SUPD} .= sprintf " %-26s", $Fields[15];
    }
    else { $Ob->{SUPD} .= "                           "; }

    # Aspirator is always blank
    # Remarks
    $Fields[17] =~ s/\n//g;
    if ( defined( $Fields[17] ) ) { $Ob->{SUPD} .= " " . $Fields[17]; }

    # Output the IMMA ob
    $Ob->write( \*STDOUT );
}

# Bonvert Beaufort force to speed im m/a
sub beaufort_to_mps {
    my $Beau = shift;
    unless ( defined($Beau) && $Beau =~ /\d/ && $Beau >= 0 && $Beau <= 12 ) {
        return;
    }
    return (qw(0 0.8 2.4 4.3 6.7 9.3 12.3 15.5 18.9 22.6 26.4 30.5 32.7))
      [$Beau];
}

# Convert 32-point compass direction to direction in degrees
sub compass_to_degrees {
    my $Dir_c = shift;
    $Dir_c =~ s/\s+//g;
    if ( lc($Dir_c) =~ /^c/ ) { $Dir_c = 'c'; }
    if ( lc($Dir_c) =~ /^v/ ) { $Dir_c = 'v'; }
    my %Directions = (
        n    => 360,
        nxe  => 11,
        nne  => 23,
        nexn => 34,
        ne   => 45,
        nexe => 57,
        ene  => 68,
        exn  => 79,
        e    => 90,
        exs  => 102,
        ese  => 113,
        sexe => 124,
        se   => 135,
        sexs => 147,
        sse  => 158,
        sxe  => 169,
        s    => 180,
        sxw  => 192,
        ssw  => 203,
        swxs => 214,
        sw   => 225,
        swxw => 237,
        wsw  => 248,
        wxs  => 259,
        w    => 270,
        wxn  => 282,
        wnw  => 293,
        nwxw => 304,
        nw   => 315,
        nwxn => 326,
        nnw  => 337,
        nxw  => 349,
        c    => 361,    # Calm
        v    => 362     # Variable
    );
    unless ( defined($Dir_c) ) { return undef; }
    $Dir_c =~ s/\W//g;
    if ( exists( $Directions{ lc($Dir_c) } ) ) {
        return $Directions{ lc($Dir_c) };
    }
    else {
        return undef;
    }
}

# Correct the date to UTC from local time
sub correct_hour_for_lon {
    my @Days_in_month = ( 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31 );
    my $Ob            = shift;
    unless ( defined( $Ob->{LON} )
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
    $Ob->{HR} += $Ob->{LON} * 12 / 180;
    if ( $Ob->{HR} < 0 ) {
        $Ob->{HR} += 24;
        $Ob->{DY}--;
        if ( $Ob->{DY} < 0 ) {
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
    return 1;
}

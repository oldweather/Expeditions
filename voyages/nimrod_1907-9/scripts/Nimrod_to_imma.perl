#!/usr/bin/perl

# Brocess digitised logbook data from The Nimrod into
#  IMMA records.

use strict;
use warnings;
use lib "/home/hc1300/hadpb/tasks/imma/perl_module";
use IMMA;
use Getopt::Long;
use FindBin;

my $Ship_name = 'Nimrod';
my ( $Year, $Month, $Day );
my $Last_lon;

while (<>) {
    if ( $_ =~ /January, (\d\d\d\d)/ ) {    # Deal explicitly with the dates
        $Year  = $1;
        $Month = 1;
    }
    elsif ( $_ =~ /February, (\d\d\d\d)/ ) {
        $Year  = $1;
        $Month = 2;
    }
    elsif ( $_ =~ /March, (\d\d\d\d)/ ) {
        $Year  = $1;
        $Month = 3;
    }
    elsif ( $_ =~ /December, (\d\d\d\d)/ ) {
        $Year  = $1;
        $Month = 12;
    }
    elsif ( $_ =~ /^\s*\d/ ) {    # Data line
        my $Ob = new IMMA;
        $Ob->clear();             # Why is this necessary?
        push @{ $Ob->{attachments} }, 0;
        my @Fields = split /\t/, $_;
        if ( defined( $Fields[0] ) && $Fields[0] =~ /\d/ ) {
            $Day = $Fields[0];
        }
        if ( $Fields[8] =~
            /(\d+)° *(\d+)['.] *([NS])[., ]+([\d]+)° *(\d+)['.] *([EW])/ )
        {
            $Ob->{LAT} = $1;
            $Ob->{LAT} += $2 / 60;
            if ( uc($3) eq 'S' ) { $Ob->{LAT} *= -1; }
            $Ob->{LON} = $4;
            $Ob->{LON} += $5 / 60;
            if ( uc($6) eq 'W' ) { $Ob->{LON} *= -1; }
            $Last_lon = $Ob->{LON};
            $Ob->{LI} = 4;    # Deg+Min position precision
        }
        elsif (
            lc( $Fields[8] ) =~
            /cape royds|hut point|mcmurdo sound|glacier tongue/ )
        {
            $Ob->{LAT} = -77.55;    # Set to position of Cape Royds
            $Ob->{LON} = 166.15;
            $Ob->{LI}  = 6;         # Position from MetaData
        }
        elsif ( $Fields[1] == 12 ) {
            warn "No noon ob for $Year $Month $Day";
        }
        $Ob->{YR} = $Year;
        $Ob->{MO} = $Month;
        $Ob->{DY} = $Day;
        if ( defined( $Fields[1] ) && $Fields[1] =~ /\d/ ) {
            $Ob->{HR} = $Fields[1];
        }
        correct_hour_for_lon_ndl($Ob);

        # Pressure converted from inches
        if ( defined( $Fields[2] ) && $Fields[2] =~ /\d/ ) {
            $Ob->{SLP} = $Fields[2] * 33.86;
        }

        # Temperatures converted from Farenheit
        if ( defined( $Fields[3] ) && $Fields[3] =~ /\d/ ) {
            $Ob->{AT} = ( $Fields[3] - 32 ) * 5 / 9;
        }
        if ( defined( $Fields[4] ) && $Fields[4] =~ /\d/ ) {
            $Ob->{WBT} = ( $Fields[4] - 32 ) * 5 / 9;
        }
        if ( defined( $Fields[5] ) && $Fields[5] =~ /\d/ ) {
            $Ob->{SST} = ( $Fields[5] - 32 ) * 5 / 9;
        }

        # Winds converted from compas dir and Beaufort force
        if ( defined( $Fields[6] ) ) {
            my $Compass_d = $Fields[6];
            $Compass_d =~ s/ //g;
            $Compass_d = lc($Compass_d);
            $Ob->{D} = compass_to_degrees($Compass_d);    # Wind direction
            if ( defined( $Ob->{D} ) ) {
                $Ob->{DI} = 1;    # Winds on 32 point compass
            }
        }
        if ( defined( $Fields[7] ) ) {    # Wind speed
            if ( $Fields[7] =~ /(\d+)-(\d+)/ ) {    # range of Beaufort numbers
                $Ob->{W} = ( beaufort_to_mps($1) + beaufort_to_mps($2) ) / 2;
            }
            else {
                $Ob->{W} = beaufort_to_mps( $Fields[7] );
            }
            if ( defined( $Ob->{W} ) ) {
                $Ob->{WI} = 5;                      # Beaufort wind force
            }
        }

        # Fill in extra metadata
        $Ob->{IM}   = 0;          # Check with Scott
        $Ob->{ATTC} = 2;          # icoads and supplemental
        $Ob->{TI}   = 0;          # Nearest hour time precision
        $Ob->{DS}   = undef;      # Unknown course
        $Ob->{VS}   = undef;      # Unknown speed
        $Ob->{NID}  = 3;          # Check with Scott
        $Ob->{II}   = 10;         # Check with Scott
        $Ob->{ID}   = 'Nimrod';
        $Ob->{C1}   = '03';       # UK recruited
        if (   defined( $Ob->{AT} )
            || defined( $Ob->{WBT} )
            || defined( $Ob->{DPT} )
            || defined( $Ob->{SST} ) )
        {
            $Ob->{IT} = 4;        # Temps in degF and 10ths
        }

        # Add the icoads attachment
        push @{ $Ob->{attachments} }, 1;
        $Ob->{BSI} = undef;
        $Ob->{B10} = undef;       # 10 degree box
        $Ob->{B1}  = undef;       # 1 degree box
        $Ob->{DCK} = 246;         # Deck ID - from Scott
        $Ob->{SID} = 127;         # Source ID - from Scott
        $Ob->{PT}  = 1;           # 'merchant ship or foreign military'
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
        if ( defined( $Fields[0] ) && $Fields[0] =~ /\S/ ) {
            $Ob->{SUPD} .= sprintf "%2d", $Fields[0];
        }
        else { $Ob->{SUPD} .= "  "; }
        if ( defined( $Fields[1] ) && $Fields[1] =~ /\S/ ) {
            $Ob->{SUPD} .= sprintf " %2d", $Fields[1];
        }
        else { $Ob->{SUPD} .= "   "; }

        if ( defined( $Fields[2] ) && $Fields[2] =~ /\S/ ) {
            $Ob->{SUPD} .= sprintf " %5.2f", $Fields[2];
        }
        else { $Ob->{SUPD} .= "      "; }
        if ( defined( $Fields[3] ) && $Fields[3] =~ /\S/ ) {
            $Ob->{SUPD} .= sprintf " %5.1f", $Fields[3];
        }
        else { $Ob->{SUPD} .= "      "; }
        if ( defined( $Fields[4] ) && $Fields[4] =~ /\S/ ) {
            $Ob->{SUPD} .= sprintf " %5.1f", $Fields[4];
        }
        else { $Ob->{SUPD} .= "      "; }
        if ( defined( $Fields[5] ) && $Fields[5] =~ /\S/ ) {
            $Ob->{SUPD} .= sprintf " %5.1f", $Fields[5];
        }
        else { $Ob->{SUPD} .= "      "; }
        if ( defined( $Fields[6] ) && $Fields[6] =~ /\S/ ) {
            $Ob->{SUPD} .= sprintf " %6s", $Fields[6];
        }
        else { $Ob->{SUPD} .= "       "; }
        if ( defined( $Fields[7] ) && $Fields[7] =~ /\S/ ) {
            $Ob->{SUPD} .= sprintf " %5s", $Fields[7];
        }
        else { $Ob->{SUPD} .= "      "; }
        $Fields[8] =~ s/\n//g;
        if ( defined( $Fields[8] ) ) { $Ob->{SUPD} .= " " . $Fields[8]; }

        # Output the IMMA ob
        $Ob->write( \*STDOUT );

    }

    else {    # Header - discard
        next;
    }

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

# Correct to UTC from local time.
# This is done independently for each ob - in practise the
# ship probably corrected its time only once each 24 hrs, but I don't know when,
# so I haven't tried to follow this. (This was standard practice - but
# it makes less sense in the polar regions so they might have done something
# different).
# Also, It's apparent from the uncorrected times that the ship
# Did not change its date when crossing the date line, so in doing the
# correction I've converted longitudes west to longitudes east > 180.
sub correct_hour_for_lon_ndl {
    my @Days_in_month = ( 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31 );
    my $Ob            = shift;
    unless ( defined($Last_lon)
        && defined( $Ob->{HR} )
        && defined( $Ob->{DY} )
        && defined( $Ob->{MO} )
        && defined( $Ob->{YR} ) )
    {
        $Ob->{HR} = undef;
        return;
    }
    my $Lon_C = $Last_lon;
    if ( $Lon_C < 0 ) { $Lon_C += 360; }    # No date line
    if ( $Ob->{YR} % 4 == 0
        && ( $Ob->{YR} % 100 != 0 || $Ob->{YR} % 400 == 0 ) )
    {
        $Days_in_month[1] = 29;
    }
    $Ob->{HR} += $Lon_C * 12 / 180;
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

# Correct the date to UTC from local time
# This version not used here - kept in for historical reasons.
sub correct_hour_for_lon {
    my @Days_in_month = ( 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31 );
    my $Ob            = shift;
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

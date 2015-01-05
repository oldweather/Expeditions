#!/usr/bin/perl

# Brocess digitised logbook data from The Nimrod into
#  IMMA records.

use strict;
use warnings;
use lib "/home/hc1300/hadpb/tasks/imma/perl_module";
use IMMA;
use Getopt::Long;
use FindBin;

my $Ship_name = 'TerraNova';
my ( $Year, $Month, $Day );
my %Map_months = (
    jan => 1,
    feb => 2,
    mar => 3,
    apr => 4,
    may => 5,
    jun => 6,
    jul => 7,
    aug => 8,
    sep => 9,
    oct => 10,
    nov => 11,
    dec => 12
);

for ( my $i = 0 ; $i < 5 ; $i++ ) { <>; }    # Skip the header lines

while (<>) {
    $_ =~ s/\n//g;
    if ( $_ =~ /^\"(\w+), (\d\d\d\d)/ ) {    # Deal explicitly with the dates
        $Year = $2;
        $Month = $Map_months{ lc( substr( $1, 0, 3 ) ) };
        unless ( defined($Month) ) { die "Bad Month $1"; }
    }
    elsif ( $_ =~ /^\s*\d/ ) {               # Data line
        my $Ob = new IMMA;
        $Ob->clear();                        # Why is this necessary?
        push @{ $Ob->{attachments} }, 0;
        my @Fields = split /\t/, $_;
        for(my $i=0;$i<scalar(@Fields);$i++) {  # Clean of unnecessary spaces.
            $Fields[$i] =~ s/^\s+//;
            $Fields[$i] =~ s/\s+$//;
        }
        if ( defined( $Fields[0] ) && $Fields[0] =~ /\d/ ) {
            $Day = $Fields[0];
        }
        $Ob->{YR} = $Year;
        $Ob->{MO} = $Month;
        $Ob->{DY} = $Day;
        if ( defined( $Fields[1] ) && $Fields[1] =~ /\d/ ) {
            $Ob->{HR} = $Fields[1];
        }
        correct_hour_for_tz($Ob);

        if ( $Fields[2] =~ /(\d+)\s+(\d+)/ ) {
            $Ob->{LAT} = $1;
            $Ob->{LAT} += $2 / 60;
            $Ob->{LAT} *= -1;    # South
        }
        if ( $Fields[3] =~ /(\d+)\s+(\d+)\s+([EW])/ ) {
            $Ob->{LON} = $1;
            $Ob->{LON} += $2 / 60;
            if ( defined($3) && lc($3) eq 'w' ) {
                $Ob->{LON} *= -1;
            }
            $Ob->{LI}  = 4;         # Position digitised as deg+minutes
        }
        if (
            lc( $Fields[2] ) =~
            /cape royds|cape evans|hut point|mcmurdo sound|glacier tongue/
            || lc( $Fields[3] ) =~
            /cape royds|cape evans|hut point|mcmurdo sound|glacier tongue/ )
        {
            $Ob->{LAT} = -77.55;    # Set to position of Cape Royds
            $Ob->{LON} = 166.15;
            $Ob->{LI}  = 6;         # Position from MetaData
        }

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
        if ( defined( $Fields[18] ) && $Fields[18] =~ /([+\-\d\.]+)/ ) {
            $Ob->{SST} = ( $1 - 32 ) * 5 / 9;
        }

        # Winds converted from compas dir and Beaufort force
        if ( defined( $Fields[4] ) ) {
            my $Compass_d = $Fields[4];
            $Compass_d =~ s/ //g;
            $Compass_d = lc($Compass_d);
            $Ob->{D} = compass_to_degrees($Compass_d);    # Wind direction
            if ( defined( $Ob->{D} ) ) {
                $Ob->{DI} = 3;    # Winds on 16 point compass
            }
        }
        if ( defined( $Fields[5] ) ) {    # Wind speed
            if ( $Fields[5] =~ /(\d+)-(\d+)/ ) {    # range of Beaufort numbers
                $Ob->{W} = ( beaufort_to_mps($1) + beaufort_to_mps($2) ) / 2;
            }
            else {
                $Ob->{W} = beaufort_to_mps( $Fields[5] );
            }
            if ( defined( $Ob->{W} ) ) {
                $Ob->{WI} = 5;                      # Beaufort wind force
            }
        }

        # Fill in extra metadata
        $Ob->{IM}   = 0;            # Check with Scott
        $Ob->{ATTC} = 2;            # icoads and supplemental
        $Ob->{TI}   = 0;            # Nearest hour time precision
        $Ob->{DS}   = undef;        # Unknown course
        $Ob->{VS}   = undef;        # Unknown speed
        $Ob->{NID}  = 3;            # Check with Scott
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
        push @{ $Ob->{attachments} }, 1;
        $Ob->{BSI} = undef;
        $Ob->{B10} = undef;         # 10 degree box
        $Ob->{B1}  = undef;         # 1 degree box
        $Ob->{DCK} = 246;           # Deck ID - from Scott
        $Ob->{SID} = 127;           # Source ID - from Scott
        $Ob->{PT}  = 1;             # 'merchant ship or foreign military'
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

        # Day
        if ( defined( $Fields[0] ) && $Fields[0] =~ /\S/ ) {
            $Ob->{SUPD} .= sprintf "%2d", $Fields[0];
        }
        else { $Ob->{SUPD} .= "  "; }

        # Hour
        if ( defined( $Fields[1] ) && $Fields[1] =~ /\S/ ) {
            $Ob->{SUPD} .= sprintf " %5s", $Fields[1];
        }
        else { $Ob->{SUPD} .= "      "; }

        # LAT
        if ( defined( $Fields[2] ) && $Fields[2] =~ /\S/ ) {
            $Ob->{SUPD} .= sprintf " %12s", $Fields[2];
        }
        else { $Ob->{SUPD} .= "             "; }

        # LON
        if ( defined( $Fields[3] ) && $Fields[3] =~ /\S/ ) {
            $Ob->{SUPD} .= sprintf " %30s", $Fields[3];
        }
        else { $Ob->{SUPD} .= "                               "; }

        # Wind direction
        if ( defined( $Fields[4] ) && $Fields[4] =~ /\S/ ) {
            $Ob->{SUPD} .= sprintf " %5s", $Fields[4];
        }
        else { $Ob->{SUPD} .= "      "; }

        # Wind force
        if ( defined( $Fields[5] ) && $Fields[5] =~ /\S/ ) {
            $Ob->{SUPD} .= sprintf " %10s", $Fields[5];
        }
        else { $Ob->{SUPD} .= "           "; }

        # Pressure
        if ( defined( $Fields[6] ) && $Fields[6] =~ /\S/ ) {
            $Ob->{SUPD} .= sprintf " %6s", $Fields[6];
        }
        else { $Ob->{SUPD} .= "       "; }

        # Dry bulb
        if ( defined( $Fields[7] ) && $Fields[7] =~ /\S/ ) {
            $Ob->{SUPD} .= sprintf " %5s", $Fields[7];
        }
        else { $Ob->{SUPD} .= "      "; }

        # Wet bulb
        if ( defined( $Fields[8] ) && $Fields[8] =~ /\S/ ) {
            $Ob->{SUPD} .= sprintf " %5s", $Fields[8];
        }
        else { $Ob->{SUPD} .= "      "; }

        # Lower cloud
        if ( defined( $Fields[9] ) && $Fields[9] =~ /\S/ ) {
            $Ob->{SUPD} .= sprintf " %32s", $Fields[9];
        }
        else { $Ob->{SUPD} .= "                                 "; }

        # Upper cloud
        if ( defined( $Fields[10] ) && $Fields[10] =~ /\S/ ) {
            $Ob->{SUPD} .= sprintf " %27s", $Fields[10];
        }
        else { $Ob->{SUPD} .= "                            "; }

        # Cloud Amount
        if ( defined( $Fields[11] ) && $Fields[11] =~ /\S/ ) {
            $Ob->{SUPD} .= sprintf " %2s", $Fields[11];
        }
        else { $Ob->{SUPD} .= "   "; }

        # Beaufort notation
        if ( defined( $Fields[12] ) && $Fields[12] =~ /\S/ ) {
            $Ob->{SUPD} .= sprintf " %16s", $Fields[12];
        }
        else { $Ob->{SUPD} .= "                 "; }

        # Fog intensity
        if ( defined( $Fields[13] ) && $Fields[13] =~ /\S/ ) {
            $Ob->{SUPD} .= sprintf " %3s", $Fields[13];
        }
        else { $Ob->{SUPD} .= "    "; }

        # Wave direction
        if ( defined( $Fields[14] ) && $Fields[14] =~ /\S/ ) {
            $Ob->{SUPD} .= sprintf " %15s", $Fields[14];
        }
        else { $Ob->{SUPD} .= "                "; }

        # Wave disturbance
        if ( defined( $Fields[15] ) && $Fields[15] =~ /\S/ ) {
            $Ob->{SUPD} .= sprintf " %15s", $Fields[15];
        }
        else { $Ob->{SUPD} .= "                "; }

        # Swell direction
        if ( defined( $Fields[16] ) && $Fields[16] =~ /\S/ ) {
            $Ob->{SUPD} .= sprintf " %22s", $Fields[16];
        }
        else { $Ob->{SUPD} .= "                       "; }

        # Swell disturbance
        if ( defined( $Fields[17] ) && $Fields[17] =~ /\S/ ) {
            $Ob->{SUPD} .= sprintf " %15s", $Fields[17];
        }
        else { $Ob->{SUPD} .= "                "; }

        # Sea temperature
        if ( defined( $Fields[18] ) && $Fields[18] =~ /\S/ ) {
            $Ob->{SUPD} .= sprintf " %5s", $Fields[18];
        }
        else { $Ob->{SUPD} .= "      "; }

        # Sea colour
        if ( defined( $Fields[19] ) && $Fields[19] =~ /\S/ ) {
            $Ob->{SUPD} .= sprintf " %20s", $Fields[19];
        }
        else { $Ob->{SUPD} .= "                     "; }

        # Remarks
        if ( defined( $Fields[20] ) ) {
            $Fields[20] =~ s/\n//g;
            $Ob->{SUPD} .= " " . $Fields[20];
        }

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
# In this case, ship's time was always 12 hours fast on GMT
sub correct_hour_for_tz {
    my @Days_in_month = ( 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31 );
    my $Ob            = shift;
    unless ( defined( $Ob->{HR} )
        && defined( $Ob->{DY} )
        && defined( $Ob->{MO} )
        && defined( $Ob->{YR} ) )
    {
        $Ob->{HR} = undef;
        return;
    }
    $Ob->{HR} -= 12;
    if ( $Ob->{HR} < 0 ) {
        $Ob->{HR} += 24;
        $Ob->{DY}--;
        if ( $Ob->{DY} < 1 ) {
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


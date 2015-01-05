#!/usr/bin/perl

# Process the digitised Franklin data from the 1776 trip into
#  IMMA records.

use strict;
use warnings;
use IMMA;
use Getopt::Long;
use FindBin;
use Date::Calc qw(Delta_Days);

my $Month;
my $Last_lon = 62;

for ( my $i = 0 ; $i < 4 ; $i++ ) { <>; }    # Skip headers and Oct and Nov data

while ( my $Line = <> ) {
    my @Fields = split /\t/, $Line;
    my $Ob = new IMMA;
    $Ob->clear();
    push @{ $Ob->{attachments} }, 0;

    # Ship was the Reprisal
    $Ob->{ID} = "Reprisal";

    # Date
    $Ob->{YR} = 1776;
    if ( $Fields[0] =~ /Oct/ ) { $Month = 10; }
    if ( $Fields[0] =~ /Nov/ ) { $Month = 11; }
    $Ob->{MO} = $Month;
    if ( $Fields[1] =~ /\d/ ) { $Ob->{DY} = $Fields[1]; }

    $Ob->{IM}   = 0;        # Check with Scott
    $Ob->{ATTC} = 1;        # Supplemental
    $Ob->{TI}   = 0;        # Nearest hour time precision
    $Ob->{DS}   = undef;    # Unknown course
    $Ob->{VS}   = undef;    # Unknown speed
    $Ob->{NID}  = 3;        # Check with Scott
    $Ob->{II}   = 10;       # Check with Scott

    # Latitude
    if ( $Fields[6] =~ /\d+/ ) {
        $Ob->{LAT} = $Fields[6] + $Fields[7] / 60;
    }

    # Longitude
    if ( $Fields[8] =~ /\d+/ ) {
        $Ob->{LON} = $Fields[8] + $Fields[9] / 60;
        $Ob->{LON} *= -1;
        $Last_lon = $Ob->{LON};
    }
    if ( $Fields[2] =~ /(\d+)(.m)/ ) {
        $Ob->{HR} = $1;
        if ( $2 eq 'pm' && $Ob->{HR} != 12) { $Ob->{HR} += 12; }
        correct_hour_for_lon($Ob);
    }

    # Air temperature
    if ( $Fields[3] =~ /\d/ ) {
        $Ob->{AT} = $Fields[3];
        $Ob->{AT} = ( $Ob->{AT} - 32 ) * 5 / 9;
    }

    # Sea temperature
    if ( $Fields[4] =~ /\d/ ) {
        $Ob->{SST} = $Fields[4];
        $Ob->{SST} = ( $Ob->{SST} - 32 ) * 5 / 9;
    }

    # Add the original record as a supplemental attachment
    push @{ $Ob->{attachments} }, 99;
    $Ob->{ATTE} = undef;
    chomp($Line);
    $Ob->{SUPD} = $Line;

    # Output the ob
    $Ob->write( \*STDOUT );

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

sub decode_direction {
    my $Dir_c = lc(shift);
    $Dir_c =~ s/b/x/;
    my %Directions = (
        n       => 360,
        north   => 360,
        nxe     => 11,
        nne     => 23,
        nexn    => 34,
        ne      => 45,
        nexe    => 57,
        ene     => 68,
        exn     => 79,
        e       => 90,
        east    => 90,
        exs     => 102,
        ese     => 113,
        sexe    => 124,
        se      => 135,
        sexs    => 147,
        sse500e => 147,
        sse     => 158,
        sxe     => 169,
        sse500s => 169,
        s       => 180,
        south   => 180,
        sxw     => 192,
        ssw     => 203,
        sw500w  => 203,
        swxs    => 214,
        sw      => 225,
        swxw    => 237,
        wsw     => 248,
        wxs     => 259,
        w       => 270,
        west    => 270,
        wxn     => 282,
        wnw     => 293,
        nwxw    => 304,
        nw      => 315,
        nwxn    => 326,
        nnw     => 337,
        nxw     => 349,
        c       => 361,    # Calm
        v       => 362     # Variable
    );
    unless ( defined($Dir_c) ) { return undef; }
    $Dir_c =~ s/b/x/;
    $Dir_c =~ s/\s//g;
    if ( exists( $Directions{ lc($Dir_c) } ) ) {
        return $Directions{ lc($Dir_c) };
    }
    else {
        warn "Unknown wind direction $Dir_c";
        return undef;
    }
}

# Make an average between two angles in degrees
sub direction_average {
    my ( $D1, $D2 ) = @_;
    unless ( defined($D1)
        && defined($D2)
        && $D1 >= 0
        && $D1 <= 360
        && $D2 >= 0
        && $D2 <= 360 )
    {
        return;
    }
    my $Diff = $D2 - $D1;
    if ( $Diff > 180 )  { $Diff = 360 - $Diff; }
    if ( $Diff < -180 ) { $Diff = 360 + $Diff; }
    my $Avg = $D1 + $Diff / 2;
    if ( $Avg > 360 ) { $Avg -= 360; }
    if ( $Avg < 0 ) { $Avg += 360; }
    return $Avg;
}

#!/usr/bin/perl

# Process digitised logbook data from The Porquoi-Pas into
#  IMMA records.
# This version does the data from winter quarters at Petermann Island

use strict;
use warnings;
use lib "/home/hc1300/hadpb/tasks/digitisation/imma/";
use IMMA;
use Getopt::Long;
use FindBin;

my $Ship_name = 'PqP PtmnI';
my ( $Year, $Month, $Day );
my $Lat      = -65.55;
my $Lon      = -68.55 + 2.33;
my $Last_lon = $Lon;

my %Map_month = (
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

while (<>) {

    if ( $_ =~ /(\w+)\s*(\d\d\d\d)   mm/ ) {
        $Month = map_month($1);
        $Year  = $2;
    }

    if ( $_ =~ /^\d/ ) {
        my @Fields = split;
        my $Day    = $Fields[0];
        for ( my $i = 1 ; $i <= 24 ; $i++ ) {
            unless ( defined( $Fields[$i] ) && $Fields[$i] =~ /\d/ ) { next; }

            my $Ob = new IMMA;
            $Ob->clear();    # Why is this necessary?
            push @{ $Ob->{attachments} }, 0;

            $Ob->{YR} = $Year;
            $Ob->{MO} = $Month;
            $Ob->{DY} = $Day;
            $Ob->{HR} = $i;
            $Ob->{LAT} = $Lat;
            $Ob->{LON} = $Lon;

            correct_hour_for_lon_ndl($Ob);    # Convert time to UTC

            # Pressure converted from mm
            $Ob->{SLP} = ($Fields[$i]+700) * 1.33322387415;

            # Fill in extra metadata
            $Ob->{IM}   = 0;                  # Check with Scott
            $Ob->{ATTC} = 1;                  # Icoads
            $Ob->{TI}   = 0;                  # Nearest hour
            $Ob->{DS}   = undef;              # Unknown course
            $Ob->{VS}   = undef;              # Unknown speed
            $Ob->{NID}  = 3;                  # Check with Scott
            $Ob->{II}   = 10;                 # Check with Scott
            $Ob->{ID}   = $Ship_name;
            $Ob->{C1}   = '04';               # French

            # Add the icoads attachment
            push @{ $Ob->{attachments} }, 1;
            $Ob->{BSI} = undef;
            $Ob->{B10} = undef;    # 10 degree box
            $Ob->{B1}  = undef;    # 1 degree box
            $Ob->{DCK} = 246;      # Deck ID - from Scott
            $Ob->{SID} = 127;      # Source ID - from Scott
            $Ob->{PT}  = 1;        # 'merchant ship or foreign military'
            foreach my $Var (qw(DUPS DUPC TC PB WX SX C2)) {
                $Ob->{$Var} = undef;
            }

            # Other elements all missing
            foreach my $Var ( @{ $IMMA::parameters[1] } ) {
                unless ( exists( $Ob->{$Var} ) ) {
                    $Ob->{$Var} = undef;
                }
            }

            # Output the IMMA ob
            $Ob->write( \*STDOUT );

        }
    }

}

sub map_month {
    my $Mon = substr( lc(shift), 0, 3 );
    if ( exists( $Map_month{$Mon} ) ) {
        return $Map_month{$Mon};
    }
    else {
        die "Bad month name $Mon";
    }
}

# Correct to UTC from local time.
# This is done independently for each ob - in practise the
# ship probably corrected its time only once each 24 hrs, but I don't know when,
# so I haven't tried to follow this. (This was standard practice - but
# it makes less sense in the polar regions so they might have done something
# different).
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


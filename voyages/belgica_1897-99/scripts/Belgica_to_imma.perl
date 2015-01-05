#!/usr/bin/perl

# Process digitised logbook data from The Belgica into
#  IMMA records.

use strict;
use warnings;
use lib "/home/hc1300/hadpb/tasks/imma/perl_module";
use IMMA;
use Getopt::Long;
use FindBin;

# Read in the Data from Rob's spreadsheet
my @Pressure;
my $Month;
my $Year;
my ( @latS, @latE, @lonS, @lonE );
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

open( DIN, "$FindBin::Bin/../as_digitised/BELGICA2.txt" ) or die;
while (<DIN>) {
    if ( $_ =~ /MSLP/ ) {    # Header line - get the month name
        $Month = $Map_months{ lc( substr( ( split /\t/, $_ )[8], 0, 3 ) ) };
        $Year = ( split /\t/, $_ )[9];
    }
    elsif ( $_ =~
        /(\d+)°\s*(\d+)\' +and +(\d+)°(\d+)\'\D+(\d+)°\s*(\d+)\' +and +(\d+)°\s*(\d+)\'/
      )
    {                        # Positions
        warn "$1 $2 $3 $4 $5 $6 $7 $8";
        $latS[$Year][$Month] = ( $1 + $2 / 60 ) * -1;
        $latE[$Year][$Month] = ( $3 + $4 / 60 ) * -1;
        $lonS[$Year][$Month] = ( $5 + $6 / 60 ) * -1;
        $lonE[$Year][$Month] = ( $7 + $8 / 60 ) * -1;
    }
    elsif ( $_ =~ /^\d/ ) {    # Data line
        my @Fields = split /\t/, $_;
        my $Day    = shift(@Fields);
        my $Mean   = pop(@Fields);
        $Pressure[$Year][$Month][$Day] = [@Fields];
    }
}
close(DIN);

for ( my $i = 0 ; $i < scalar(@Pressure) ; $i++ ) {    # Year
    for ( my $j = 1 ; $j <= 12 ; $j++ ) {              # Month
        unless ( defined( $Pressure[$i][$j] ) ) { next; }
        for ( my $k = 1 ; $k < scalar( @{ $Pressure[$i][$j] } ) ; $k++ ) { # Day
            for ( my $l = 0 ; $l < 24 ; $l++ ) {    # Hour
                unless ( defined( $Pressure[$i][$j][$k][$l] )
                    && $Pressure[$i][$j][$k][$l] =~ /\d/ )
                {
                    next;
                }
                my $Ob = new IMMA;
                $Ob->clear();                       # Why is this necessary?
                push @{ $Ob->{attachments} }, 0;

                #my $Fraction_through_month =
                #  ( $k - 1 + ( $l / 24 ) ) / scalar( @{ $Pressure[$i][$j] } );
                $Ob->{LAT} = ( $latS[$i][$j] + $latE[$i][$j] ) / 2;
                $Ob->{LON} = ( $lonS[$i][$j] + $lonE[$i][$j] ) / 2;
                $Ob->{LI} = 3;                      # Positions interpolated
                $Ob->{YR} = $i;
                $Ob->{MO} = $j;
                $Ob->{DY} = $k;
                $Ob->{HR} = $l;
                correct_hour_for_lon_ndl($Ob);

                # Pressure converted from mmHg
                $Ob->{SLP} =
                  ( $Pressure[$i][$j][$k][$l] + 700 ) * 1.33322387415;

                # Fill in extra metadata
                $Ob->{IM}   = 0;           # Check with Scott
                $Ob->{ATTC} = 2;           # icoads and supplemental
                $Ob->{TI}   = 0;           # Nearest hour time precision
                $Ob->{DS}   = undef;       # Unknown course
                $Ob->{VS}   = undef;       # Unknown speed
                $Ob->{NID}  = 3;           # Check with Scott
                $Ob->{II}   = 10;          # Check with Scott
                $Ob->{ID}   = 'Belgica';
                $Ob->{C1}   = undef;       # UK recruited

                # Add the icoads attachment
                push @{ $Ob->{attachments} }, 1;
                $Ob->{BSI} = undef;
                $Ob->{B10} = undef;        # 10 degree box
                $Ob->{B1}  = undef;        # 1 degree box
                $Ob->{DCK} = 246;          # Deck ID - from Scott
                $Ob->{SID} = 127;          # Source ID - from Scott
                $Ob->{PT}  = 1;            # 'merchant ship or foreign military'
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
    unless ( defined( $Ob->{LON} )
        && defined( $Ob->{HR} )
        && defined( $Ob->{DY} )
        && defined( $Ob->{MO} )
        && defined( $Ob->{YR} ) )
    {
        $Ob->{HR} = undef;
        return;
    }
    my $Lon_C = $Ob->{LON};
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


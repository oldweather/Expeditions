#!/usr/bin/perl

# Make estimates of ice-cover from SST, AT and speed

use strict;
use warnings;
use IMMA;
use FindBin;
use MarineOb::ice_estimators qw(ice);
use MarineOb::immalibPB qw(Delta_Meters Delta_Seconds);
use Date::Calc qw(Delta_Days);
use Numeric::median;

my @obs;
while ( my $ob = imma_read( \*STDIN ) ) {
    push @obs, $ob;
}
for ( my $i = 0 ; $i < scalar(@obs) ; $i++ ) {
    if (   !defined( $obs[$i]->{YR} )
        || !defined( $obs[$i]->{MO} )
        || !defined( $obs[$i]->{DY} )
        || !defined( $obs[$i]->{HR} )
        || !defined( $obs[$i]->{LAT} )
        || !defined( $obs[$i]->{LON} ) )
    {
        next;
    }

    my $Speed;
    if (   $i > 0
        && defined( $obs[ $i - 1 ]->{LAT} )
        && defined( $obs[ $i - 1 ]->{LON} ) )
    {
        my $dTime = Delta_Seconds( $obs[ $i - 1 ], $obs[$i] );
        my $dSpace = Delta_Meters( $obs[$i], $obs[ $i - 1 ] );
        if (   defined($dTime)
            && defined($dSpace)
            && $dTime < 86400 * 5
            && $dTime > 1
            && $dSpace < 500000 )
        {
            $Speed = $dSpace / $dTime;
            $Speed *= 2;   # Double speed as a (slow) sailing ship (bomb vessel)
        }
    }

    my @ATV;
    if (   defined( $obs[$i]->{YR} )
        && defined( $obs[$i]->{MO} )
        && defined( $obs[$i]->{DY} ) )
    {
        for ( my $j = $i ; $j >= 0 ; $j-- ) {
            if (   defined( $obs[$j]->{YR} )
                && defined( $obs[$j]->{MO} )
                && defined( $obs[$j]->{DY} ) )
            {
                if (
                    abs(
                        Delta_Days(
                            $obs[$i]->{YR}, $obs[$i]->{MO}, $obs[$i]->{DY},
                            $obs[$j]->{YR}, $obs[$j]->{MO}, $obs[$j]->{DY}
                        )
                    ) > 7
                  )
                {
                    last;
                }
                if ( defined( $obs[$j]->{AT} ) ) { push @ATV, $obs[$j]->{AT}; }
            }
        }
        for ( my $j = $i + 1 ; $j < scalar(@obs) ; $j++ ) {
            if (   defined( $obs[$j]->{YR} )
                && defined( $obs[$j]->{MO} )
                && defined( $obs[$j]->{DY} ) )
            {
                if (
                    abs(
                        Delta_Days(
                            $obs[$i]->{YR}, $obs[$i]->{MO}, $obs[$i]->{DY},
                            $obs[$j]->{YR}, $obs[$j]->{MO}, $obs[$j]->{DY}
                        )
                    ) > 7
                  )
                {
                    last;
                }
                if ( defined( $obs[$j]->{AT} ) ) { push @ATV, $obs[$j]->{AT}; }
            }
        }
    }

    my %Ice = ice(
        SST   => $obs[$i]->{SST},
        AT    => $obs[$i]->{AT},
        long  => $obs[$i]->{LON},
        month => $obs[$i]->{MO},
        speed => $Speed,
        ATV   => \@ATV
    );

    printf "%04d/%02d/%02d %02d:00:00 ", $obs[$i]->{YR}, $obs[$i]->{MO},
      $obs[$i]->{DY}, $obs[$i]->{HR};
    foreach my $Var qw(SST AT ATV speed) {
        if ( defined( $Ice{$Var} ) ) {
            printf " %4.2f", $Ice{$Var};
        }
        else { print "   NA"; }
    }
    print "\n";
}


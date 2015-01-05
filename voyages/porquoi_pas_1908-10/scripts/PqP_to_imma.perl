#!/usr/bin/perl

# Process digitised logbook data from The Porquoi-Pas into
#  IMMA records.

use strict;
use warnings;
use lib "/home/hc1300/hadpb/tasks/digitisation/imma/";
use IMMA;
use Getopt::Long;
use FindBin;

my $Ship_name = 'PorquoiP';
my ( $Year, $Month, $Day, $Lat, $Lon );
my $Last_lon;

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

    if ( $_ =~ /Mean/ ) { next; }

    if ( $_ =~
        /(\d+)\w\w\s+(\w\w\w) +(\d\d\d\d)\s+L=\s*(\d+) (\d+)([\w])\s+G=\s*(\d+) (\d+)([\w])/
      )
    {
        $Year  = $3;
        $Month = map_month( lc($2) );
        $Day   = $1;
        $Lat   = $4 + $5 / 60;
        if ( lc($6) eq 's' ) { $Lat *= -1; }
        elsif ( lc($6) ne 'n' ) { die "Bad Lat hemisphere: $6"; }
        $Lon = $7 + $8 / 60;
        if ( lc($9) eq 'w' ) { $Lon *= -1; }
        elsif ( lc($9) ne 'e' ) { die "Bad Lon hemisphere: $9"; }
        $Lon += 2.33;    # Paris longitudes
        $Last_lon = $Lon;
    }
    elsif ( $_ =~ /(\d+)\w\w\s+(\w\w\w) +(\d\d\d\d)/ ) {
        $Year  = $3;
        $Month = map_month( lc($2) );
        $Day   = $1;
        if($_ =~ /ILE\s+DECEPTION/) {
            $Lat = -62.92;
            $Lon= -62.92+2.33;
        }
        elsif($_ =~ /BAIE\s+DE\s+L'AMIRAUTE/) {
            $Lat = -62.92;
            $Lon= -62.92+2.33;
        }
        elsif($_ =~ /BAIE\s+MARGUERITE/) {
            $Lat = -67.72;
            $Lon= -70.75+2.33;
        }
        elsif($_ =~ /ILE\s+PETERMANN/) {
            $Lat = -65.17;
            $Lon= -66.57+2.33;
        }
        elsif($_ =~ /CAPE\s+TUXEN/) {
            $Lat = -65.17;
            $Lon= -66.57+2.33;
        }
        else {
            $Lat = undef();
            $Lon = undef();
            warn "Unrecognized place: $_";
        }
    }    
    elsif ( $_ =~ /(\d+)\s+([\d\.]+)\s+([\-\.\d]+)/ ) {
        my $Ob = new IMMA;
        $Ob->clear();    # Why is this necessary?
        push @{ $Ob->{attachments} }, 0;

        $Ob->{YR} = $Year;
        $Ob->{MO} = $Month;
        $Ob->{DY} = $Day;
        $Ob->{HR} = $1;
        if ( $Ob->{HR} == 12 ) {
            $Ob->{LAT} = $Lat;
            $Ob->{LON} = $Lon;
            $Ob->{LI}  = 4;      # Deg+Min position precision
        }
        
        correct_hour_for_lon_ndl($Ob); # Convert time to UTC
        
        # Pressure converted from mm
        $Ob->{SLP} = $2 * 1.33322387415;

        # Temperatures in C
        $Ob->{AT} = $3;
        $Ob->{IT} = 0; # Centigrade and tenths

        # Fill in extra metadata
        $Ob->{IM}   = 0;            # Check with Scott
        $Ob->{ATTC} = 1;            # Icoads
        $Ob->{TI}   = 0;            # Nearest hour
        $Ob->{DS}   = undef;        # Unknown course
        $Ob->{VS}   = undef;        # Unknown speed
        $Ob->{NID}  = 3;            # Check with Scott
        $Ob->{II}   = 10;           # Check with Scott
        $Ob->{ID}   = $Ship_name;
        $Ob->{C1}   = '04';         # French

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

        # Output the IMMA ob
        $Ob->write( \*STDOUT );
    }
    else { warn "Unmatched line: $_"; }
}

sub map_month {
    my $Mon = lc(shift);
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


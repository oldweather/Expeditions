#!/usr/bin/perl

# Process digitised logbook data from The BANZARE expedition into
#  IMMA records.

use strict;
use warnings;
use lib "/home/hc1300/hadpb/tasks/digitisation/imma/";
use IMMA;
use Getopt::Long;
use FindBin;

my $Ship_name = 'Discovery';
my ( $Year, $Month, $Day, $Lat, $Lon );
my $Time_offset;
my $SST_in_Celsius = 0;

while (<>) {

    if ( $_ !~ /^\s*\d/ ) { next; }    # Discard headers

    my @Fields = split /\t/, $_;

    if ( defined( $Fields[0] ) && $Fields[0] =~ /\d/ ) {
        $Year = $Fields[0];
    }
    if ( defined( $Fields[1] ) && $Fields[1] =~ /\d/ ) {
        $Month = $Fields[1];
    }
    if ( defined( $Fields[2] ) && $Fields[2] =~ /\d/ ) {
        $Day = $Fields[2];
    }
    if ( defined( $Fields[3] ) && $Fields[3] =~ /\d/ ) {
        $Time_offset = $Fields[3] - $Fields[4];
    }

    my $Ob = new IMMA;
    $Ob->clear();    # Why is this necessary?
    push @{ $Ob->{attachments} }, 0;

    $Ob->{YR} = $Year;
    $Ob->{MO} = $Month;
    $Ob->{DY} = $Day;
    $Ob->{HR} = $Fields[4];

    # Correct time to GMT
    GMTTime( $Ob, $Time_offset );

    if ( defined( $Fields[5] ) && $Fields[5] =~ /\d/ ) {
        $Fields[5] =~ /(\d+)[\s\.]+(\d+)[\s\.]+(\d*)\s*([NS])/
          or die "Bad LAT: $Fields[5]";
        my $Min = $2;
        if ( defined($3) && $3 ne "" ) {
            $Min += $3 / 10;
        }
        $Ob->{LAT} = $1 + $Min / 60;
        if ( $4 eq 'S' ) { $Ob->{LAT} *= -1; }
    }
    if ( defined( $Fields[6] ) && $Fields[6] =~ /\d/ ) {
        $Fields[6] =~ /(\d+)[\s\.]+(\d+)[\s\.]+(\d*)\s*([EW])/
          or die "Bad LON: $Fields[6]";
        my $Min = $2;
        if ( defined($3)  && $3 ne "" ) {
            $Min += $3 / 10;
        }
        $Ob->{LON} = $1 + $Min / 60;
        if ( $4 eq 'W' ) { $Ob->{LON} *= -1; }
    }
    if ( defined( $Ob->{LON} ) && defined( $Ob->{LAT} ) ) {
        $Ob->{LI} = 4;    # Degrees+minutes
    }

    # Pressure already in hPa
    if(defined($Fields[7]) && $Fields[7] =~ /\d/) {
        $Ob->{SLP} = $Fields[7];
    }

    # Temperatures in F
    if ( defined( $Fields[8] ) && $Fields[8] =~ /\d/ ) {
        $Ob->{AT} = ( $Fields[8] - 32 ) * 5 / 9;
    }
    if ( defined( $Fields[9] ) && $Fields[9] =~ /\d/ ) {
        $Ob->{WBT} = ( $Fields[9] - 32 ) * 5 / 9;
    }
    if ( defined( $Fields[10] ) && $Fields[10] =~ /\d/ ) {
        if ( defined( $Fields[11] ) && $Fields[11] =~ /Celsius/ ) {
            $SST_in_Celsius = 1;
        }
        if ( defined( $Fields[11] ) && $Fields[11] =~ /Fahrenheit/ ) {
            $SST_in_Celsius = 0;
        }
        if ( $SST_in_Celsius == 0 ) {
            $Ob->{SST} = ( $Fields[10] - 32 ) * 5 / 9;
        }
        else {
            $Ob->{SST} = $Fields[10];
        }
    }

    # Fill in extra metadata
    $Ob->{IM}   = 0;            # Check with Scott
    $Ob->{ATTC} = 1;            # Icoads
    $Ob->{TI}   = 0;            # Nearest hour
    $Ob->{DS}   = undef;        # Unknown course
    $Ob->{VS}   = undef;        # Unknown speed
    $Ob->{NID}  = 3;            # Check with Scott
    $Ob->{II}   = 10;           # Check with Scott
    $Ob->{ID}   = $Ship_name;
    $Ob->{C1}   = '16';         # No code for commonwealth
                                # so use Australian
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
    $Ob->{PT}  = 0;             # 'US Navy or "deck" log, or unknown'
    foreach my $Var (qw(DUPS DUPC TC PB WX SX C2)) {
        $Ob->{$Var} = undef;
    }

    # Other elements all missing
    foreach my $Var ( @{ $IMMA::parameters[1] } ) {
        unless ( exists( $Ob->{$Var} ) ) {
            $Ob->{$Var} = undef;
        }
    }

    # Add any supplemental data
    if ( defined( $Fields[11] ) ) {
        chomp($Fields[11]);
        $Ob->{ATTC}++;
        push @{ $Ob->{attachments} }, 99;
        $Ob->{ATTE} = undef;
        $Ob->{SUPD} = $Fields[11];
    }

    # Output the IMMA ob
    $Ob->write( \*STDOUT );
}

# Convert ship time to UTC
sub GMTTime {
    my @Days_in_month = ( 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31 );

    my $Ob          = shift;
    my $Time_offset = shift;

    unless ( defined($Time_offset)
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
    $Ob->{HR} += $Time_offset;
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

#!/usr/bin/perl

# Process digitised logbook data from The Southern Cross into
#  IMMA records.

use strict;
use warnings;
use lib "/home/hc1300/hadpb/tasks/digitisation/imma/";
use IMMA;
use Getopt::Long;
use FindBin;

my $Ship_name = 'SouthernC';
my ( $Year, $Month, $Day );
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

# Skip headers
for(my $i=0;$i<4;$i++) { <>; }

while (<>) {

    my @Fields = split /\t/, $_;

    my $Ob = new IMMA;
    $Ob->clear();    # Why is this necessary?
    push @{ $Ob->{attachments} }, 0;

    # Date
    unless ( defined( $Fields[0] ) && $Fields[0] =~ /\d/ ) { next; }
    if ( $Fields[0] =~ /(\d\d\d\d).+(\w\w\w).+(\d+)/ ) {
        $Year  = $1;
        $Month = map_month($2);
        $Day   = $3;
    }
    elsif ( $Fields[0] =~ / (\w\w\w).+(\d+)/ ) {
        $Month = map_month($1);
        $Day   = $2;
    }
    elsif ( $Fields[0] =~ /(\d+)/ ) {
        $Day = $1;
    }
    else {
        die "Bad date format";
    }
    $Ob->{YR} = $Year;
    $Ob->{MO} = $Month;
    $Ob->{DY} = $Day;
    $Ob->{HR} = undef();    # Daily mean data
                            # Position
    if ( $Fields[1] =~ /No obs|Poss/ || $Fields[2] =~ /No obs/ ) {
        next;
    }                       # Don't bother with unknown positions
    if ( $Fields[1] =~ /(\d+) +(\d+)/ ) {
        $Ob->{LAT} = ( $1 + $2 / 60 ) * -1;
    }
    else {
        die "Bad LAT format: $Fields[1]";
    }
    if ( $Fields[2] =~ /(\d+) +(\d)/ ) {
        $Ob->{LON} = $1 + $2 / 60;
    }
    else {
        die "Bad LON format $Fields[2]";
    }
    $Ob->{LI} = 4;    # Deg+Min position precision

    # Pressure converted from inches - mean only
    if ( defined( $Fields[3] ) && $Fields[3] =~ /\d/ ) {
        $Ob->{SLP} = $Fields[3] * 33.86;
    }

    # Temperatures converted from Farenheit
    if ( defined( $Fields[6] ) && $Fields[6] =~ /\d/ ) {
        $Ob->{AT} = ( $Fields[6] - 32 ) * 5 / 9;
    }
    if ( defined( $Fields[9] ) && $Fields[9] =~ /\d/ ) {
        $Ob->{SST} = ( $Fields[9] - 32 ) * 5 / 9;
    }

    # Fill in extra metadata
    $Ob->{IM}   = 0;            # Check with Scott
    $Ob->{ATTC} = 2;            # icoads and supplemental
    $Ob->{TI}   = undef;        # Daily mean, not point values, so no time
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

    # Date
    if ( defined( $Fields[0] ) && $Fields[0] =~ /\S/ ) {
        $Ob->{SUPD} .= sprintf "%15s", $Fields[0];
    }
    else { $Ob->{SUPD} .= "               "; }

    # Position
    if ( defined( $Fields[1] ) && $Fields[1] =~ /\S/ ) {
        $Ob->{SUPD} .= sprintf " %6s", $Fields[1];
    }
    else { $Ob->{SUPD} .= "       "; }
    if ( defined( $Fields[2] ) && $Fields[2] =~ /\S/ ) {
        $Ob->{SUPD} .= sprintf " %6s", $Fields[2];
    }
    else { $Ob->{SUPD} .= "       "; }

    # Pressures
    if ( defined( $Fields[3] ) && $Fields[3] =~ /\S/ ) {
        $Ob->{SUPD} .= sprintf " %6s", $Fields[3];
    }
    else { $Ob->{SUPD} .= "       "; }
    if ( defined( $Fields[4] ) && $Fields[4] =~ /\S/ ) {
        $Ob->{SUPD} .= sprintf " %6s", $Fields[4];
    }
    else { $Ob->{SUPD} .= "       "; }
    if ( defined( $Fields[5] ) && $Fields[5] =~ /\S/ ) {
        $Ob->{SUPD} .= sprintf " %6s", $Fields[5];
    }
    else { $Ob->{SUPD} .= "       "; }

    # AT
    if ( defined( $Fields[6] ) && $Fields[6] =~ /\S/ ) {
        $Ob->{SUPD} .= sprintf " %6s", $Fields[6];
    }
    else { $Ob->{SUPD} .= "       "; }
    if ( defined( $Fields[7] ) && $Fields[7] =~ /\S/ ) {
        $Ob->{SUPD} .= sprintf " %6s", $Fields[7];
    }
    else { $Ob->{SUPD} .= "       "; }
    if ( defined( $Fields[8] ) && $Fields[8] =~ /\S/ ) {
        $Ob->{SUPD} .= sprintf " %6s", $Fields[8];
    }
    else { $Ob->{SUPD} .= "       "; }

    # SST
    if ( defined( $Fields[9] ) && $Fields[9] =~ /\S/ ) {
        $Ob->{SUPD} .= sprintf " %6s", $Fields[9];
    }
    else { $Ob->{SUPD} .= "       "; }
    if ( defined( $Fields[10] ) && $Fields[10] =~ /\S/ ) {
        $Ob->{SUPD} .= sprintf " %6s", $Fields[10];
    }
    else { $Ob->{SUPD} .= "       "; }
    if ( defined( $Fields[11] ) && $Fields[11] =~ /\S/ ) {
        $Ob->{SUPD} .= sprintf " %6s", $Fields[11];
    }
    else { $Ob->{SUPD} .= "       "; }

    # Specific gravity
    if ( defined( $Fields[12] ) && $Fields[12] =~ /\S/ ) {
        $Ob->{SUPD} .= sprintf " %5s", $Fields[12];
    }
    else { $Ob->{SUPD} .= "      "; }

    # Wind direction
    if ( defined( $Fields[13] ) && $Fields[13] =~ /\S/ ) {
        $Ob->{SUPD} .= sprintf " %56s", $Fields[13];
    }
    else {
        for ( my $i = 0 ; $i < 57 ; $i++ ) { $Ob->{SUPD} .= " "; }
    }

    # Wind speed
    if ( defined( $Fields[14] ) && $Fields[14] =~ /\S/ ) {
        $Ob->{SUPD} .= sprintf " %5s", $Fields[14];
    }
    else { $Ob->{SUPD} .= "      "; }

    # Cloud
    if ( defined( $Fields[15] ) && $Fields[15] =~ /\S/ ) {
        $Ob->{SUPD} .= sprintf " %7s", $Fields[15];
    }
    else { $Ob->{SUPD} .= "        "; }

    # Weather
    if ( defined( $Fields[16] ) && $Fields[16] =~ /\S/ ) {
        $Ob->{SUPD} .= sprintf " %7s", $Fields[16];
    }
    else { $Ob->{SUPD} .= "        "; }

    # Remarks
    $Fields[17] =~ s/\n//g;
    if ( defined( $Fields[8] ) ) { $Ob->{SUPD} .= " " . $Fields[17]; }

    # Output the IMMA ob
    $Ob->write( \*STDOUT );

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

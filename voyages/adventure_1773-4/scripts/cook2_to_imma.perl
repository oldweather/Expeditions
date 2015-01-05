#!/usr/bin/perl

# Process digitised logbook data from Cook's Adventure obs into
#  IMMA records.

use strict;
use warnings;
use IMMA;
use Getopt::Long;
use FindBin;
use Date::Calc qw(Decode_Month);
use MarineOb::lmrlib
  qw(rxltut ixdtnd rxnddt fxeimb fwbpgv fxtftc ix32dd ixdcdd fxbfms);
use MarineOb::declination qw(magnetic_to_true);
use MarineOb::WindTerms qw(WordsToBeaufort);

my $Ship_name = 'Adventure';
my ( $Year, $Month, $Day, $Hour );
my $Last_lon;
my $Last_lat;
my $Lat_flag = 'S';
my $Lon_flag = 'E';
my $Last;    # previous ob

for ( my $i = 0 ; $i < 3 ; $i++ ) { <>; }    # Skip headers

while (<>) {

    my @Fields = split /\t/, $_;
    my $String = $_;
    if ( lc( $Fields[2] ) =~ /we/ ) { $Lon_flag = 'W'; }
    if ( lc( $Fields[2] ) =~ /ea/ ) { $Lon_flag = 'E'; }

    if ( $_ =~ /^\s*(\d\d\d\d)\s+(...)/ ) {
        $Year  = $1;
        $Month = Decode_Month($2);
        if ( $Month == 0 ) { die "Bad month $2"; }
        next;
    }
    my $Ob = new IMMA;
    $Ob->clear();    # Why is this necessary?
    push @{ $Ob->{attachments} }, 0;

    if ( defined( $Fields[0] ) && $Fields[0] =~ /(\D*)\s+(\d+)/ ) {
        $Day  = $2;
        $Hour = 12;    # Noon by default
        if ( defined($1) ) {
            my $Hr = $1;
            if ( $Hr =~ /A.*M/ ) { $Hour = 8; }     # Arbitrary morning time
            if ( $Hr =~ /P.*M/ ) { $Hour = 18; }    # Arbitrary afternoon time
        }
    }
    else { next; }

    $Ob->{YR} = $Year;
    $Ob->{MO} = $Month;
    $Ob->{DY} = $Day;
    $Ob->{HR} = $Hour;

    if ( defined( $Fields[1] )
        && $Fields[1] =~ /(\d+)\s+([\d\.]+)\s*([NS]*)/ )
    {
        $Ob->{LAT} = $1 + $2 / 60;
        if ( defined($3) && ( $3 eq 'N' || $3 eq 'S' ) ) { $Lat_flag = $3; }
        if ( $Lat_flag eq 'S' ) { $Ob->{LAT} *= -1; }
    }
    if ( defined( $Fields[2] )
        && $Fields[2] =~ /(\d+)\s+([\d.]+)\s*([EW]*)/ )
    {
        $Ob->{LON} = $1 + $2 / 60;
        if ( defined($3) && ( $3 eq 'E' || $3 eq 'W' ) ) { $Lon_flag = $3; }
        if ( $Lon_flag eq 'W' ) { $Ob->{LON} *= -1; }
    }
    if ( defined( $Ob->{LAT} ) || defined( $Ob->{LON} ) ) {
        $Ob->{LI} = 4;    # Deg+Min position precision
    }
    if ( defined( $Ob->{LAT} ) ) { $Last_lat = $Ob->{LAT}; }
    if ( defined( $Ob->{LON} ) ) { $Last_lon = $Ob->{LON}; }

    # Convert ob date and time to UTC
    if (   defined($Last_lon)
        && defined( $Ob->{HR} )
        && defined( $Ob->{DY} )
        && defined( $Ob->{MO} )
        && defined( $Ob->{YR} ) )
    {
        my $elon = $Last_lon;
        if ( $elon < 0 ) { $elon += 360; }
        my ( $uhr, $udy ) = rxltut(
            $Ob->{HR} * 100,
            ixdtnd( $Ob->{DY}, $Ob->{MO}, $Ob->{YR} ),
            $elon * 100
        );
        $Ob->{HR} = $uhr / 100;
        ( $Ob->{DY}, $Ob->{MO}, $Ob->{YR} ) = rxnddt($udy);
    }
    else { $Ob->{HR} = undef; }

    # Pressure converted from inches
    if ( defined( $Fields[5] ) && $Fields[5] =~ /\d/ ) {
        $Ob->{SLP} = fxeimb( $Fields[5] );
    }

    # Gravity correction
    if ( defined( $Ob->{SLP} ) && defined($Last_lat) ) {
        $Ob->{SLP} += fwbpgv( $Ob->{SLP}, $Last_lat, 2 );
    }

    # Temperatures converted from F
    if ( defined( $Fields[4] ) && $Fields[4] =~ /\d/ ) {
        $Ob->{AT} = fxtftc( $Fields[4] );
    }

    # Extract wind direction from Remarks
    if ( defined( $Fields[6] ) && $Fields[6] =~ /\w/ ) {
        my $Dirn;
        if ( $Fields[6] =~ /^\W*Ditto/ ) {
            $Ob->{D}  = $Last->{D};
            $Ob->{DI} = $Last->{DI};
        }
        elsif ( $Fields[6] =~
            /([NESW][\s\.]+b*y*\s*[NESW]*[\s\.]*b*y*\s*[NESW]*[\s\.]+)/ )
        {
            $Dirn = $1;
            $Dirn =~ s/[\s\.]+//g;
            $Dirn =~ s/by/x/g;
        }
        elsif ( $Fields[6] =~ /[Nn]orth/ ) {
            $Dirn = 'N';
        }
        elsif ( $Fields[6] =~ /[Ee]a[sf]t/ ) {
            $Dirn = 'E';
        }
        elsif ( $Fields[6] =~ /[SsFf]outh/ ) {
            $Dirn = 'S';
        }
        elsif ( $Fields[6] =~ /[Ww]e[sf][tl]/ ) {
            $Dirn = 'W';
        }
        elsif ( $Fields[6] =~ /[Vv]ariable/ ) {
            $Dirn = 'V';
        }
        elsif ( $Fields[6] =~ /[Cc]alm/ ) {
            $Dirn = 'C';
        }
        else {
            warn "No wind direction in $Fields[6]";
        }
        if ( defined($Dirn) ) {
            $Dirn = sprintf "%-4s", uc($Dirn);
            if ( $Dirn eq 'C   ' ) {
                $Ob->{D} = 361;
            }
            elsif ( $Dirn eq 'V   ' ) {
                $Ob->{D} = 362;
            }
            else {
                ( $Ob->{D}, undef ) = ix32dd($Dirn);    # to degrees
                if ( defined( $Ob->{D} ) ) {
                    $Ob->{DI} = 1;                      # 32-point compass
                }
                else {
                    warn "Unknown wind direction $Dirn - $Fields[6]";
                }
            }
        }
    }

    # Extract wind speed from remarks
    if ( defined( $Fields[6] ) && $Fields[6] =~ /\w/ ) {
        my $Force;
        if ( $Fields[6] =~ /^.+\.\s*Ditto/ ) {
            $Ob->{W}  = $Last->{W};
            $Ob->{WI} = $Last->{WI};
        }
        elsif ( $Fields[6] =~ /(\w+\W*gale)/ ) {
            $Force = $1;
        }
        elsif ( $Fields[6] =~ /(\w+\W*wind)/ ) {
            $Force = $1;
        }
        elsif ( $Fields[6] =~ /(\w+\W*breeze)/ ) {
            $Force = $1;
        }
        elsif ( $Fields[6] =~ /(\w+\W+air)/ ) {
            $Force = $1;
        }
        elsif ( $Fields[6] =~ /[Cc]alm/ ) {
            $Force = 'calm';
        }
        if ( defined($Force) ) {
            $Force =~ s/[Ff]trong/strong/;
            $Force =~ s/[Ff]re[tfi]h/fresh/;
            $Force =~ s/[Ff]teady/steady/;
            $Force =~ s/[Bb]rifk/brisk/;
            my $F2;
            if ( $Force =~ /(\w+)\s+(\w+)/ ) {
                $F2 = WordsToBeaufort( $1, $2 );
            }
            else {
                $F2 = WordsToBeaufort($Force);
            }
            if ( defined($F2) ) {
                if ( $F2 == -1 ) {
                    warn "Unknown wind force term $Force";
                }
                else {
                    $Ob->{W}  = fxbfms($F2);    # Beaufort -> m/s
                    $Ob->{WI} = 5;              # Beaufort force
                }
            }
        }
    }

    # Fill in extra metadata
    $Ob->{IM}   = 0;                            # Check with Scott
    $Ob->{ATTC} = 0;                            # No attachments
    $Ob->{TI}   = undef;                        # Unknown time precision
    $Ob->{DS}   = undef;                        # Unknown course
    $Ob->{VS}   = undef;                        # Unknown speed
    $Ob->{NID}  = undef;                        # Check with Scott
    $Ob->{II}   = 10;                           # Check with Scott
    $Ob->{ID}   = $Ship_name;
    $Ob->{C1}   = '03';                         # UK
    if (   defined( $Ob->{AT} )
        || defined( $Ob->{WBT} )
        || defined( $Ob->{DPT} )
        || defined( $Ob->{SST} ) )
    {
        $Ob->{IT} = 4;                          # Temps in degF and 10ths
    }

    # Add the text record as an attachment
    chomp($String);
    $Ob->{ATTC}++;
    push @{ $Ob->{attachments} }, 99;
    $Ob->{ATTE} = undef;
    $Ob->{SUPD} = $String;

    $Last = $Ob;

    $Ob->write( \*STDOUT );

}


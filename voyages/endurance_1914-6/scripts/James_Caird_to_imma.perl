#!/usr/bin/perl

# Process digitised logbook data from the James Caird into
#  IMMA records.

use strict;
use warnings;
use MarineOb::IMMA;
use MarineOb::lmrlib
  qw(rxltut ixdtnd rxnddt fxeimb fwbpgv fxtftc fxtktc ix32dd ixdcdd fxbfms fwbptc);
use FindBin;
use Date::Calc qw(Add_Delta_Days);

my $Ship_name = 'JmesCaird';
my ( $Year, $Month, $Day );
my $Last_lon=-61;
my $Last_lat=-55;
my $Lat_flag = 'N';
my $Lon_flag = 'W';

#for ( my $i = 0 ; $i < 5 ; $i++ ) { <>; }    # Skip headers

while (<>) {
    unless($_ =~ /^\s*1916/) { next; }
    my $Ob = new MarineOb::IMMA;
    $Ob->clear();                            # Why is this necessary?
    push @{ $Ob->{attachments} }, 0;
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
    $Ob->{YR} = $Year;
    $Ob->{MO} = $Month;
    $Ob->{DY} = $Day;
    if($Month==5 && $Day==9 && $Fields[3] !~ /\S/) { $Fields[3]=1200; }
    if ( defined( $Fields[3] ) && $Fields[3] =~ /pm/) {  $Fields[3] =1700; }
    if ( defined( $Fields[3] ) && $Fields[3] =~ /\d/ ) {
        if($Fields[3]==2400) { 
	    ($Ob->{YR},$Ob->{MO},$Ob->{DY}) = Add_Delta_Days($Ob->{YR},$Ob->{MO},$Ob->{DY},1);
	    $Ob->{HR}=0;
        } else {
          $Ob->{HR} = int( $Fields[3] / 100 ) + ( $Fields[3] % 100 ) / 60;
        }
    }

    if ( defined( $Fields[4] ) && $Fields[4] =~ /[a-z]/ ) {    # Port name
        ( $Ob->{LAT}, $Ob->{LON} ) = position_from_port( $Fields[4] );
        $Ob->{LI} = 6;    # Position from metadata
    } elsif ( defined( $Fields[9] ) && $Fields[9] =~ /[a-z]/ ) {    # Remarks, possible port
        ( $Ob->{LAT}, $Ob->{LON} ) = position_from_port( $Fields[9] );
        if(defined($Ob->{LAT})) {$Ob->{LI} = 6;}    # Position from metadata
    }

    if ( defined( $Fields[4] )
	&& $Fields[4] =~ /(\d+)\D+(\d+)/ )
    {
	$Ob->{LAT} = ($1 + $2 / 60)*-1;
    }
    if ( defined( $Fields[5] )
	&& $Fields[5] =~ /(\d+)\D+(\d+)/ )
    {
	$Ob->{LON} = ($1 + $2 / 60)*-1;
    }
    if ( defined( $Ob->{LAT} ) || defined( $Ob->{LON} ) ) {
	$Ob->{LI} = 4;    # Deg+Min position precision
    }
    if ( defined( $Ob->{LON} ) ) { $Last_lon = $Ob->{LON}; }
    if ( defined( $Ob->{LAT} ) ) { $Last_lat = $Ob->{LAT}; }
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

    if ( defined( $Fields[6] ) && $Fields[6] =~ /\S/ ) {
        my $Dirn = $Fields[6];
        $Dirn =~ s/b/x/;
        $Dirn =~ s/\//x/;
        $Dirn = sprintf "%-4s", uc($Dirn);
        if($Dirn =~ /CALM/) { $Ob->{D} = 361; }
        elsif($Dirn =~ /VAR/) { $Ob->{D} = 362; }
	else {
	    ( $Ob->{D}, undef ) = ix32dd($Dirn);
	    if ( defined( $Ob->{D} ) ) {
		$Ob->{DI} = 1;    # 32-point compass
	    }
	    else {
		warn "Unknown wind direction $Dirn - $Fields[8]";
	    }
	}
    }
    if ( defined( $Fields[7] ) && $Fields[7] =~ /\d/ ) {
                $Ob->{W}  = fxbfms($Fields[7]);    # Beaufort -> m/s
                $Ob->{WI} = 5;                 # Beaufort force
    }

    # Fill in extra metadata
    $Ob->{IM}   = 0;            
    $Ob->{ATTC} = 0;            # None
    $Ob->{TI}   = 0;            # Nearest hour time precision
    $Ob->{DS}   = undef;        # Unknown course
    $Ob->{VS}   = undef;        # Unknown speed
    $Ob->{NID}  = 3;            
    $Ob->{II}   = 10;           
    $Ob->{ID}   = $Ship_name;
    $Ob->{C1}   = '03';         # UK recruited
    if (   defined( $Ob->{AT} )
        || defined( $Ob->{WBT} )
        || defined( $Ob->{DPT} )
        || defined( $Ob->{SST} ) )
    {
        $Ob->{IT} = 4;          # Temps in degF and 10ths
    }

     #Add the remarks as a supplemental attachment
     push @{ $Ob->{attachments} }, 99;
     $Ob->{ATTE} = undef;
     if(defined($Fields[9])) {
        $Ob->{SUPD} = $Fields[9];
     }
    else {
        $Ob->{SUPD} = ' ';
    }
    $Ob->write( \*STDOUT );

}

# Get a position from a port name
sub position_from_port {
    my $Name = lc(shift);
    if ( $Name =~ /wild/ ) { # Point Wild - start
        return ( -61.1, -54.9 );   
    }
    if ( $Name =~ /annenakov/ ) { 
        return ( -54.5, -37.1 );   
    }
    if ( $Name =~ /haakon/ ) { 
        return ( -54.1, -37.3 );   
    }

    return ( undef, undef );
}


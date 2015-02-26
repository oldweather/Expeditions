#!/usr/bin/perl

# Combine all Aurora records into one set of IMMA.

use strict;
use warnings;
use MarineOb::IMMA;
use MarineOb::lmrlib
  qw(rxltut ixdtnd rxnddt fxeimb fwbpgv fxtftc fxtktc ix32dd ixdcdd fxbfms fwbptc);
use Date::Calc qw(Add_Delta_Days);

my %Lats;
my %Lons;
my %Remarks;
my %Dates;
my %Obs;

my $Ship_name = 'Aurora';

open(DIN,'../as_digitised/AURORA_1914-1915_Source1.txt') or die;
while(my $Line = <DIN>) {
    chomp($Line);
    unless($Line =~ /^\s*19/) { next; }
    my @Fields = split /\t/,$Line;
    my $Date = sprintf "%04d-%02d-%02d:%04d",$Fields[0],
                $Fields[1],$Fields[2],$Fields[3];
    $Dates{$Date}=1;
    if(defined($Fields[4]) && $Fields[4] =~ /\S+/) { 
       $Lats{$Date} = $Fields[4]; 
       if($Lats{$Date} =~ /(\d+)\D(\d*)/) { $Lats{$Date} = $1+$2/60; }
       else { warn "Odd format: $Lats{$Date}"; }
       $Dates{$Date}=1;
       if(defined($Fields[6]) && $Fields[6] =~ /[Ss]/) {
	   $Lats{$Date} *= -1;
       }
    }
    if(!defined($Lats{$Date}) && defined($Fields[5]) && $Fields[5] =~ /\S+/) { 
       $Lats{$Date} = $Fields[5]; 
       if($Lats{$Date} =~ /(\d+)\D(\d*)/) { $Lats{$Date} = $1+$2/60; }
       else { warn "Odd format: $Lats{$Date}"; }
       $Dates{$Date}=1;
       if(defined($Fields[6]) && $Fields[6] =~ /[Ss]/) {
	   $Lats{$Date} *= -1;
       }
    }
    if(defined($Fields[7]) && $Fields[7] =~ /\S+/) { 
       $Lons{$Date} = $Fields[7]; 
       if($Lons{$Date} =~ /(\d+)\D(\d*)/) { $Lons{$Date} = $1+$2/60; }
       else { warn "Odd format: $Lons{$Date}"; }
       $Dates{$Date}=1;
       if(defined($Fields[9]) && $Fields[9] =~ /[Ww]/) {
	   $Lons{$Date} *= -1;
       }
    }
    if(!defined($Lats{$Date}) && defined($Fields[8]) && $Fields[8] =~ /\S+/) { 
       $Lons{$Date} = $Fields[8]; 
       if($Lons{$Date} =~ /(\d+)\D(\d*)/) { $Lons{$Date} = $1+$2/60; }
       else { warn "Odd format: $Lons{$Date}"; }
       $Dates{$Date}=1;
       if(defined($Fields[9]) && $Fields[9] =~ /[Ww]/) {
	   $Lons{$Date} *= -1;
       }
    }
    if(defined($Fields[14]) && $Fields[14] =~ /\S+/) { 
       $Remarks{$Date} .= $Fields[14]; 
       $Dates{$Date}=1;
    }
    if(defined($Fields[13]) && $Fields[13] =~ /\S+/) { 
	$Obs{$Date}{'barometer'}=$Fields[13];
    }
    if(defined($Fields[11]) && $Fields[11] =~ /\S+/) { 
	$Obs{$Date}{'attached'}=$Fields[11];
    }
    if(defined($Fields[10]) && $Fields[10] =~ /\S+/) { 
	$Obs{$Date}{'wind'}=$Fields[10];
    }
}
close(DIN);
open(DIN,'../as_digitised/AURORA_1914-1916_source2_log1+2.txt') or die;
while(my $Line = <DIN>) {
    chomp($Line);
    unless($Line =~ /^\s*19/) { next; }
    my @Fields = split /\t/,$Line;
    my $Date = sprintf "%04d-%02d-%02d:%04d",$Fields[0],
                  $Fields[1],$Fields[2],$Fields[3];
    $Dates{$Date}=1;
    if(defined($Fields[4]) && $Fields[4] =~ /\S+/) { 
       $Lats{$Date} = $Fields[4]; 
       if($Lats{$Date} =~ /(\d+)\D(\d*)/) { $Lats{$Date} = $1+$2/60; }
       else { warn "Odd format: $Lats{$Date}"; }
       $Dates{$Date}=1;
       if(defined($Fields[5]) && $Fields[5] =~ /[Ss]/) {
	   $Lats{$Date} *= -1;
       }
    }
    if(defined($Fields[6]) && $Fields[6] =~ /\S+/) { 
       $Lons{$Date} = $Fields[6]; 
       if($Lons{$Date} =~ /(\d+)\D(\d*)/) { $Lons{$Date} = $1+$2/60; }
       else { warn "Odd format: $Lons{$Date}"; }
       $Dates{$Date}=1;
       if(defined($Fields[7]) && $Fields[7] =~ /[Ww]/) {
	   $Lons{$Date} *= -1;
       }
    }
    if(defined($Fields[18]) && $Fields[18] =~ /\S+/) { 
       $Remarks{$Date} = $Fields[18]; 
       $Dates{$Date}=1;
    }
    if(defined($Fields[8]) && $Fields[8] =~ /\S+/) { 
	$Obs{$Date}{'barometer'}=$Fields[8];
    }
    if(defined($Fields[9]) && $Fields[9] =~ /\S+/) { 
	$Obs{$Date}{'attached'}=$Fields[9];
    }
    if(defined($Fields[11]) && $Fields[11] =~ /\S+/) { 
	$Obs{$Date}{'dry'}=$Fields[11];
    }
    if(defined($Fields[12]) && $Fields[12] =~ /\S+/) { 
	$Obs{$Date}{'wet'}=$Fields[12];
    }
    if(defined($Fields[15]) && $Fields[15] =~ /\S+/) { 
	$Obs{$Date}{'sea'}=$Fields[15];
    }
}
close(DIN);
open(DIN,'../as_digitised/AURORA_1914-1916_source2_log3.txt') or die;
while(my $Line = <DIN>) {
    chomp($Line);
    unless($Line =~ /^\s*19/) { next; }
    my @Fields = split /\t/,$Line;
    my $Date = sprintf "%04d-%02d-%02d:%04d",$Fields[0],
                 $Fields[1],$Fields[2],$Fields[3];
    $Dates{$Date}=1;
    if(defined($Fields[4]) && $Fields[4] =~ /\S+/) { 
       $Lats{$Date} = $Fields[4]; 
       if($Lats{$Date} =~ /(\d+)\D(\d*)/) { $Lats{$Date} = $1+$2/60; }
       else { warn "Odd format: $Lats{$Date}"; }
       $Dates{$Date}=1;
       if(defined($Fields[5]) && $Fields[5] =~ /[Ss]/) {
	   $Lats{$Date} *= -1;
       }
    }
    if(defined($Fields[6]) && $Fields[6] =~ /\S+/) { 
       $Lons{$Date} = $Fields[6]; 
       if($Lons{$Date} =~ /(\d+)\D(\d*)/) { $Lons{$Date} = $1+$2/60; }
       else { warn "Odd format: $Lons{$Date}"; }
       $Dates{$Date}=1;
       if(defined($Fields[7]) && $Fields[7] =~ /[Ww]/) {
	   $Lons{$Date} *= -1;
       }
    }
    if(defined($Fields[14]) && $Fields[14] =~ /\S+/) { 
       $Remarks{$Date} .= $Fields[14]; 
       $Dates{$Date}=1;
    }
    if(defined($Fields[8]) && $Fields[8] =~ /\S+/) { 
	$Obs{$Date}{'barometer'}=$Fields[8];
    }
    if(defined($Fields[9]) && $Fields[9] =~ /\S+/) { 
	$Obs{$Date}{'attached'}=$Fields[9];
    }
    if(defined($Fields[10]) && $Fields[10] =~ /\S+/) { 
	$Obs{$Date}{'dry'}=$Fields[10];
    }
    if(defined($Fields[11]) && $Fields[11] =~ /\S+/) { 
	$Obs{$Date}{'wind'}=$Fields[11];
    }
    if(defined($Fields[12]) && $Fields[12] =~ /\S+/) { 
	$Obs{$Date}{'force'}=$Fields[12];
    }
}
close(DIN);
open(DIN,'../as_digitised/AURORA_1914-1916_source2_log4+5.txt') or die;
while(my $Line = <DIN>) {
    chomp($Line);
    unless($Line =~ /^\s*19/) { next; }
    my @Fields = split /\t/,$Line;
    my $Date = sprintf "%04d-%02d-%02d:%04d",$Fields[0],
                  $Fields[1],$Fields[2],$Fields[3];
    $Dates{$Date}=1;
    if(defined($Fields[4]) && $Fields[4] =~ /\S+/) { 
       $Lats{$Date} = $Fields[4]; 
       if($Lats{$Date} =~ /(\d+)\D(\d*)/) { $Lats{$Date} = $1+$2/60; }
       else { warn "Odd format: $Lats{$Date}"; }
       $Dates{$Date}=1;
       if(defined($Fields[5]) && $Fields[5] =~ /[Ss]/) {
	   $Lats{$Date} *= -1;
       }
    }
    if(defined($Fields[6]) && $Fields[6] =~ /\S+/) { 
       $Lons{$Date} = $Fields[6]; 
       if($Lons{$Date} =~ /(\d+)\D(\d*)/) { $Lons{$Date} = $1+$2/60; }
       else { warn "Odd format: $Lons{$Date}"; }
       $Dates{$Date}=1;
       if(defined($Fields[7]) && $Fields[7] =~ /[Ww]/) {
	   $Lons{$Date} *= -1;
       }
    }
    if(defined($Fields[15]) && $Fields[15] =~ /\S+/) { 
       $Remarks{$Date} .= $Fields[15]; 
       $Dates{$Date}=1;
    }
    if(defined($Fields[8]) && $Fields[8] =~ /\S+/) { 
	$Obs{$Date}{'barometer'}=$Fields[8];
    }
    if(defined($Fields[9]) && $Fields[9] =~ /\S+/) { 
	$Obs{$Date}{'attached'}=$Fields[9];
    }
    if(defined($Fields[11]) && $Fields[11] =~ /\S+/) { 
	$Obs{$Date}{'dry'}=$Fields[11];
    }
    if(defined($Fields[12]) && $Fields[12] =~ /\S+/) { 
	$Obs{$Date}{'wind'}=$Fields[12];
    }
    if(defined($Fields[13]) && $Fields[13] =~ /\S+/) { 
	$Obs{$Date}{'force'}=$Fields[13];
    }
}
close(DIN);

my $Last_lon=151;
my $Last_lat=-36;

foreach my $Date (sort(keys(%Dates))) {
    unless(defined($Obs{$Date}) || defined($Remarks{$Date}) ||
           defined($Lats{$Date}) || defined($Lons{$Date})) { next; }
    my $Ob = new MarineOb::IMMA;
    $Ob->clear();                            # Why is this necessary?
    push @{ $Ob->{attachments} }, 0;
 
    $Date =~ /(\d\d\d\d)\D(\d\d)\D(\d\d)\D(\d+)/ or die "Bad date $Date";
    $Ob->{YR} = $1;
    $Ob->{MO} = $2;
    $Ob->{DY} = $3;
    if($4==2400) {
       ($Ob->{YR},$Ob->{MO},$Ob->{DY}) = Add_Delta_Days($Ob->{YR},$Ob->{MO},$Ob->{DY},1);
       $Ob->{HR}=0;
    } else {
       $Ob->{HR} = int( $4 / 100 ) + ( $4 % 100 ) / 60
    }
    if(defined($Lats{$Date})) { $Ob->{LAT} = $Lats{$Date}; }
    if(defined($Lons{$Date})) { $Ob->{LON} = $Lons{$Date}; }
    if(defined($Remarks{$Date})) { 
       my ($Lat,$Lon) = position_from_port($Remarks{$Date});
       if(!defined($Ob->{LAT}) && defined($Lat)) { $Ob->{LAT} = $Lat; }
       if(!defined($Ob->{LON}) && defined($Lon)) { $Ob->{LON} = $Lon; }
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

    # Pressure converted from inches
    if ( defined($Obs{$Date}{'barometer'})) {
        if($Obs{$Date}{'barometer'}<100) { $Ob->{SLP} = fxeimb($Obs{$Date}{'barometer'}); } # inches Hg
        else { $Ob->{SLP} = $Obs{$Date}{'barometer'}; } # hPa
    # Temperature correction
	if (   defined( $Ob->{SLP} )
	    && defined( $Obs{$Date}{'attached'} ))
	{
	    $Ob->{SLP} += fwbptc( $Ob->{SLP}, fxtftc($Obs{$Date}{'attached'}) );
	}
	else { $Ob->{SLP} = undef; }
	# Gravity correction
	if ( defined( $Ob->{SLP} ) && defined($Last_lat) ) {
	    $Ob->{SLP} += fwbpgv( $Ob->{SLP}, $Last_lat, 2 );
	}
    }

    # Temperatures converted from Farenheit
    if ( defined( $Obs{$Date}{'dry'} )) {
        $Ob->{AT} = fxtftc( $Obs{$Date}{'dry'} );
    }
    if ( defined( $Obs{$Date}{'wet'} )) {
        $Ob->{WBT} = fxtftc( $Obs{$Date}{'wet'} );
    }
    if ( defined( $Obs{$Date}{'sea'} )) {
        $Ob->{SST} = fxtftc( $Obs{$Date}{'sea'} );
    }

    # Wind direction and force
    if ( defined( $Obs{$Date}{'wind'} )) {
        my $Dirn =  $Obs{$Date}{'wind'};
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
		warn "Unknown wind direction $Dirn - $Obs{$Date}{'wind'}";
	    }
	}
    }
    if ( defined($Obs{$Date}{'force'}  ) ) {
                $Ob->{W}  = fxbfms($Obs{$Date}{'force'});    # Beaufort -> m/s
                $Ob->{WI} = 5;                 # Beaufort force
    }

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
     $Ob->{SUPD} = $Remarks{$Date};
     if(defined($Remarks{$Date})) {
        $Ob->{SUPD} = $Remarks{$Date};
     }
    else {
	$Ob->{SUPD} = ' ';
    }   

    #print "$Date ";
    $Ob->write( \*STDOUT );
}


sub position_from_port {
    my $Name = lc(shift);
    if ( $Name =~ /hobart/ ) {
        return ( -42.9, 147.3 );
    }
    if ( $Name =~ /macquarie/ ) {
        return ( -54.6, 158.9  );
    }
    if ( $Name =~ /beaufort/ ) {
        return ( -76.9, 166.9 );
    }
    if ( $Name =~ /royds/ ) {
        return ( -77.5, 166.1 );
    }
    if ( $Name =~ /cape barne/ ) {
        return ( -77.5, 166.2  );
    }
    if ( $Name =~ /cape evans/ ) {
        return ( -77.7, 166.4 );
    }
    if ( $Name =~ /hut point/ ) {
        return ( -77.8, 166.8 );
    }
    if ( $Name =~ /tent island/ ) {
        return ( -77.7, 166.4 );
    }
    if ( $Name =~ /mcmurdo/ ) {
        return ( -77.5, 166.1 );
    }
    if ( $Name =~ /nordenskjold/ ) {
        return ( -76.1, 163.1  );
    }
    if ( $Name =~ /franklin/ ) {
        return ( -76.0, 168.4 );
    }
    if ( $Name =~ /coulman/ ) {
        return ( -73.5, 169.75 );
    }
    if ( $Name =~ /adare/ ) {
        return ( -71.3, 170.2  );
    }
    if ( $Name =~ /c north/ ) {
        return ( -70.7, 165.8  );
    }
   return ( undef, undef );
}

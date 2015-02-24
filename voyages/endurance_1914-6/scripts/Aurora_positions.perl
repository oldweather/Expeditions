#!/usr/bin/perl

# Combine all Aurora position information for manual editing

use strict;
use warnings;

my %Lats;
my %Lons;
my %Remarks;
my %Dates;

open(DIN,'../as_digitised/AURORA_1914-1916_source2_log1+2.txt') or die;
while(my $Line = <DIN>) {
    chomp($Line);
    unless($Line =~ /^\s*19/) { next; }
    my @Fields = split /\t/,$Line;
    my $Date = sprintf "%04d-%02d-%02d:%02d",$Fields[0],
    $Fields[1],$Fields[2],$Fields[3];
    if(defined($Fields[4]) && $Fields[4] =~ /\S+/) { 
       $Lats{$Date} = $Fields[4]; 
       if($Lats{$Date} =~ /(\d+)\D(\d*)/) { $Lats{$Date} = $1+$2/60; }
       $Dates{$Date}=1;
       if(defined($Fields[5]) && $Fields[5] =~ /[Ss]/) {
	   $Lats{$Date} *= -1;
       }
    }
    if(defined($Fields[6]) && $Fields[6] =~ /\S+/) { 
       $Lons{$Date} = $Fields[6]; 
       if($Lons{$Date} =~ /(\d+)\D(\d*)/) { $Lons{$Date} = $1+$2/60; }
       $Dates{$Date}=1;
       if(defined($Fields[7]) && $Fields[7] =~ /[Ww]/) {
	   $Lons{$Date} *= -1;
       }
    }
    if(defined($Fields[18]) && $Fields[18] =~ /\S+/) { 
       $Remarks{$Date} = $Fields[18]; 
       $Dates{$Date}=1;
    }
}
close(DIN);
open(DIN,'../as_digitised/AURORA_1914-1916_source2_log3.txt') or die;
while(my $Line = <DIN>) {
    chomp($Line);
    unless($Line =~ /^\s*19/) { next; }
    my @Fields = split /\t/,$Line;
    my $Date = sprintf "%04d-%02d-%02d:%02d",$Fields[0],
    $Fields[1],$Fields[2],$Fields[3];
    if(defined($Fields[4]) && $Fields[4] =~ /\S+/) { 
       $Lats{$Date} = $Fields[4]; 
       if($Lats{$Date} =~ /(\d+)\D(\d*)/) { $Lats{$Date} = $1+$2/60; }
       $Dates{$Date}=1;
       if(defined($Fields[5]) && $Fields[5] =~ /[Ss]/) {
	   $Lats{$Date} *= -1;
       }
    }
    if(defined($Fields[6]) && $Fields[4] =~ /\S+/) { 
       $Lons{$Date} = $Fields[6]; 
       if($Lons{$Date} =~ /(\d+)\D(\d*)/) { $Lons{$Date} = $1+$2/60; }
       $Dates{$Date}=1;
       if(defined($Fields[7]) && $Fields[7] =~ /[Ww]/) {
	   $Lons{$Date} *= -1;
       }
    }
    if(defined($Fields[14]) && $Fields[14] =~ /\S+/) { 
       $Remarks{$Date} .= $Fields[14]; 
       $Dates{$Date}=1;
    }
}
close(DIN);
open(DIN,'../as_digitised/AURORA_1914-1916_source2_log4+5.txt') or die;
while(my $Line = <DIN>) {
    chomp($Line);
    unless($Line =~ /^\s*19/) { next; }
    my @Fields = split /\t/,$Line;
    my $Date = sprintf "%04d-%02d-%02d:%02d",$Fields[0],
    $Fields[1],$Fields[2],$Fields[3];
    if(defined($Fields[4]) && $Fields[4] =~ /\S+/) { 
       $Lats{$Date} = $Fields[4]; 
       if($Lats{$Date} =~ /(\d+)\D(\d*)/) { $Lats{$Date} = $1+$2/60; }
       $Dates{$Date}=1;
       if(defined($Fields[5]) && $Fields[5] =~ /[Ss]/) {
	   $Lats{$Date} *= -1;
       }
    }
    if(defined($Fields[6]) && $Fields[6] =~ /\S+/) { 
       $Lons{$Date} = $Fields[6]; 
       if($Lons{$Date} =~ /(\d+)\D(\d*)/) { $Lons{$Date} = $1+$2/60; }
       $Dates{$Date}=1;
       if(defined($Fields[7]) && $Fields[7] =~ /[Ww]/) {
	   $Lons{$Date} *= -1;
       }
    }
    if(defined($Fields[15]) && $Fields[15] =~ /\S+/) { 
       $Remarks{$Date} .= $Fields[15]; 
       $Dates{$Date}=1;
    }
}
close(DIN);
open(DIN,'../as_digitised/AURORA_1914-1916_source2_log3.txt') or die;
while(my $Line = <DIN>) {
    chomp($Line);
    unless($Line =~ /^\s*19/) { next; }
    my @Fields = split /\t/,$Line;
    my $Date = sprintf "%04d-%02d-%02d:%02d",$Fields[0],
    $Fields[1],$Fields[2],$Fields[3];
    if(defined($Fields[4]) && $Fields[4] =~ /\S+/) { 
       $Lats{$Date} = $Fields[4]; 
       if($Lats{$Date} =~ /(\d+)\D(\d*)/) { $Lats{$Date} = $1+$2/60; }
       $Dates{$Date}=1;
       if(defined($Fields[5]) && $Fields[5] =~ /[Ss]/) {
	   $Lats{$Date} *= -1;
       }
    }
    if(defined($Fields[6]) && $Fields[6] =~ /\S+/) { 
       $Lons{$Date} = $Fields[6]; 
       if($Lons{$Date} =~ /(\d+)\D(\d*)/) { $Lons{$Date} = $1+$2/60; }
       $Dates{$Date}=1;
       if(defined($Fields[7]) && $Fields[7] =~ /[Ww]/) {
	   $Lons{$Date} *= -1;
       }
    }
    if(defined($Fields[15]) && $Fields[15] =~ /\S+/) { 
       $Remarks{$Date} .= $Fields[15]; 
       $Dates{$Date}=1;
    }
}
close(DIN);
open(DIN,'../as_digitised/AURORA_1914-1915_Source1.txt') or die;
while(my $Line = <DIN>) {
    chomp($Line);
    unless($Line =~ /^\s*19/) { next; }
    my @Fields = split /\t/,$Line;
    my $Date = sprintf "%04d-%02d-%02d:%02d",$Fields[0],
    $Fields[1],$Fields[2],$Fields[3];
    if(defined($Fields[4]) && $Fields[4] =~ /\S+/) { 
       $Lats{$Date} = $Fields[4]; 
       if($Lats{$Date} =~ /(\d+)\D(\d*)/) { $Lats{$Date} = $1+$2/60; }
       $Dates{$Date}=1;
       if(defined($Fields[6]) && $Fields[6] =~ /[Ss]/) {
	   $Lats{$Date} *= -1;
       }
    }
    if(!defined($Lats{$Date}) && defined($Fields[5]) && $Fields[5] =~ /\S+/) { 
       $Lats{$Date} = $Fields[5]; 
       if($Lats{$Date} =~ /(\d+)\D(\d*)/) { $Lats{$Date} = $1+$2/60; }
       $Dates{$Date}=1;
       if(defined($Fields[6]) && $Fields[6] =~ /[Ss]/) {
	   $Lats{$Date} *= -1;
       }
    }
    if(defined($Fields[7]) && $Fields[7] =~ /\S+/) { 
       $Lons{$Date} = $Fields[7]; 
       if($Lons{$Date} =~ /(\d+)\D(\d*)/) { $Lons{$Date} = $1+$2/60; }
       $Dates{$Date}=1;
       if(defined($Fields[9]) && $Fields[9] =~ /[Ww]/) {
	   $Lons{$Date} *= -1;
       }
    }
    if(!defined($Lats{$Date}) && defined($Fields[8]) && $Fields[8] =~ /\S+/) { 
       $Lons{$Date} = $Fields[8]; 
       if($Lons{$Date} =~ /(\d+)\D(\d*)/) { $Lons{$Date} = $1+$2/60; }
       $Dates{$Date}=1;
       if(defined($Fields[9]) && $Fields[9] =~ /[Ww]/) {
	   $Lons{$Date} *= -1;
       }
    }
    if(defined($Fields[14]) && $Fields[14] =~ /\S+/) { 
       $Remarks{$Date} .= $Fields[14]; 
       $Dates{$Date}=1;
    }
}
close(DIN);

foreach my $Date (sort(keys(%Dates))) {
    print "$Date\t";
    if(defined($Lats{$Date})) { printf "%6.2f\t",$Lats{$Date}; }
    else { print "    NA\t"; }
    if(defined($Lons{$Date})) { printf "%6.2f\t",$Lons{$Date}; }
    else { print "    NA\t"; }
    if(defined($Remarks{$Date})) { 
       my ($Lat,$Lon) = position_from_port($Remarks{$Date});
       if(defined($Lat)) { printf "%6.2f\t",$Lat; }
       else { print "    NA\t"; }
       if(defined($Lon)) { printf "%6.2f\t",$Lon; }
       else { print "    NA\t"; }
       printf "%s\n",$Remarks{$Date};
    }
    else { print "    NA\t    NA\tNA\n"; }
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

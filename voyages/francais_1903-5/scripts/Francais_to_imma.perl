#!/usr/bin/perl

# Process digitised logbook data from the Francais into
#  IMMA records.

use strict;
use warnings;
use MarineOb::IMMA;
use MarineOb::lmrlib
  qw(fxmmmb rxltut ixdtnd rxnddt fxeimb fwbpgv fxtftc 
     fxtktc ix32dd ixdcdd fxbfms fwbptc);
use FindBin;
use Date::Calc qw(Delta_Days Add_Delta_Days);

my $Ship_name = 'Francais ';
my ( $Year, $Month, $Day );
my $Last_lon=51;
my $Last_lat=-3;
my $Lat_flag = 'N';
my $Lon_flag = 'W';

# Read in the positions
my %Positions;
open(DIN,"../as_digitised/Positions.txt") or die;
while(my $Line = <DIN>) {
    unless($Line =~ /^\d/) { next; }
    my @Fields = split /\t/,$Line;
   my $Date = $Fields[0];
   $Date =~ /(\d+)\-(.+)\-(\d+)/ or die "Bad date $Date";
   my $Year = $3+1900;
   my $Day = $1;
   my $Month = $2;
   if($Month eq 'Jan') { $Month=1; }
   if($Month eq 'Feb') { $Month=2; }
   if($Month eq 'Mar') { $Month=3; }
   if($Month eq 'Dec') { $Month=12; }
   my $Lat = $Fields[1];
    if($Lat =~ /\w/) {
      if($Lat =~ /(\d+).(\d+)/) {
         $Lat = ($1+$2/60)*-1;
      } elsif($Lat =~ /(\d+)\D/) {
	  $Lat = $1*-1;
      } else {
         die "Bad Lat $Lat";
      }
    }
   my $Lon = $Fields[2];
    if($Lon =~ /\w/) {
      if($Lon =~ /(\d+).(\d+)/) {
         $Lon = ($1+$2/60)*-1;
      } elsif($Lon =~ /(\d+)\D/) {
	  $Lon = $1*-1;
      } else {
         die "Bad Lon $Lon";
      }
    }
   my $Dstring = sprintf("%04d-%02d-%02d",$Year,$Month,$Day);
   $Positions{$Dstring}{'Lat'} = $Lat;
   $Positions{$Dstring}{'Lon'} = $Lon;
}
close(DIN);
# Add the port locations
my @Dt=(1904,2,7);
while(Delta_Days(@Dt,1904,2,19)>=0) {
   my $Dstring = sprintf("%04d-%02d-%02d",$Dt[0],$Dt[1],$Dt[2]);
   $Positions{$Dstring} = $Positions{'1904-02-07'};
   @Dt=Add_Delta_Days(@Dt,1)
}
$Positions{'1904-02-24'} = $Positions{'1904-02-23'};
@Dt=(1904,3,4);
while(Delta_Days(@Dt,1904,12,25)>=0) {
   my $Dstring = sprintf("%04d-%02d-%02d",$Dt[0],$Dt[1],$Dt[2]);
   $Positions{$Dstring} = $Positions{'1904-03-04'};
   @Dt=Add_Delta_Days(@Dt,1)
}
while(Delta_Days(@Dt,1905,1,4)>=0) {
   my $Dstring = sprintf("%04d-%02d-%02d",$Dt[0],$Dt[1],$Dt[2]);
   $Positions{$Dstring} = $Positions{'1904-12-26'};
   @Dt=Add_Delta_Days(@Dt,1)
}
@Dt=(1905,1,30);
while(Delta_Days(@Dt,1905,2,10)>=0) {
   my $Dstring = sprintf("%04d-%02d-%02d",$Dt[0],$Dt[1],$Dt[2]);
   $Positions{$Dstring} = $Positions{'1905-01-29'};
   @Dt=Add_Delta_Days(@Dt,1)
}

# Read in the pressures
my %Pressures;
open(DIN,"../as_digitised/Pressures.txt") or die;
while(my $Line = <DIN>) {
    unless($Line =~ /^\d/) { next; }
    my @Fields = split /\t/,$Line;
   my $Date = $Fields[0];
   $Date =~ /(\d+)\-(.+)\-(\d+)/ or die "Bad date $Date";
   my $Year = $3+1900;
   my $Day = $1;
   my $Month = $2;
   if($Month eq 'Jan') { $Month=1; }
   if($Month eq 'Feb') { $Month=2; }
   if($Month eq 'Mar') { $Month=3; }
   if($Month eq 'Apr') { $Month=4; }
   if($Month eq 'May') { $Month=5; }
   if($Month eq 'Jun') { $Month=6; }
   if($Month eq 'Jul') { $Month=7; }
   if($Month eq 'Aug') { $Month=8; }
   if($Month eq 'Sep') { $Month=9; }
   if($Month eq 'Oct') { $Month=10; }
   if($Month eq 'Nov') { $Month=11; }
   if($Month eq 'Dec') { $Month=12; }
   my $Dstring = sprintf("%04d-%02d-%02d",$Year,$Month,$Day);
   $Pressures{$Dstring} = \@Fields;
}
close(DIN);

# Make Hourly obs of pressure with positions at noon.
@Dt=(1904,2,1);
while(Delta_Days(@Dt,1905,1,31)>=0) {
   my $Dstring = sprintf("%04d-%02d-%02d",$Dt[0],$Dt[1],$Dt[2]);

   for(my $Hour=1;$Hour<=23;$Hour++) { # Midnight observations are missing

	my $Ob = new MarineOb::IMMA;
	$Ob->clear();                            # Why is this necessary?
	push @{ $Ob->{attachments} }, 0;
        $Ob->{ID} = $Ship_name;
	$Ob->{YR} = $Dt[0];
	$Ob->{MO} = $Dt[1];
	$Ob->{DY} = $Dt[2];
	$Ob->{HR} = $Hour;  
	# Convert ob date and time to UTC
	my $elon = $Positions{$Dstring}{'Lon'};
	if ( $elon < 0 ) { $elon += 360; }
	my ( $uhr, $udy ) = rxltut(
	    $Ob->{HR} * 100,
	    ixdtnd( $Ob->{DY}, $Ob->{MO}, $Ob->{YR} ),
	    $elon * 100
	);
	$Ob->{HR} = $uhr / 100;
	( $Ob->{DY}, $Ob->{MO}, $Ob->{YR} ) = rxnddt($udy);

	# If it's noon, add the position
	if($Hour==12) {
	   $Ob->{LAT}=$Positions{$Dstring}{'Lat'};
	   $Ob->{LON}=$Positions{$Dstring}{'Lon'};
	   $Ob->{LI} = 4;    # Deg+Min position precision
	}

	# Add the pressures, converted from mmHg to hPa
	$Ob->{SLP} = fxmmmb($Pressures{$Dstring}->[$Hour]);

	# Output the result
	$Ob->write( \*STDOUT );
   }
   @Dt=Add_Delta_Days(@Dt,1)
}



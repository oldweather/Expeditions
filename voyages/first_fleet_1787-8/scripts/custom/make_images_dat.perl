#!/usr/bin/perl 

# Make pentad images from HadISST SST normals

use strict;
use warnings;
use PP;
use Numeric::climint;
use FindBin;
use GD;

# Read in Monthly files
my @Monthly;
my $Din;
open( $Din,
    "/ibackup/cr1/hadobs/OBS/marine/MOHMAT/norms/MOHMATD41_pn1dg6190.pp"
) or die "Can't open HadISST file";
for ( my $i = 0 ; $i < 73 ; $i++ ) {
    push @Monthly, pp_read($Din);
}
close($Din);

# Subset of the world 50S to 60N, -70 to 160 E
my $Width  = 230;
my $W_off  = 110;
my $Height = 100;
my $H_off  = 40;    # Top to bottom

# Convert data to plain array and interpolate to pentads
my @Interpolated;
for ( my $i = 0 ; $i < $Monthly[0]->{lbrow} ; $i++ ) {
    if ( $i < $H_off || $i > $H_off + $Height ) { next; }
    for ( my $j = 0 ; $j < $Monthly[0]->{lbnpt} ; $j++ ) {
        if ( $j < $W_off || $j > $W_off + $Width ) { next; }
        if ( $Monthly[0]->{data}->[$i][$j] == $Monthly[0]->{bmdi} ) { next; }
        my @Mtmp;
        for ( my $m = 0 ; $m < 73 ; $m++ ) {
            $Mtmp[$m] = $Monthly[$m]->{data}->[$i][$j];
        }
        $Interpolated[ $i ][ $j ] = [@Mtmp];
    }
}

# Make the images
my @Scheme = get_CP_BR();

for ( my $Day = 0 ; $Day < 73 ; $Day++ ) {
    my $im = new GD::Image( $Width * 2, $Height * 2 );

    # Make the colours
    my @Colours;
    for ( my $i = 0 ; $i < scalar(@Scheme) ; $i++ ) {
        $Colours[$i] = $im->colorAllocateAlpha( @{ $Scheme[$i] } );
    }

    # Transparent background
    my $white = $im->colorAllocateAlpha( 255, 255, 255, 127 );
    $im->transparent($white);

    # Find the data, lat and long ranges in the field
    my $Min = 0;
    my $Max = 30;

    # Fill by pixels - simple but will only work for constant grids
    for ( my $i = 0 ; $i < $Height ; $i++ ) {
        for ( my $j = 0 ; $j < $Width ; $j++ ) {

            $im->setPixel( $j * 2,     $i * 2,     $white );
            $im->setPixel( $j * 2 + 1, $i * 2,     $white );
            $im->setPixel( $j * 2,     $i * 2 + 1, $white );
            $im->setPixel( $j * 2 + 1, $i * 2 + 1, $white );

            if ( !defined( $Interpolated[ $i + $H_off ][ $j + $W_off ][$Day] )
                || $Interpolated[ $i + $H_off ][ $j + $W_off ][$Day] < $Min )
            {
                next;
            }
            if ( $Interpolated[ $i + $H_off ][ $j + $W_off ][$Day] > $Max ) {
                $Interpolated[ $i + $H_off ][ $j + $W_off ][$Day] = $Max;
            }

            my $Index =
              ( $Interpolated[ $i + $H_off ][ $j + $W_off ][$Day] - $Min ) /
              ( $Max - $Min );
            $Index = int( $Index * scalar(@Scheme) + 0.5 );
            if ( $Index > scalar(@Scheme) - 1 ) {
                $Index = scalar(@Scheme) - 1;
            }
            if ( $Index < 0 ) { $Index = 0; }

            $im->setPixel( $j * 2,     $i * 2,     $Colours[$Index] );
            $im->setPixel( $j * 2 + 1, $i * 2,     $Colours[$Index] );
            $im->setPixel( $j * 2,     $i * 2 + 1, $Colours[$Index] );
            $im->setPixel( $j * 2 + 1, $i * 2 + 1, $Colours[$Index] );

        }
    }

    # Output the image as a PNG
    my $Dout;
    my $Fname = sprintf "%s/../kml/images/DAT_%03d.png", $FindBin::Bin, $Day;
    open( $Dout, ">$Fname" ) or die "Can't open $Fname";
    print $Dout $im->png;
}

# Use the Light and Bartlein diverging red-blue colour scheme
sub get_CP_BR {

    my @Scheme = (
        [ 36,  0,   216, 0 ],
        [ 24,  28,  247, 0 ],
        [ 40,  87,  255, 0 ],
        [ 61,  135, 255, 0 ],
        [ 86,  176, 255, 0 ],
        [ 117, 211, 255, 0 ],
        [ 153, 234, 255, 0 ],
        [ 188, 249, 255, 0 ],
        [ 234, 255, 255, 0 ],
        [ 255, 255, 234, 0 ],
        [ 255, 241, 188, 0 ],
        [ 255, 214, 153, 0 ],
        [ 255, 172, 117, 0 ],
        [ 255, 120, 86,  0 ],
        [ 255, 61,  61,  0 ],
        [ 247, 39,  53,  0 ],
        [ 216, 21,  47,  0 ],
        [ 165, 0,   33,  0 ]
    );

    return @Scheme;
}

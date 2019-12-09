"""
version 0.2 
  - 4/9/2019 corrected time_date2julianday 
=============================================================================
 Comprehensive Ocean-Atmosphere Data Set (COADS):                  Python Code 
 Python translation of Scott Woodruff and Sandy Lubker' lmrlib Fortran library
       See http://icoads.noaa.gov/software/lmrlib

 Comments are preserved from the original. 

 Function: Tools to assist conversions into LMR6   
=============================================================================

 Functionality:  This is a library of tools to assist conversions from other
 formats into LMR6, whose functions are individually described in the comments
 at the beginning of each function. 
 
 Contents:  Following are the routines included, and their broader groupings:
      barometric conversions:
           {baro_mm2mb}     millimeters Hg to millibars
           {baro_mb2mm}     millibars to millimeters Hg
           {baro_Eng_in2mb}     inches (English) Hg to millibars
           {baro_mb2Eng_in}     millibars to inches (English) Hg
           {baro_Fr_in2mb}     inches (French) Hg to millibars
           {baro_mb2Fr_in}     millibars to inches (French) Hg, plus
                        entry points {fxfim0,fxfim1} used by {tpbpfi}
           {baro_tempF_correction}     correction value for temperature (Fahrenheit)
           {baro_tempC_correction}     correction value for temperature (Celsius)
           {baro_temp_correction}     correction value for temperature (generalized)
           {baro_G_correction}     correction value for gravity
      cloud conversions:
           {cloud_tenthsclear2oktas}     tenths (of sky clear  ) to oktas (of sky covered)
           {cloud_tenthscovered2oktas}     tenths (of sky covered) to oktas (of sky covered)
      temperature conversions:
           {temp_f2c}     Fahrenheit to Celsius
           {temp_c2f}     Celsius to Fahrenheit
           {temp_k2c}     Kelvins to Celsius
           {temp_c2k}     Celsius to Kelvins
           {temp_r2c}     Reaumur to Celsius
           {temp_c2r}     Celsius to Reaumur
      wind conversions:
           {wind_uv2dir}     vector (u,v) components to direction (degrees)
           {wind_uv2vel}     vector (u,v) components to velocity
           {wind_kts2mps}     knots to m/s (ref. international nautical mile)
           {wind_mps2kts}     m/s to knots (ref. international nautical mile)
           {wind_us_kts2mps}     knots to m/s (ref. US nautical mile)
           {wind_mps2us_kts}     m/s to knots (ref. US nautical mile)
           {wind_a_kts2mps}     knots to m/s (ref. Admiralty nautical mile)
           {wind_mps2a_kts}     m/s to knots (ref. Admiralty nautical mile)
           {wind_Beaufort2kts}     0-12 Beaufort number to knots (WMO code 1100)
           {wind_Beaufort2mps}     0-12 Beaufort number to m/s (WMO code 1100)
           {wind_4chardir2deg}     32-point direction abbreviation into code and degrees
           {wind_dircode2deg}     32-point direction code into degrees
      time conversions:
           {time_local_hour_julianday2UTC}     local standard hour and "Julian" day into UTC
           {time_date2julianday}     date to days ("Julian") since 1 Jan 1770
           {time_julianday2date}     days ("Julian") since 1 Jan 1770 to date
      miscellaneous:
           {print_epsilon}     print machine epsilon
           {print_dblepsilon}     double precision version of {print_epsilon}
           {round}     round to nearest even integer
 Machine dependencies:  None known.
-----------------------------------------------------------------------
"""
import sys
import math
from datetime import date, timedelta
import calendar
import numpy as np

#=============================================================================
# WARNING:  Code beyond this point should not require any modification.       
#=============================================================================
#--Barometric conversions-----------------------------------------------------
#=============================================================================
#-----Convert barometric pressure in (standard) millimeters of mercury (mm)
#     to millibars (hPa), e.g., baro_mm2mb(760.) = 1013.25 (one atmosphere)
#     (List, 1966, p. 13).
#     References:
#     List, R.J., 1966: Smithsonian Meteorological Tables.
#           Smithsonian Institution, Washington, DC, 527 pp.
#     WMO (World Meteorological Organization), 1966: International
#           Meteorological Tables, WMO-No.188.TP.94.
#-----factor from List (1966), p. 13 and Table 11; also in WMO (1966).
def baro_mm2mb(mm):
    baro_mm2mb = mm * 1.333224
    return baro_mm2mb

#=============================================================================
#-----Convert barometric pressure in millibars (hPa; mb) to (standard)
#     millimeters of mercury.  Numerical inverse of {baro_mm2mb} (see for
#     background).  Note: This method yields better numerical agreement
#     in cross-testing against that routine than the factor 0.750062.
def baro_mb2mm(mb):
    baro_mb2mm = mb / 1.333224
    return fxbmm

#=============================================================================
#-----Convert barometric pressure in (standard) inches (English) of
#     mercury (in) to millibars (hPa), e.g., baro_Eng_in2mb(29.9213) = 1013.25
#     (one atmosphere) (List, 1966, p. 13).
#     References:
#     List, R.J., 1966: Smithsonian Meteorological Tables.
#           Smithsonian Institution, Washington, DC, 527 pp.
#     WMO (World Meteorological Organization), 1966: International
#           Meteorological Tables, WMO-No.188.TP.94.
#-----factor from List (1966), Table 9.  Note: a slightly different factor 
#     33.8639 appears also on p. 13 of List (1966), and in WMO (1966).  Tests 
#     (32-bit Sun f77) over a wide range of pressure values (25.69"-31.73",
#     approximately equivalent to ~870-1074.6 mb) indicated that the choice
#     of constant made no numeric difference when data were converted to mb
#     and then rounded to tenths, except for two cases of 0.1 mb difference
#     (25.79" = 873.3/.4 mb; and 26.23" = 888.2/.3 mb).  If 1 mm = 1.333224
#     mb and 1" = 25.4 mm, then 25.4mm = 33.86389 to 7 significant digits.
def baro_Eng_in2mb(ei):
    baro_Eng_in2mb = ei * 33.86389
    return baro_Eng_in2mb

#=============================================================================
#-----Convert barometric pressure in millibars (hPa; mb) to (standard)
#     inches (English) of mercury.  Numerical inverse of {baro_Eng_in2mb} (see for
#     background).  Note: This method yields better numerical agreement
#     in cross-testing against that routine than the factor 0.0295300.
def baro_mb2Eng_in(mb):
    baro_mb2Eng_in = mb / 33.86389
    return baro_mb2Eng_in
#=============================================================================
#-----Convert barometric pressure in inches (French) of mercury (fi) to
#     millibars (hPa).  Paris, instead of French, inches are referred
#     to in Lamb (1986), but these appear to be equivalent units.  Note:
#     data in lines (twelve lines per inch) or in inches and lines need
#     to be converted to inches (plus any decimal fraction).  Entry points
#     {fxfim0,fxfim1}, which are called by {tpbpfi} (see for background)
#     are not recommended for use in place of {baro_Fr_in2mb}.
#     References:
#     IMC (International Meteorological Committee), 1890: International
#           Meteorological Tables, published in Conformity with a Resolution
#           of the Congress of Rome, 1879.  Gauthier-Villars et Fils, Paris.
#     Lamb, H.H., 1986: Ancient units used by the pioneers of meteorological
#           instruments.  Weather, 41, 230-233.
#-----factor for conversion of French inches to mm (IMC, 1890, p. B.2);
#     mm are then converted to mb via {baro_mm2mb}
def baro_Fr_in2mb(fi):
    baro_Fr_in2mb = baro_mm2mb(fi * 27.069953)
    return baro_Fr_in2mb

#=============================================================================
#-----Convert barometric pressure in millibars (hPa; mb) to inches (French)
#     of mercury.  Numerical inverse of {baro_Fr_in2mb} (see for background).
def baro_mb2Fr_in(mb):
    baro_mb2Fr_in = baro_mb2mm(mb) / 27.069953
    return baro_mb2Fr_in

#=============================================================================
#-----Correction value of barometric pressure (in mm or mb; standard
#     temperature of scale 0C) (bp) for temperature in Celsius (tc)
#     (see {fwbpgt} for additional background).
#     Reference:
#     List, R.J., 1966: Smithsonian Meteorological Tables.
#           Smithsonian Institution, Washington, DC, 527 pp.
#-----constants m and l from List (1966), p. 136.
def baro_tempC_correction(bp,tc):
    m=0.0001818
    l=0.0000184
    baro_tempC_correction = -bp * ( ((m-l)*tc) / (1.+(m*tc)) )
    return baro_tempC_correction
#=============================================================================
#-----Correction value of barometric pressure (in inches; standard
#     temperature of scale 62F) (bp) for temperature in Fahrenheit (tf)
#     (see {fwbpgt} for additional background).
#     Reference:
#     List, R.J., 1966: Smithsonian Meteorological Tables.
#           Smithsonian Institution, Washington, DC, 527 pp.
#-----constants m and l from List (1966), p. 137.
def baro_tempF_correction(bp,tf):
    m=0.000101
    l=0.0000102
    baro_tempF_correction = -bp * ( ((m*(tf-32.))-(l*(tf-62.))) / (1.+m*(tf-32.)) )
    return baro_tempF_correction
#=============================================================================
#-----Correction value (generalized) of barometric pressure (bp) for
#     temperature (t), depending on units (u):
#                                          standard temperature:
#          u  bp          t           of scale (ts)  of mercury (th)
#          -  ----------  ----------  -------------  -------------------
#          1  mm or mb    Celsius      0C             0C
#          2  Eng. in.    Fahrenheit  62F (16.667C)  32F (0C) (pre-1955)    
#          3  Eng. in.    Fahrenheit  32F (0C)       32F (0C) (1955-)
#          4  French in.  Reaumur     13R (16.25C)    0R (0C)
#     The returned {baro_temp_correction} value is in the same units as, and is to be
#     added to, bp.  Establishment of 0C/32F as the standard temperature
#     for both scale and mercury as implemented under u=1 and 3 became
#     effective 1 Jan 1955 under WMO International Barometer Conventions
#     (WBAN, 12 App.1.4.1--2; see also WMO, 1966 and UKMO, 1969).  List
#     (1966), p. 139 states that "the freezing point of water is universally
#     adopted as the standard temperature of the mercury, to which all
#     readings are to be reduced," but for English units uses only 62F for
#     the standard temperature of the scale.  Note: Results under u=4, and
#     the utilized settings of constants l and m, have not been verified
#     against published values, if available.  IMC (1890, p. B.24) states
#     that in "old Russian barometer readings expressed in English half lines
#     (0.05 in) the mercury and the scale were set to the same temperature
#     62F."  UKMO (1969, p. 5) states that for Met. Office barometers prior
#     to 1955 reading in millibars the standard temperature was 285K (12C).
#     This routine does not handle these, or likely other historical cases.
#     References:
#     IMC (International Meteorological Committee), 1890: International
#           Meteorological Tables, published in Conformity with a Resolution
#           of the Congress of Rome, 1879.  Gauthier-Villars et Fils, Paris.
#     List, R.J., 1966: Smithsonian Meteorological Tables.
#           Smithsonian Institution, Washington, DC, 527 pp.
#     UKMO (UK Met. Office), 1969: Marine Observer's Handbook (9th ed.).
#           HMSO, London, 152 pp.
#     US Weather Bureau, Air Weather Service, and Naval Weather Service,
#           1963: Federal Meteorological Handbook No. 8--Manual of Barometry
#           (WBAN), Volume 1 (1st ed.).  US GPO, Washington, DC.
#     WMO (World Meteorological Organization), 1966: International
#           Meteorological Tables, WMO-No.188.TP.94.
#-----constants ts and th are from List (1966), pp. 136-137 (u=1-2); WBAN
#     12 App.1.4.1--3 (u=3); and IMC (1890), p. B.24 (u=4).
def baro_temp_correction(bp,t,u):
    tsList=[0.0,62.,32.,13.]
    thList=[0.0,32.,32.,0.0]
#-----constants m and l are from List (1966), pp. 136-137 (u=1-3) and WBAN,
#     pp. 5-4 and 5-5 (for metric and English units).  For u=4, the u=1
#     constants were multiplied by 5/4 (after List, 1966, p. 137).
    mList=[0.0001818, 0.000101, 0.000101, 0.000227]
    lList=[0.0000184,0.0000102,0.0000102,0.0000230]
#-----test u for valid range
    if u < 1 or u > 4:
       sys.exit("baro_temp_correction error: invalid u")

    baro_temp_correction = -bp * ( ((mList[u]*(t-thList[u]))-(lList[u]*(t-tsList[u]))) /
                   (1.+(mList[u]*(t-thList[u]))) )
    return baro_temp_correction
#=============================================================================
#-----Correction value of barometric pressure (bp) for gravity depending on
#     latitude (rlat), with constants set depending on gmode (for COADS, we
#     adopt gmode=1 for 1955-forward, and gmode=2 for data prior to 1955):
#           g1 (equation 1)   g2 (equation 2)   Comment
#           ---------------   ---------------   -----------------------------
#     1 =          g45               g0         yields List (1966), Table 47B
#     2 =          g0                g0         follows GRAVCOR (pre-1955)
#     3 =          g45               g45        (of unknown utility)
#     The returned {baro_G_correction} value is in the same units as, and is to be added
#     to, bp (units for bp are unspecified; Table 47B has columns for inches,
#     millimeters, and millibars).  Usage of g0 and g45 as implemented under
#     gmode=1 became effective 1 Jan 1955 under WMO International Barometer
#     Conventions: g45 is a "best" estimate of acceleration of gravity at 45
#     deg latitude and sea level, and g0 is the value of standard (normal)
#     gravity "to which reported barometric data in mm or inches of mercury
#     shall refer, but it does not represent the value of gravity at latitude
#     45 deg, at sea level" (WBAN, 12 App.1.4.1--2; see also List, 1966, pp.
#     3-4, and WMO, 1966).  For example, UK Met. Office MK I (MK II) barometers
#     issued before (starting) 1 January 1955 were graduated to read correctly
#     when the value of gravity was g45 (g0) (UKMO, 1969).  As shown by test
#     routines {tpbpg1,tpbpg2}, gmode=2 and 3 yield virtually the same results.
#     References:
#     List, R.J., 1966: Smithsonian Meteorological Tables.
#           Smithsonian Institution, Washington, DC, 527 pp.
#     UKMO (UK Met. Office), 1969: Marine Observer's Handbook (9th ed.).
#           HMSO, London, 152 pp.
#     US Weather Bureau, Air Weather Service, and Naval Weather Service,
#           1963: Federal Meteorological Handbook No. 8--Manual of Barometry
#           (WBAN), Volume 1 (1st ed.).  US GPO, Washington, DC.
#     WMO (World Meteorological Organization), 1966: International
#           Meteorological Tables, WMO-No.188.TP.94.
def baro_G_correction(bp,rlat,gmode):
    pi=3.14159265358979323846264338327950288
#-----g45 from List (1966), p. 488 ("best" sea-level gravity at latitude 45)
    g45=980.616
#-----g0  from List (1966), p. 200 ("standard" acceleration of gravity)
    g0=980.665
#-----check latitude 
    if rlat < -90. or rlat > 90.:
       sys.exit("baro_G_correction error: invalid rlat")

#-----check gmode, and set g1 and g2
    if gmode == 1:
       g1 = g45
       g2 = g0
    elif gmode == 2:
       g1 = g0
       g2 = g0
    elif gmode == 3:
       g1 = g45
       g2 = g45
    else:
       sys.exit("baro_G_correction error: invalid gmode")
#-----convert degrees to radians
    rlatr  = rlat * (pi/180.)
#-----List (1966), p. 488, equation 1 (c is the local acceleration of gravity)
    a      =      0.0000059 * (math.cos(2.0*rlatr)**2)
    b      = 1. - 0.0026373 *  math.cos(2.0*rlatr)
    c      = g1 * (a + b)
#-----List (1966), p. 202, equation 2
    baro_G_correction = ((c - g2)/g2) * bp
    return baro_G_correction
#=============================================================================
#=======================================================================-------
#-----cloud conversions--------------------------------------------------------
#=======================================================================-------
#-----Convert "proportion of sky clear" in tenths (t0), to oktas (eighths
#     of sky covered; WMO code 2700).  The t0 code, specified in Maury
#     (1854), was documented for use, e.g., for US Marine Meteorological
#     Journals (1878-1893).  The dates of transition to instead reporting
#     "proportion of sky covered" (t1, as handled by {cloud_tenthscovered2oktas}) may have
#     varied nationally.  Following shows the mappings of t0/t1 to oktas
#     as provided by these routines ({tpt0t1} output):
#     10ths clear (t0)   oktas   10ths cover (t1)   oktas
#     ----------------   -----   ----------------   -----
#                   10       0                  0       0
#                    9       1                  1       1
#                    8       2                  2       2
#                    7       2                  3       2
#                    6       3                  4       3
#                    5       4                  5       4
#                    4       5                  6       5
#                    3       6                  7       6
#                    2       6                  8       6
#                    1       7                  9       7
#                    0       8                 10       8
#     Reference:
#     Maury, M.F., 1854: Maritime Conference held at Brussels for devising
#           a uniform system of meteorological observations at sea, August
#           and September, 1853.  Explanations and Sailing Directions to
#           Accompany the Wind and Current Charts, 6th Ed., Washington, DC,
#           pp. 54-88.

def cloud_tenthsclear2oktas(t0):
#-----check validity of t0
    if t0 < 0 or t0 > 10:
       sys.exit('cloud_tenthsclear2oktas error: illegal t0=',t0)
#-----convert tenths of "sky clear" (t0) to tenths of "sky covered" (t1)
#     (Note: assumption: no known basis in documentation)
    t1 = 10 - t0 
#-----convert tenths of "sky covered" to oktas
    cloud_tenthsclear2oktas = cloud_tenthscovered2oktas(t1)
    return cloud_tenthsclear2oktas

#=======================================================================-------
#-----Convert tenths (of sky covered) (t1), to oktas (eighths of sky
#     covered; WMO code 2700).  This implements the mapping of tenths
#     to oktas shown below (left-hand columns) from NCDC (1968), section
#     4.5, scale 7.  In contrast, the right-hand columns show a reverse
#     mapping of "code no." (referring to oktas in the synoptic code)
#     back to tenths from Riehl (1947) (the justifications for the two
#     approaches are not known):
#           oktas  <-  tenths     |    code no.  ->  tenths
#           -----      -------    |    --------      -------
#             0         0         |        0           0
#             1         1         |        1           0
#             2         2 or 3    |        2           1
#             3         4         |        3           2.5
#             4         5         |        4           5
#             5         6         |        5           7.5
#             6         7 or 8    |        6           9
#             7         9         |        7          10 
#             8        10         |        8          10
#             9        obscured
#     Input t1 values must be limited to 0-10; "obscured" is not handled.
#     References:
#     NCDC (National Climatic Data Center), 1968: TDF-11 Reference Manual.
#           NCDC, Asheville, NC.
#     Riehl, 1947: Diurnal variation of cloudiness over the subtropical
#           Atlantic Ocean.  Bull. Amer. Meteor. Soc., 28, 37-40.
def cloud_tenthscovered2oktas(t1):
    okList = [0,1,2,2,3,4,5,6,6,7,8]
#-----check validity of t1
    if t1 < 0 or t1 > 10:
       sys.exit("cloud_tenthscovered2oktas error: illegal t1=",t1)
#-----convert from tenths to oktas
    cloud_tenthscovered2oktas = okList[t1]
    return cloud_tenthscovered2oktas
#=======================================================================-------
#-----temperature conversions--------------------------------------------------
#=======================================================================-------
#-----Convert temperature in degrees Fahrenheit (tc) to degrees Celsius.
#     Reference:
#     List, R.J., 1966: Smithsonian Meteorological Tables.
#           Smithsonian Institution, Washington, DC, 527 pp.
#-----equation from List (1966), Table 2 (p. 17).
def temp_f2c(tf):
    temp_f2c = (5.0/9.0) * (tf - 32.0)
    return temp_f2c
#=============================================================================
#-----Convert temperature in degrees Celsius (tc) to degrees Fahrenheit.
#     Reference:
#     List, R.J., 1966: Smithsonian Meteorological Tables.
#           Smithsonian Institution, Washington, DC, 527 pp.
#-----equation from List (1966), Table 2 (p. 17).
def temp_c2f(tc):
    temp_c2f = ((9.0/5.0) * tc) + 32.0
    return temp_c2f
#=============================================================================
#-----Convert temperature in Kelvins (tk) to degrees Celsius.
#-----Adapted from colib5s.01J function {cvtkc} (1984); 
def temp_k2c(tk):
    if tk < 0.0:
       sys.exit("temp_k2c error: negative input tk=",tk)
    temp_k2c = tk - 273.15
    return temp_k2c
#=============================================================================
#-----Convert temperature in degrees Celsius (tc) to Kelvins.
#-----Adapted from colib5s.01J function {cvtck} (1984); 
def temp_c2k(tc):
    temp_c2k = tc + 273.15
    if temp_c2k < 0.0:
       sys.exit("temp_c2k error: negative output=",fxtctk)
    return temp_c2k
#=============================================================================
#-----Convert temperature in degrees Reaumur (tc) to degrees Celsius.
#     Reference:
#     List, R.J., 1966: Smithsonian Meteorological Tables.
#           Smithsonian Institution, Washington, DC, 527 pp.
#-----equation from List (1966), Table 2 (p. 17).
def temp_r2c(tr):
    temp_r2c = (5.0/4.0) * tr
    return temp_r2c
#=============================================================================
#-----Convert temperature in degrees Celsius (tc) to degrees Reaumur.
#     Reference:
#     List, R.J., 1966: Smithsonian Meteorological Tables.
#           Smithsonian Institution, Washington, DC, 527 pp.
#-----equation from List (1966), Table 2 (p. 17).
def temp_c2r(tc):
    temp_c2r = (4.0/5.0) * tc
    return temp_c2r
#=============================================================================
#=======================================================================-------
#-----wind conversions---------------------------------------------------------
#=======================================================================-------
#-----Convert wind vector eastward and northward components (u,v) to
#     direction (from) in degrees (clockwise from 0 degrees North).
#-----Adapted from colib5s.01J function {dduv} (1984); 
def wind_uv2dir(u,v):

    if u == 0.0 and v == 0.0:
       a = 0.0
    else:
       a = math.atan2(v,u)*(180.0/3.14159265358979323846264338327950288)

    wind_uv2dir = 270.0 - a

    if wind_uv2dir > 360.0:
       wind_uv2dir = fxuvdd - 360.0
    return wind_uv2dir
#=============================================================================
def wind_uv2vel(u,v):
#-----Convert wind vector eastward and northward components (u,v) to
#     velocity.
#-----Adapted from colib5s.01J function {vvuv} (1984); 
    wind_uv2vel = math.sqrt(u**2 + v**2)
    return wind_uv2vel

#=============================================================================
def wind_kts2mps(kt):
#-----Convert from knots (kt; with respect to the international nautical
#     mile) to meters per second (see {tpktms} for details).
#-----Adapted from colib5s.01J function {cvskm} (1984); 
    wind_kts2mps = kt * 0.51444444444444444444
    return wind_kts2mps

#=============================================================================
def wind_mps2kts(ms):
#-----Convert from meters per second (ms) to knots (with respect to the
#     international nautical mile) (see {tpktms} for details).
#-----Adapted from colib5s.01J function {cvsmk} (1984); 
    wind_mps2kts = ms *  1.9438444924406047516
    return wind_mps2kts

#=============================================================================
#-----Convert from knots (k0; with respect to the U.S. nautical mile) to
#     meters per second (see {tpktms} for details).
def wind_us_kts2mps(k0):
    wind_us_kts2mps = k0 * 0.51479111111111111111
    return wind_us_kts2mps

#=============================================================================
#-----Convert from meters per second (ms) to knots (with respect to the
#     U.S. nautical mile) (see {tpktms} for details).
def wind_mps2us_kts(ms):
    wind_mps2us_kts = ms *  1.9425354836481679732
    return wind_mps2us_kts

#=============================================================================
#-----Convert from knots (k1; with respect to the Admiralty nautical mile)
#     to meters per second (see {tpktms} for details).
def wind_a_kts2mps(k1):
    wind_a_kts2mps = k1 * 0.51477333333333333333
    return wind_a_kts2mps

#=============================================================================
#-----Convert from meters per second (ms) to knots (with respect to the
#     Admiralty nautical mile) (see {tpktms} for details).
def wind_mps2a_kts(ms):
    wind_mps2a_kts = ms *  1.9426025694156651471
    return wind_mps2a_kts

#=============================================================================
#-----Convert from Beaufort force 0-12 (bf) to "old" (WMO code 1100)
#     midpoint in knots.  From NCDC (1968), conversion scale 5 (sec.
#     4.4).  Note: Midpoint value 18 looks questionable, but appeared
#     originally in UKMO (1948).
#     References:
#     NCDC (National Climatic Data Center), 1968: TDF-11 Reference Manual.
#           NCDC, Asheville, NC.
#     UKMO (UK Met. Office), 1948: International Meteorological Code
#           Adopted by the International Meteorological Organisation,
#           Washington, 1947 (Decode for the Use of Shipping, effective
#           from 1st January, 1949).  Air Ministry, Meteorological Office,
#           HM Stationary Office, London, 39 pp.
def wind_Beaufort2kts(bf):
    ktList = [0,2,5,9,13,18,24,30,37,44,52,60,68]

    if bf < 0 or bf > 12:
       sys.exit("wind_Beaufort2kts error:  bf=",bf)
    wind_Beaufort2kts = ktList[bf]
    return wind_Beaufort2kts
#=============================================================================
#-----Convert from Beaufort force 0-12 (bf) to "old" (WMO code 1100)
#     midpoint in meters per second.  From Slutz et al. (1985) supp.
#     K, Table K5-5 (p. K29).  See {wind_Beaufort2kts} for additional background.
#     Reference:
#     Slutz, R.J., S.J. Lubker, J.D. Hiscox, S.D. Woodruff, R.L. Jenne,
#           D.H. Joseph, P.M. Steurer, and J.D. Elms, 1985: Comprehensive
#           Ocean-Atmosphere Data Data Set; Release 1.  NOAA
#           Environmental Research Laboratories, Climate Research
#           Program, Boulder, Colo., 268 pp. (NTIS PB86-105723).
def wind_Beaufort2mps(bf):
    msList = [0.,1.,2.6,4.6,6.7,9.3,12.3,15.4,19.,22.6,26.8,30.9,35.]
    if bf < 0 or bf > 12:
       sys.exit("wind_Beaufort2mps error:  bf=",bf)
    wind_Beaufort2mps = msList[bf]
    return wind_Beaufort2mps

#=============================================================================
#-----Convert 4-character 32-point wind direction abbreviation c32 into
#     degrees, or return imiss if unrecognized; also return numeric code
#     1-32 (or imiss) in dc (see {wind_dircode2deg} for background).  Recognized
#     abbreviations are in cwd, with these characteristics: left-justified,
#     upper-case, with trailing blank fill, and where "X" stands for "by".
#     NOTE: No constraint is placed on imiss (it could overlap with data).
def wind_4chardir2deg(c32,dc,imiss):
    cwdList = ['NXE ','NNE ','NEXN','NE  ','NEXE','ENE ','EXN ','E   ',
               'EXS ','ESE ','SEXE','SE  ','SEXS','SSE ','SXE ','S   ',
               'SXW ','SSW ','SWXS','SW  ','SWXW','WSW ','WXS ','W   ',
               'WXN ','WNW ','NWXW','NW  ','NWXN','NNW ','NXW ','N   ']
    wind_4chardir2deg = imiss
    for j in range(1,32):
       if c32 == cwdList[j]:
          wind_4chardir2deg = wind_dircode2deg(j,imiss)
          dc     = j
          return wind_4chardir2deg
    return wind_4chardir2deg
#=============================================================================
#-----Convert 32-point wind direction numeric code dc into degrees, or
#     return imiss if dc is out of range 1-32.  Release 1, Table F2-1
#     defines the mapping of code dc to degrees in dwd.
#     NOTE: No constraint is placed on imiss (it could overlap with data).
def wind_dircode2deg(dc,imiss):
    dwdList = [ 11,    23,    34,    45,    56,    68,    79,    90,
               101,   113,   124,   135,   146,   158,   169,   180,
               191,   203,   214,   225,   236,   248,   259,   270,
               281,   293,   304,   315,   326,   338,   349,   360]
    if dc >= 1 and dc<= 32:
       wind_dircode2deg = dwdList[dc]
    else:
       wind_dircode2deg = imiss
    return wind_dircode2deg
#=============================================================================
#=======================================================================-------
#-----time conversions---------------------------------------------------------
#=======================================================================-------
#ckm def square(x,y):
#ckm     return x*x, y*y
#ckm
#ckm xsq, ysq = square(2,3)
#ckm print(xsq)  # Prints 4
#ckm print(ysq)  # Prints 9  

#-----Convert local standard hour (ihr; in hundredths 0-2399) and "Julian"
#     day (i.e., any incrementable integer date) (idy) into coordinated
#     universal time (UTC) hour (uhr) and day (udy; decremented if the
#     dateline is crossed), using longitude (elon; in hundredths of degrees
#     0-35999, measured east of Greenwich).  Notes: a) Strict time zones,
#     including the International Date Line, are not employed.  b) In all
#     cases the western (eastern) boundary of each time zone is inclusive
#     (exclusive), i.e., 7.50W-7.49E, 7.50E-22.49E, ..., 172.50E-172.51W.
def time_local_hour_julianday2UTC(ihr,idy,elon):#,uhr,udy):

    if ihr < 0 or ihr > 2399:
       sys.exit("error time_local_hour_julianday2UTC: ihr=",ihr)
    elif elon < 0 or elon > 35999:
       sys.exit("error time_local_hour_julianday2UTC: elon=",elon)

    wlon = 36000 - elon
    udy = idy
    dhr = (wlon + 749)//1500
    uhr = ihr + dhr*100
    if uhr >= 2400:
       udy = udy + 1
       uhr = uhr - 2400
    if wlon >= 18000:
       udy = udy - 1

    return uhr,udy

#=============================================================================
#-----Convert from date (iday,imonth,iyear) to number of days since
#     1 Jan 1770.
def time_date2julianday(iday,imonth,iyear):
    daysList = [31,28,31,30,31,30,31,31,30,31,30,31]

    if (iyear < 1770 or imonth < 1 or imonth > 12
       or iday < 1 or  iday > daysList[imonth-1]
       and (imonth != 2 or not calendar.isleap(iyear) or iday != 29)):

       sys.exit("time_date2julianday: invalid day,month,year")

    start = date(1770,1,1)
    end = date(iyear,imonth,iday)

    delta_time = end - start

    time_date2julianday = delta_time.days

    return time_date2julianday 

#=============================================================================
#-----Convert from number of days (ndays) since 1 Jan 1770 to
#     date (iday,imonth,iyear).
#     iday=-1, imonth=-1, and iyear=-1 if ndays is invalid.
def time_julianday2date(ndays):

    start = date(1770,1,1)
    delta = timedelta(ndays)
    offset = start + delta

    iday = '{0.day:02d}'.format(offset)
    imonth = '{0.month:02d}'.format(offset) 
    iyear = '{0.year:04d}'.format(offset) 

    return iday,imonth,iyear

#=============================================================================
#-----miscellaneous------------------------------------------------------------
#=============================================================================
def print_epsilon():
#-----Print calculated machine epsilon, i.e., the smallest power of 2,
#     2**no = ep, such that 1+2**no>1
    print("print_epsilon output:",np.finfo(float32).eps)
    return

#=============================================================================
def print_dblepsilon():
#-----Double precision version of {print_epsilon} (see for background).
    print("print_dblepsilon output:",np.finfo(np.float).eps)
    return

#=============================================================================
def round(x):
#-----Round real x into integer round such that a fractional part of x
#     of exactly 0.5 results in rounding to the nearest even integer.
#-----Adapted from colib5s.01J function {iround} (1984); 
    nextHighInt = math.ceil(x / 2.) * 2 - x
    deltaHigh = nextHighInt - x
    deltaLow = deltaHigh - 2

    if deltaHigh < deltaLow:
       round = nextHighInt
    else:
       round = nextHighInt - 2
    return round
#=============================================================================

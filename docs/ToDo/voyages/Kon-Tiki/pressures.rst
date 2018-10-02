Kon-Tiki Expedition (1947): Pressure observations
=================================================

.. figure:: ../../../../ToDo/voyages/Kon-Tiki_1947/analyses/20CRv3_comparisons/pressure_comparison.png
   :width: 95%
   :align: center
   :figwidth: 95%

   Atmospheric pressure observations made by the Kon-Tiki (black dots), compared with co-located MSLP in the 20CRv3 ensemble (blue dots). The red dots are the observations with a constant offset of 12hPa subtracted.

The apparent bias in the observations is large. I'm :doc:`assuming the observations come from aneroid barometer <metadata>`, so no temperature or gravity correction has been made. If they were really from a mercury barometer, the corrections would reduce the bias by about half (temperature and latitude vary little across the voyage).

Get the 20CRv3 data for comparison:

.. code-block:: python

    import IRData.twcr as twcr
    import datetime

    for month in (4,5,6,7,8):
	dtn=datetime.datetime(1947,month,1)
	twcr.fetch('prmsl',dtn,version='4.5.1')


Extract 20CRv3 MSLP at the time and place of each IMMA record. Uses :doc:`this script <comparators>`:

.. code-block:: sh

   ./get_comparators.py --imma=../../../imma/Kon-Tiki_1947.imma --var=prmsl

Make the figure:

.. literalinclude:: ../../../../ToDo/voyages/Kon-Tiki_1947/analyses/20CRv3_comparisons/plot_pressure_comparison.py



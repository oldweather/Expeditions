Kon-Tiki Expedition (1947): Wind direction observations
=======================================================

.. figure:: ../../../../ToDo/voyages/Kon-Tiki_1947/analyses/20CRv3_comparisons/D_comparison.png
   :width: 95%
   :align: center
   :figwidth: 95%

   Wind direction observations made by the Kon-Tiki (red dots), compared with co-located 10m wind direction in the 20CRv3 ensemble (blue dots).

The observed wind directions are almost certainly magnetic. To convert them to true would mean adding about 7 degrees (1/3 point) - moving them up with respect to the reanalysis data.

The wind observations were made with :doc:`a hand-held anemometer <metadata>`, probably at the masthead (maybe 6m above sea-level).

Get the 20CRv3 data for comparison:

.. code-block:: python

    import IRData.twcr as twcr
    import datetime

    for month in (4,5,6,7,8):
	dtn=datetime.datetime(1947,month,1)
	twcr.fetch('uwnd.10m',dtn,version='4.5.1')
	twcr.fetch('vwnd.10m',dtn,version='4.5.1')


Extract 20CRv3 10-metre zonal and meridional wind speeds at the time and place of each IMMA record. Uses :doc:`this script <comparators>`:

.. code-block:: sh

   ./get_comparators.py --imma=../../../imma/Kon-Tiki_1947.imma --var=uwnd.10m
   ./get_comparators.py --imma=../../../imma/Kon-Tiki_1947.imma --var=vwnd.10m

Make the figure:

.. literalinclude:: ../../../../ToDo/voyages/Kon-Tiki_1947/analyses/20CRv3_comparisons/plot_D_comparison.py



Kon-Tiki Expedition (1947): Air temperature observations
========================================================

.. figure:: ../../../../ToDo/voyages/Kon-Tiki_1947/analyses/20CRv3_comparisons/AT_comparison.png
   :width: 95%
   :align: center
   :figwidth: 95%

   Air temperature observations made by the Kon-Tiki (red dots), compared with co-located 2m air temperature in the 20CRv3 ensemble (blue dots).

I don't know how the observations were made or with what instrument. 

There is a substantial increase in the scatter of the observations at the beginning of June. I don't know why.

Get the 20CRv3 data for comparison:

.. code-block:: python

    import IRData.twcr as twcr
    import datetime

    for month in (4,5,6,7,8):
	dtn=datetime.datetime(1947,month,1)
	twcr.fetch('air.2m',dtn,version='4.5.1')


Extract 20CRv3 2-metre temperature at the time and place of each IMMA record. Uses :doc:`this script <comparators>`:

.. code-block:: sh

   ./get_comparators.py --imma=../../../imma/Kon-Tiki_1947.imma --var=air.2m

Make the figure:

.. literalinclude:: ../../../../ToDo/voyages/Kon-Tiki_1947/analyses/20CRv3_comparisons/plot_AT_comparison.py



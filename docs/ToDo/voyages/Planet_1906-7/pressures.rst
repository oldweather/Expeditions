SMS Planet voyage of 1906-7: Pressure observations
==================================================

.. figure:: ../../../../ToDo/voyages/planet_1906-7/analyses/20CRv3_comparisons/pressure_comparison.png
   :width: 95%
   :align: center
   :figwidth: 95%

   Atmospheric pressure observations made by the Planet (red dots), compared with co-located MSLP in the 20CRv3 ensemble (blue dots). 

Get the 20CRv3 data for comparison:

.. code-block:: python

    import IRData.twcr as twcr
    import datetime

    for month in range(1,11):
	dtn=datetime.datetime(1906,month,1)
	twcr.fetch('prmsl',dtn,version='4.5.1')
    for month in (1,2):
	dtn=datetime.datetime(1907,month,1)
	twcr.fetch('prmsl',dtn,version='4.5.1')


Extract 20CRv3 MSLP at the time and place of each IMMA record. Uses :doc:`this script <comparators>`:

.. literalinclude:: ../../../../ToDo/voyages/planet_1906-7/analyses/20CRv3_comparisons/make_all_comparators.py

Make the figure:

.. literalinclude:: ../../../../ToDo/voyages/planet_1906-7/analyses/20CRv3_comparisons/plot_pressure_comparison.py



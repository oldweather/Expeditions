Princesse Alice II Expedition (1898): Pressure observations
===========================================================

.. figure:: ../../../../ToDo/voyages/Princesse_Alice_II_1898/analyses/20CRv3_comparisons/pressure_comparison.png
   :width: 95%
   :align: center
   :figwidth: 95%

   Atmospheric pressure observations made by the Princesse Alice II (red dots), compared with co-located MSLP in the 20CRv3 ensemble (blue dots). 

Get the 20CRv3 data for comparison:

.. code-block:: python

    import IRData.twcr as twcr
    import datetime

    dtn=datetime.datetime(1898,1,1)
    twcr.fetch('PRMSL',dtn,version='3')

Extract 20CRv3 MSLP at the time and place of each IMMA record. Uses :doc:`this script <comparators>`:

.. code-block:: sh

   ./get_comparators.py --imma=../../../imma/Princess_Alice_II_1898.imma --var=PRMSL

Make the figure:

.. literalinclude:: ../../../../ToDo/voyages/Princesse_Alice_II_1898/analyses/20CRv3_comparisons/plot_pressure_comparison.py



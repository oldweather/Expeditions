:orphan:

Make 20CR comparators for an IMMA file
======================================

Script that extracts 20CRv3 ensemble values at the time and location of each record in an IMMA file. Uses the `IRData <http://brohan.org/IRData/>`_ package. It takes the IMMA file name and selected variable as options and saves the extracted data as a `pickle <https://docs.python.org/2/library/pickle.html>`_.

This takes a while for each observation, so it's designed to be parallelised - run it only on the set of IMMA records numbered from ``--start``` to ``--end``.

.. literalinclude:: ../../../../ToDo/voyages/planet_1906-7/analyses/20CRv3_comparisons/get_comparators.py


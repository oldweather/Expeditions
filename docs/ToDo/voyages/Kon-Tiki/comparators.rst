Make 20CR comparators for an IMMA file
======================================

Script that extracts 20CRv3 ensemble values at the time and location of each record in an IMMA file. Uses the `IRData <http://brohan.org/IRData/>`_ package. It takes the IMMA file name and selected variable as options and saves the extracted data as a `pickle <https://docs.python.org/2/library/pickle.html>`_.

Warning: **slow**: Maybe 2 records/minute. For large IMMA files a faster approach will be needed.

.. literalinclude:: ../../../../ToDo/voyages/Kon-Tiki_1947/analyses/20CRv3_comparisons/get_comparators.py


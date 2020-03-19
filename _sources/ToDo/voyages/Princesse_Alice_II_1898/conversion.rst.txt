Princesse Alice II 1898 Conversion script
=========================================

Script to convert transcribed data to IMMA for the :doc:`Princesse Alice II expedition in 1898 <Expedition>`. Uses the `Python IMMA library <http://brohan.org/pyIMMA/>`_, and the `Copernicus DRS marine data conversion tools <https://github.com/chesleymccoll/CS3-DR-Unit_Conversions>`_.

.. literalinclude:: ../../../../ToDo/voyages/Princesse_Alice_II_1898/scripts/pa_to_imma.py

As usual with marine sources, we have fewer position records than weather observations. Use interpolation to estimate a position for all observations.

.. literalinclude:: ../../../../ToDo/voyages/Princesse_Alice_II_1898/scripts/imma_interpolate.py



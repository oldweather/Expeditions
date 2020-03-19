Princesse Alice II Expedition (1898): Video summary
===================================================

.. raw:: html

    <center>
    <table><tr><td><center>
    <iframe src="https://player.vimeo.com/video/380259038?title=0&byline=0&portrait=0" width="795" height="448" frameborder="0" webkitallowfullscreen mozallowfullscreen allowfullscreen></iframe></center></td></tr>
    <tr><td><center>Route (left) and observations (right), from the Princess Alice II in 1898. Compared with the observations coverage, and ensemble reconstructions, for 20CRv3.</center></td></tr>
    </table>
    </center>

|

The map on the left shows the route of the Princesse Alice II (red and grey dots) and the locations of all the other pressure observations available to 20CR3 (yellow dots). The graphs on the right show the observations made by the ship (red and black dots), and co-located reconstructions from the 20CR3 ensemble (blue dots).

Based on the detailed figures for: :doc:`Route <route>` and :doc:`SLP <pressures>`. See those for the necessary data collection and pre-processing.

|

Script to make an individual frame - takes year, month, day, and hour as command-line options:

.. literalinclude:: ../../../../ToDo/voyages/Princesse_Alice_II_1898/video/PA_V3vobs.py

To make the video you need to run the plot script thousands of times, making an image file for each point in time, and then to merge the thousands of resulting images into a single video.

This script makes a list of commands to plot a frame each hour over the voyage:

.. literalinclude:: ../../../../ToDo/voyages/Princesse_Alice_II_1898/video/make_frames.py

You will want to run those jobs in parallel, either with `GNU parallel <https://www.gnu.org/software/parallel/>`_ or by submitting them to a batch system (I used the MO SPICE cluster).

To turn the thousands of images into a movie, use `ffmpeg <http://www.ffmpeg.org>`_

.. code-block:: shell

    ffmpeg -r 24 -pattern_type glob -i Princesse_Alice_II_1898/\*.png \
           -c:v libx264 -threads 16 -preset slow -tune animation \
           -profile:v high -level 4.2 -pix_fmt yuv420p -crf 25 \
           -c:a copy Princesse_Alice_II_1898.mp4




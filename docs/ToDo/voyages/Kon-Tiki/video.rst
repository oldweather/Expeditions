Kon-Tiki Expedition (1947): Video summary
=========================================

.. raw:: html

    <center>
    <table><tr><td><center>
    <iframe src="https://player.vimeo.com/video/292918898?title=0&byline=0&portrait=0" width="795" height="448" frameborder="0" webkitallowfullscreen mozallowfullscreen allowfullscreen></iframe></center></td></tr>
    <tr><td><center>Route (left) and observations (right), from the Kon-Tiki. Compared with the observations coverage, and ensemble reconstructions, for 20CRv3.</center></td></tr>
    </table>
    </center>

|

The map on the left shows the route of the Kon-Tiki (red and grey dots) and the locations of all the other pressure observations available to 20CR3 (yellow dots). The graphs on the right show the observations made by the Kon-Tiki (red and black dots), and co-located reconstructions from the 20CR3 ensemble (blue dots).

Based on the detailed figures for: :doc:`Route <route>`, :doc:`SLP <pressures>`, :doc:`air temperature <sea_temperatures>`, :doc:`SST <sea_temperatures>`, :doc:`wind speed <wind_speed>` & :doc:`wind direction <wind_speed>`. See those for the necessary data collection and pre-processing.

|

Script to make an individual frame - takes year, month, day, and hour as command-line options:

.. literalinclude:: ../../../../ToDo/voyages/Kon-Tiki_1947/analyses/video/KT_V3vobs.py

To make the video, it is necessary to run the script above hundreds of times - giving an image for every 15-minute period. The best way to do this is system dependent - the script below does it on the Met Office SPICE cluster - it will need modification to run on any other system. (Could do this on a single PC, but it will take many hours).

.. literalinclude:: ../../../../ToDo/voyages/Kon-Tiki_1947/analyses/video/make_frames.py

To turn the thousands of images into a movie, use `ffmpeg <http://www.ffmpeg.org>`_

.. code-block:: shell

    ffmpeg -r 24 -pattern_type glob -i Kon-Tiki/\*.png \
           -c:v libx264 -threads 16 -preset slow -tune animation \
           -profile:v high -level 4.2 -pix_fmt yuv420p -crf 25 \
           -c:a copy Kon-Tiki.mp4




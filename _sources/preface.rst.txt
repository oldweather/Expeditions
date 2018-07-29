What this is, and why
=====================

This is a benchmark dataset for a problem in computer vision, inspired by `MNIST <http://yann.lecun.com/exdb/mnist/>`_.

Everything we know about climate change and variability depends on our datasets of past weather observations. Datasets such as `ISPD <https://reanalyses.org/observations/international-surface-pressure-databank>`_ and `ISTI <http://www.surfacetemperatures.org/>`_ contain `billions of such observations <https://blog.oldweather.org/2015/01/08/a-history-of-the-world-in-1399120833-observations/>`_, but we need more: Many times and places still have few or no observations.

The world's archives contain millions of pages of paper documents containing tables of so-far-unused observations, and `we are systematically seeking them out for use <http://www.met-acre.net/>`_. The rate-limiting step in this process is transcription - the conversion of the numbers printed on those pages to database entries useable for science. At the moment this transcription is done manually - it would be an enormous advantage to have an automated system, based on machine learning/computer vision, that could perform such transcription with good accuracy.

No useful automated page transcription systems currently exist. It is likely that modern work on computer vision has built all or most of the components needed for such a system, but we still have to put them together into a working page transcriber. A key requirement for such a build is a set of test cases - pages to transcribe and pre-generated truth data to validate against. That's what this dataset is for.

This was chosen as a realistic, but easy dataset: The document pages are printed (rather than handwritten), in good condition, and consistent in format. The main difficulty is likely to be the indifferent quality of the document images. Such problems are typical - high quality document scanning is slow and expensive - so a widely-useful transcription system will have to work on images of this quality. We know the images are good enough, because they are what was used to produce the (manually transcribed) truth data.

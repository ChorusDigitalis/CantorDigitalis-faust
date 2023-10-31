Cantor Digitalis — Faust version
=================================

This is a partial implementation, in [Faust](https://faust.grame.fr/), of the singing synthesizer Cantor Digitalis as described in:

[L. Feugère, C. d'Alessandro, B. Doval, O. Perrotin:
Cantor Digitalis: Chironomic Parametric Synthesis of Singing
*EURASIP Journal on Audio, Speech and Music Processing*, 2017, 2 (2017)](https://doi.org/10.1186/s13636-016-0098-5)

More information about Cantor Digitalis, including video demos, research articles, as well as the original implementation in Max/MSP, can be found [there](https://cantordigitalis.limsi.fr/).


Use
----

### To quickly test the synth

Head over to [the online Faust IDE](https://faustide.grame.fr/). Upload the three files in `/src`, set `cantor.dsp` as the main file. The interface may become unresponsive for a few seconds once the files have been loaded, due to the project being fairly large for the online IDE. Don't panic. Once you are able to, click *Run* and wait a few more seconds.

### To compile it into a usable format (including VST, Max/MSP external, and many more)

#### Without installing Faust

* Go to the online IDE (see above)
* Click the *Export* button (the one with a picture of a truck on it)
* Choose your platform
* Choose format you want to export to
* Click *Compile*
* Download the file

#### To compile it on your own machine

* [Install Faust](https://faust.grame.fr/downloads/)
* Search for the format you're interested in [there](https://faustdoc.grame.fr/manual/tools/)
* Use the script accordingly


# NetsendPD

A multi-channel audio streaming proof of concept for Pd+iOS architecture. 

In a nutshell, this project allows you to stream any multi (2 and more) channel audio from your mac/PC server in realtime to your mobile iOS clients. At the same time, clients are able to communicate with server via OSC protocol.



## Requirements:

* **iOS 7.0+** (it's possible to build it against 6.0, but not recommended)

* **Python 2.7 with modules**: [pyosc](https://trac.v2.nl/wiki/pyOSC), [pybonjour](https://code.google.com/p/pybonjour/)

* **[Pd-extended](http://puredata.info/downloads/pd-extended) v0.43.4 and up** (you might need to check if Pd can find all external objects used in test patch)

* **Mac or PC** server connected to a wireless spot via **LAN cable** and, ideally, the Wi-Fi spot should work in **5Ghz frequency.**


## Setup and usage

Simply open up the Pd patch in project folder, run a python script in the same place, and finally build and run an iOS application. 

For the best experience **[check out this short tutorial in wiki](https://github.com/Apolotary/NetsendPD/wiki/Setup-and-usage)**


## License

This project is distributed under MIT license. Please see more in [LICENSE.txt](https://github.com/Apolotary/NetsendPD/blob/master/LICENSE.txt)
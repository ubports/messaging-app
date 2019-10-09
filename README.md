ReadMe - Ubuntu Messaging App
=============================
Ubuntu Messaging App is the official SMS app for Ubuntu Touch. We follow an open
source model where the code is available to anyone to branch and hack on.

Building with clickable
=======================
Install [clickable](http://clickable.bhdouglass.com/en/latest/), then app then can be build and deployed by simply running:

```
clickable
```

For faster build speeds, building app tests is disabled in ```clickable.json``` 

Building with crossbuilder
==========================
The easiest way to build this app is using crossbuilder.

Some dependencies need to be installed by running:

```
crossbuilder inst-foreign dh-translations apparmor-easyprof-ubuntu
```

The app then can be build by simply running:

```
crossbuilder
```

See [crossbuilder on github](https://github.com/ubports/crossbuilder) for details.

Useful Links
============
Here are some useful links with regards to the Messaging App development.

* [UBports](https://ubports.com/)
* [building with crossbuilder](https://docs.ubports.com/en/latest/systemdev/testing-locally.html#cross-building-with-crossbuilder)
* [crossbuilder on github](https://github.com/ubports/crossbuilder)
* [OpenStore](https://open-store.io/)
* [MMS infrastructure on Ubuntu Touch](https://wiki.ubuntu.com/Touch/Specs/MMSInfrastructure)

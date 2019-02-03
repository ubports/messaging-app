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

_NOTE:_ As for now, building with clickable fails, due to libnotify dependencies missing in clickable/ubuntu-sdk:16.04-armhf docker image.
Issue will be filled, but in the meantime you can install the ```libnotify-dev:armhf``` by yourself into the image and then use it via the ```--docker-image``` parameter. 

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
* [building with crossbuilder](http://docs.ubports.com/en/latest/appdev/system-software.html?highlight=crossbuilder#cross-building-with-crossbuilder)
* [crossbuilder on github](https://github.com/ubports/crossbuilder)
* [OpenStore](https://open-store.io/)

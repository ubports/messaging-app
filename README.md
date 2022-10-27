Messaging App
=============
Messaging App is the official SMS app for Ubuntu Touch.

Internals
=========

Messaging app relies on:
 - [history-service](https://github.com/ubports/history-service) for the database backend through `Ubuntu.History` QML import.
 - [telephony service](https://github.com/ubports/telephony-service) for message relay through `Ubuntu.Telphony`QML import.
 - [address-book-app](https://github.com/ubports/address-book-app) for contact features through `Ubuntu.Contacts` QML import.
 

Building with clickable (for local testings)
============================================

Note that it will not allow full feature access (url dispatcher, audio playback )

Install [clickable](http://clickable.bhdouglass.com/en/latest/), then run:

```
clickable
```

For faster build speeds, building app tests is disabled in ```clickable.json``` 

Desktop mode
------------

`clickable desktop` or via `clickable ide qtcreator`

If we want to test with real data, History database and Contact database must be present in `~.local/share/history-service/history.sqlite` and `/home/lionel/.local/share/system/privileged/Contacts/qtcontacts-sqlite/contacts.db` respectively
There is a condition that must be commented in order to see messages: see updateFilters method in Messages.qml

Building with crossbuilder ( build & install as a deb package )
===============================================================


Some dependencies need to be installed by running:

```
crossbuilder inst-foreign dh-translations apparmor-easyprof-ubuntu
```

The app then can be build by running:

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
* [MMS infrastructure on Ubuntu Touch](http://docs.ubports.com/en/latest/systemdev/mms-infrastructure.html)

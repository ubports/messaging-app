# -*- Mode: Python; coding: utf-8; indent-tabs-mode: nil; tab-width: 4 -*-
# Copyright 2013 Canonical
#
# This file is part of messaging-app.
#
# messaging-app is free software: you can redistribute it and/or modify it
# under the terms of the GNU General Public License version 3, as published
# by the Free Software Foundation.

import dbus

def get_my_number():
    bus = dbus.SystemBus()
    obj = bus.get_object('org.ofono', '/ril_0') # MAX config this?

    mgr = dbus.Interface(obj, 'org.ofono.SimManager')
    number = str(mgr.GetProperties()['SubscriberNumbers'][0])
    return(number)

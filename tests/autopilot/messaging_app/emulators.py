# -*- Mode: Python; coding: utf-8; indent-tabs-mode: nil; tab-width: 4 -*-
# Copyright 2013 Canonical
#
# This file is part of messaging-app.
#
# messaging-app is free software: you can redistribute it and/or modify it
# under the terms of the GNU General Public License version 3, as published
# by the Free Software Foundation.


"""Messaging app autopilot emulators."""

from ubuntuuitoolkit import emulators as toolkit_emulators

class MainView(toolkit_emulators.MainView):
    def __init__(self, *args):
        super(MainView, self).__init__(*args)

    def get_pagestack(self):
        return self.select_single("PageStack", objectName="mainStack")

    def get_messages_page(self):
        return self.select_single("Messages", objectName="messagesPage")

    def get_newmessage_textfield(self):
        return self.select_single("TextField", objectName="newPhoneNumberField")


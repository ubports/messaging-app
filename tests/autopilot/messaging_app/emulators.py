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

    @property
    def messages_page(self):
        return self.select_single(MessagesPage)

class MessagesPage(toolkit_emulators.UbuntuUIToolkitEmulatorBase):
    def __init__(self, *args):
        super(MessagesPage, self).__init__(*args)

    @property
    def messages_listview(self):
        return self.select_single("MultipleSelectionListView", objectName="messageList")

    @property
    def newmessage_textfield(self):
        return self.select_single("TextField", objectName="newPhoneNumberField")


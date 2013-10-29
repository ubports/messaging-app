# -*- Mode: Python; coding: utf-8; indent-tabs-mode: nil; tab-width: 4 -*-
# Copyright 2013 Canonical
#
# This file is part of messaging-app.
#
# messaging-app is free software: you can redistribute it and/or modify it
# under the terms of the GNU General Public License version 3, as published
# by the Free Software Foundation.

"""Pure UI tests for Messaging App"""

from __future__ import absolute_import

from autopilot.matchers import Eventually
from testtools.matchers import Equals

from messaging_app.tests import MessagingAppTestCase


class TestUI(MessagingAppTestCase):
    def test_new_message_panel(self):
        """New message panel comes up with the toolbar button"""

        # Click "New message" menu button
        self.main_view.open_toolbar()
        toolbar = self.main_view.get_toolbar()
        toolbar.click_button("newMessageButton")

        # wait for "New message" page
        self.assertThat(self.main_view.get_pagestack().depth,
                        Eventually(Equals(2)))
        self.assertThat(self.main_view.get_messages_page().visible,
                        Eventually(Equals(True)))

        # type address number
        text_entry = self.main_view.get_newmessage_textfield()
        text_entry.activeFocus.wait_for(True)
        self.keyboard.type("123")
        self.assertThat(text_entry.text, Eventually(Equals("123")))

        # type message
        text_entry = self.main_view.get_newmessage_textarea()
        self.pointing_device.click_object(text_entry)
        text_entry.activeFocus.wait_for(True)
        message = "hello from Ubuntu"
        self.keyboard.type(message)
        self.assertThat(text_entry.text, Eventually(Equals(message)))

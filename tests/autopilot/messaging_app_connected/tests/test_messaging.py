# -*- Mode: Python; coding: utf-8; indent-tabs-mode: nil; tab-width: 4 -*-
# Copyright 2012 Canonical
#
# This file is part of messaging-app.
#
# messaging-app is free software: you can redistribute it and/or modify it
# under the terms of the GNU General Public License version 3, as published
# by the Free Software Foundation.

"""Tests for the Messaging App"""

from __future__ import absolute_import

from autopilot.matchers import Eventually
from testtools.matchers import Equals

from messaging_app_connected.tests import MessagingAppTestCase
from messaging_app_connected import emulators

import time

from uuid import uuid4

class TestMessaging(MessagingAppTestCase):
    """Tests for the communication panel."""

    def setUp(self):
        super(TestMessaging, self).setUp()
        self.number = emulators.ofono.get_my_number()
        self.message = str(uuid4())

    def click_new_message_button(self):
        self.main_view.open_toolbar()
        toolbar = self.main_view.get_toolbar()
        toolbar.click_button("newMessageButton")
        self.assertThat(self.main_view.get_pagestack().depth, Eventually(Equals(2)))
        self.assertThat(self.main_view.get_messages_page().visible, Eventually(Equals(True)))

    def enter_number(self, number):
        text_entry = self.main_view.get_newmessage_textfield()
        self.pointing_device.click_object(text_entry)
        text_entry.activeFocus.wait_for(True)
        self.keyboard.type(number)
        self.assertThat(text_entry.text, Eventually(Equals(number)))

    def enter_message(self, message):
        text_entry = self.main_view.get_newmessage_textarea()
        self.pointing_device.click_object(text_entry)
        text_entry.activeFocus.wait_for(True)
        self.keyboard.type(message)
        self.assertThat(text_entry.text, Eventually(Equals(message)))

    def click_send_button(self):
        button = self.main_view.get_send_button()
        self.assertThat(button.enabled, Eventually(Equals(True)))
        self.pointing_device.click_object(button)
        self.assertThat(button.enabled, Eventually(Equals(False)))

    def send_message(self, number, message):
        self.click_new_message_button()
        self.enter_number(number)
        self.enter_message(message)
        self.click_send_button()

    def test_send_sms(self):
        self.send_message(self.number, self.message)

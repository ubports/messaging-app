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

from connected_tests.tests import MessagingAppTestCase

import time


class TestCommunicationPanel(MessagingAppTestCase):
    """Tests for the communication panel."""

    def setUp(self):
        super(TestCommunicationPanel, self).setUp()
        communication_page = self.communication_panel.get_communication_page()
        self.switch_to_conversation_tab()
        self.assertThat(communication_page.isCurrent, Eventually(Equals(True)))

    def click_new_message_button(self):
        self.reveal_toolbar()
        new_message_item = self.communication_panel.get_new_message_button()

        self.pointing_device.click_object(new_message_item)

    def type_sendto_number(self, number):
        sendto_box = self.communication_panel.get_new_message_send_to_box()
        self.pointing_device.click_object(sendto_box)
        self.assertThat(sendto_box.activeFocus, Eventually(Equals(True)))
        self.keyboard.type(number, delay=self.TYPING_DELAY)
        self.assertThat(sendto_box.text, Eventually(Equals(number)))

    def type_message_to_send(self, message):
        message_box = self.communication_panel.get_new_message_text_box()
        self.pointing_device.click_object(message_box)
        self.assertThat(message_box.activeFocus, Eventually(Equals(True)))
        self.keyboard.type(message, delay=self.TYPING_DELAY)
        self.assertThat(message_box.text, Eventually(Equals(message)))
    
    def test_sending_sms_is_intact(self):
        self.click_new_message_button()
        self.type_sendto_number(self.SEND_SMS_NUMBER)
        self.type_message_to_send(self.SEND_SMS_TEXT)
        
        send_button = self.communication_panel.get_message_send_button()
        self.assertThat(send_button.enabled, Eventually(Equals(True)))
        self.pointing_device.click_object(send_button)
        self.assertThat(send_button.enabled, Eventually(Equals(False)))

        communication_view = self.communication_panel.get_communication_view()
        self.assertThat(communication_view.active, Eventually(Equals(True)))

        sms_item = self.communication_panel.get_sms_item(1)
        self.assertThat(sms_item.message, Eventually(Equals(self.SEND_SMS_TEXT)))

    def test_receiving_sms_is_intact(self):
        """Test will wait and wait till a new sms arrives."""
        sms_item = self.communication_panel.get_sms_list_item(1)
        self.assertThat(sms_item.title, Eventually(Equals(self.RECEIVED_SMS_NUMBER)))

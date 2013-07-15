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

from messaging_app.tests import MessagingAppTestCase


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

        self.pointing_device.move_to_object(new_message_item)
        self.pointing_device.click()

    def click_sendto_box(self):
        sendto_box = self.communication_panel.get_new_message_send_to_box()
        self.pointing_device.move_to_object(sendto_box)
        self.pointing_device.click()
        self.assertThat(sendto_box.activeFocus, Eventually(Equals(True)))

    def test_searchbox_focus(self):
        """Clicking inside the searbox must give it the focus."""
        searchbox = self.communication_panel.get_communication_searchbox()
        self.pointing_device.move_to_object(searchbox)
        self.pointing_device.click()

        self.assertThat(searchbox.activeFocus, Eventually(Equals(True)))

    def test_searchbox_entry(self):
        """Ensures that typing inside the main searchbox works."""
        searchbox = self.communication_panel.get_communication_searchbox()
        self.pointing_device.move_to_object(searchbox)
        self.pointing_device.click()

        self.keyboard.type("test")

        self.assertThat(searchbox.text, Eventually(Equals("test")))

    def test_searchbox_clear_button(self):
        """Clicking the cross icon must clear the searchbox."""
        searchbox = self.communication_panel.get_communication_searchbox()
        clear_button = self.communication_panel.get_communication_searchbox_clear_button()

        self.pointing_device.move_to_object(searchbox)
        self.pointing_device.click()

        self.keyboard.type("test")
        self.assertThat(searchbox.text, Eventually(Equals("test")))

        self.pointing_device.move_to_object(clear_button)
        self.pointing_device.click()

        self.assertThat(searchbox.text, Eventually(Equals("")))

    def test_communication_view_visible(self):
        """Clicking on the 'New Message' list item must show the message view.
        """
        self.click_new_message_button()
        communication_view = self.communication_panel.get_communication_view()

        self.assertThat(communication_view.visible, Eventually(Equals(True)))

    def test_message_send_to_focus(self):
        """Clicking the 'New Message' list item must give focus to the
        'sendto' box.

        """
        self.click_new_message_button()
        sendto_box = self.communication_panel.get_new_message_send_to_box()

        # FIXME: we should have the field focused by default, but right now we
        # need to explicitly give it focus
        self.click_sendto_box()

        self.assertThat(sendto_box.activeFocus, Eventually(Equals(True)))

    def test_message_send_to_entry(self):
        """Ensures that number can be typed into the 'sendto' box."""
        self.click_new_message_button()
        sendto_box = self.communication_panel.get_new_message_send_to_box()

        # FIXME: we should have the field focused by default, but right now we
        # need to explicitly give it focus
        self.click_sendto_box()
        self.keyboard.type("911")

        self.assertThat(sendto_box.text, Eventually(Equals("911")))

    def test_send_button_active(self):
        """Typing a number into the 'sendto' box and a message
           must enable the Send button.
        """
        self.click_new_message_button()
        send_button = self.communication_panel.get_message_send_button()

        self.assertThat(send_button.enabled, Eventually(Equals(False)))

        # FIXME: we should have the field focused by default, but right now we
        # need to explicitly give it focus
        self.click_sendto_box()
        self.keyboard.type("911")

        # By typing just the destination number, the button should continue
        # disabled until a message is typed
        self.assertThat(send_button.enabled, Eventually(Equals(False)))

        # type a message
        message_box = self.communication_panel.get_new_message_text_box()
        self.pointing_device.move_to_object(message_box)
        self.pointing_device.click()
        self.keyboard.type("Hello!")

        # and now finally the send button is enabled
        # FIXME: send button is only enabled when there is an active connection
        #        to oFono, need to check how to mock that.
        #self.assertThat(send_button.enabled, Eventually(Equals(True)))

    def test_send_button_disable_on_clear(self):
        """Removing the number from the 'sendto' box must disable the
        Send button.

        """
        self.click_new_message_button()
        send_button = self.communication_panel.get_message_send_button()

        # type a message
        message_box = self.communication_panel.get_new_message_text_box()
        self.pointing_device.move_to_object(message_box)
        self.pointing_device.click()
        self.keyboard.type("Hello!")

        # FIXME: we should have the field focused by default, but right now we
        # need to explicitly give it focus
        self.click_sendto_box()
        self.keyboard.type("911")
        self.keyboard.press_and_release("Ctrl+a")
        self.keyboard.press_and_release("Delete")

        self.assertThat(send_button.enabled, Eventually(Equals(False)))

    def test_new_message_box_focus(self):
        """Clicking inside the main message box must give it the focus."""
        self.click_new_message_button()
        message_box = self.communication_panel.get_new_message_text_box()

        self.pointing_device.move_to_object(message_box)
        self.pointing_device.click()

        self.assertThat(message_box.activeFocus, Eventually(Equals(True)))

    def test_new_message_box_entry(self):
        """Ensures that typing inside the main message box works."""
        self.click_new_message_button()
        message_box = self.communication_panel.get_new_message_text_box()

        self.pointing_device.move_to_object(message_box)
        self.pointing_device.click()

        self.keyboard.type("test")

        self.assertThat(message_box.text, Eventually(Equals("test")))

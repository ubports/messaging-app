# -*- Mode: Python; coding: utf-8; indent-tabs-mode: nil; tab-width: 4 -*-
# Copyright 2012 Canonical
#
# This file is part of messaging-app.
#
# messaging-app is free software: you can redistribute it and/or modify it
# under the terms of the GNU General Public License version 3, as published
# by the Free Software Foundation.

"""Tests for the Messaging App using ofono-phonesim"""

from __future__ import absolute_import

import os
import subprocess
import time

from autopilot.introspection import dbus
from autopilot.matchers import Eventually
from testtools.matchers import Equals
from testtools import skipIf, skipUnless

from messaging_app.tests import MessagingAppTestCase

# determine whether we are running with phonesim
try:
    out = subprocess.check_output(["/usr/share/ofono/scripts/list-modems"],
                                  stderr=subprocess.PIPE)
    have_phonesim = out.startswith("[ /phonesim ]")
except subprocess.CalledProcessError:
    have_phonesim = False


@skipUnless(have_phonesim,
            "this test needs to run under with-ofono-phonesim")
@skipIf(os.uname()[2].endswith("maguro"),
        "tests cause Unity crashes on maguro")
class TestMessaging(MessagingAppTestCase):
    """Tests for the communication panel."""

    def setUp(self):
        # kill OSK it gets stuck open sometimes
        subprocess.call(["pkill", "maliit-server"])

        # provide clean history
        self.history = os.path.expanduser(
            "~/.local/share/history-service/history.sqlite")
        if os.path.exists(self.history):
            os.rename(self.history, self.history + ".orig")
        subprocess.call(["pkill", "history-daemon"])
        subprocess.call(["pkill", "-f", "telephony-service-handler"])

        super(TestMessaging, self).setUp()

        # no initial messages
        self.thread_list = self.app.select_single(objectName="threadList")
        self.assertThat(self.thread_list.visible, Equals(True))
        self.assertThat(self.thread_list.count, Equals(0))

    def tearDown(self):
        super(TestMessaging, self).tearDown()

        # restore history
        try:
            os.unlink(self.history)
        except OSError:
            pass
        if os.path.exists(self.history + ".orig"):
            os.rename(self.history + ".orig", self.history)
        subprocess.call(["pkill", "history-daemon"])
        subprocess.call(["pkill", "-f", "telephony-service-handler"])

        # on desktop, notify-osd may generate persistent popups (like for "SMS
        # received"), don't make that stay around for the tests
        subprocess.call(["pkill", "-f", "notify-osd"])

    def test_receive_message(self):
        # receive an sms message
        self.main_view.receive_sms('0815', 'hello to Ubuntu')

        # verify that we got the message
        self.assertThat(self.thread_list.count, Eventually(Equals(1)))

        # verify number
        self.thread_list.select_single('Label', text='0815')
        time.sleep(1)  # make it visible to human users for a sec
        # verify text
        self.thread_list.select_single('Label', text='hello to Ubuntu')

    def test_write_new_message(self):
        self.main_view.click_new_message_button()
        #verify the thread list page is not visible
        self.assertThat(self.thread_list.visible, Eventually(Equals(False)))

        # type contact/number
        phone_num = 123
        self.main_view.type_contact_phone_num(phone_num)

        # type message
        message = "hello from Ubuntu"
        self.main_view.type_message(message)

        # send
        self.main_view.click_send_button()

        # verify that we get a bubble with our message
        list_view = self.main_view.get_multiple_selection_list_view()
        self.assertThat(list_view.count, Eventually(Equals(1)))
        # verify label text
        self.main_view.get_message("hello from Ubuntu")

        # switch back to main page with thread list
        self.main_view.close_osk()
        self.main_view.go_back()

        # verify the main page with the contacts that have sent messages is
        # visible
        self.assertThat(self.thread_list.visible, Eventually(Equals(True)))

        # verify a message in the thread list
        self.assertThat(self.thread_list.count, Equals(1))
        # verify our number
        self.thread_list.select_single("Label", text="123")
        # verify our text
        self.thread_list.select_single("Label", text="hello from Ubuntu")

    def test_deleting_message_long_press(self):
        self.main_view.click_new_message_button()
        self.assertThat(self.thread_list.visible, Eventually(Equals(False)))

        # type address number
        phone_num = "555-555-4321"
        self.main_view.type_contact_phone_num(phone_num)
        # type message
        message = "delete me"
        self.main_view.type_message(message)

        # send
        self.main_view.click_send_button()

        # verify that we get a bubble with our message
        list_view = self.main_view.get_multiple_selection_list_view()
        self.assertThat(list_view.count, Eventually(Equals(1)))
        bubble = self.main_view.get_message(message)

        self.main_view.close_osk()

        # long press on bubble
        self.main_view.long_press(bubble)

        # select delete button
        self.main_view.click_delete_dialog_button()

        # verify message is deleted
        bubble.wait_until_destroyed()

    def test_cancel_deleting_message_long_press(self):
        self.main_view.click_new_message_button()
        self.assertThat(self.thread_list.visible, Eventually(Equals(False)))

        # type address number
        phone_num = "5555551234"
        self.main_view.type_contact_phone_num(phone_num)

        # type message
        message = "do not delete"
        self.main_view.type_message(message)

        # send
        self.main_view.click_send_button()

        # verify that we get a bubble with our message
        list_view = self.main_view.get_multiple_selection_list_view()
        self.assertThat(list_view.count, Eventually(Equals(1)))
        bubble = self.main_view.get_message(message)

        self.main_view.close_osk()

        # long press on bubble and verify cancel button does not delete message
        self.main_view.long_press(bubble)
        self.main_view.click_cancel_dialog_button()
        time.sleep(5)  # on a slow machine it might return a false positive
        #the bubble must exist
        bubble = self.main_view.get_message(message)

    def test_open_received_message(self):
        number = '5555555678'
        message = 'open me'
        # receive message
        self.main_view.receive_sms(number, message)
        self.assertThat(self.thread_list.count, Eventually(Equals(1)))
        # click message thread
        mess_thread = self.thread_list.wait_select_single("Label", text=number)
        self.pointing_device.click_object(mess_thread)
        self.main_view.get_message(message)
        # send new message
        self.main_view.type_message('{} 2'.format(message))
        self.main_view.click_send_button()
        # verify both messages are seen in list
        self.main_view.get_message('{} 2'.format(message))
        self.main_view.get_message(message)

    def test_delete_multiple_messages(self):
        number = '5555559876'
        message = "delete me"
        # send 5 messages
        for num in range(1, 6):
            self.main_view.receive_sms(number, '{} {}'.format(message, num))
            time.sleep(1)
        # verify messages show up in thread
        self.assertThat(self.thread_list.count, Eventually(Equals(1)))

        mess_thread = self.thread_list.wait_select_single("Label", text=number)
        self.pointing_device.click_object(mess_thread)

        # long press on message 5
        bubble5 = self.main_view.get_label("delete me 5")
        self.main_view.long_press(bubble5)

        # tap message 2 - 4
        for num in range(2, 5):
            bubble = self.main_view.get_label(
                '{} {}'.format(message, num)
            )
            self.pointing_device.click_object(bubble)

        # delete messages 2 - 5
        self.main_view.click_delete_dialog_button()

        #verify message 2 - 5 are destroyed
        for num in range(2, 6):
            try:
                bubble = self.main_view.get_label(
                    '{} {}'.format(message, num)
                )
                bubble.wait_until_destroyed()
            ## if the message is not there it was already destroyed
            except dbus.StateNotFoundError:
                pass
        #verify message bubble 1 exists
        self.main_view.get_label("delete me 1")

    def test_toolbar_delete_message(self):
        self.main_view.click_new_message_button()
        self.assertThat(self.thread_list.visible, Eventually(Equals(False)))

        # type address number
        phone_num = "555-555-4321"
        self.main_view.type_contact_phone_num(phone_num)
        # type message
        message = "delete me"
        self.main_view.type_message(message)

        # send
        self.main_view.click_send_button()

        # verify that we get a bubble with our message
        list_view = self.main_view.get_multiple_selection_list_view()
        self.assertThat(list_view.count, Eventually(Equals(1)))
        bubble = self.main_view.get_message(message)

        self.main_view.close_osk()

        # press on select button and message then delete
        self.main_view.click_select_messages_button()
        self.pointing_device.click_object(bubble)
        self.main_view.click_delete_dialog_button()
        #verify messsage is gone
        bubble.wait_until_destroyed()

    def test_toolbar_delete_message_without_selecting_a_message(self):
        self.main_view.click_new_message_button()
        self.assertThat(self.thread_list.visible, Eventually(Equals(False)))

        # type address number
        phone_num = "555-555-4321"
        self.main_view.type_contact_phone_num(phone_num)
        # type message
        message = "dont delete me"
        self.main_view.type_message(message)

        # send
        self.main_view.click_send_button()

        # verify that we get a bubble with our message
        list_view = self.main_view.get_multiple_selection_list_view()
        self.assertThat(list_view.count, Eventually(Equals(1)))
        self.main_view.get_message(message)

        self.main_view.close_osk()

        # press on select button then delete
        self.main_view.click_select_messages_button()
        self.main_view.click_delete_dialog_button()

        #verify messsage is not gone
        time.sleep(5)  # wait 5 seconds, the emulator is slow
        list_view.select_single("Label", text=message)

    def test_recieve_text_with_letters_in_phone_number(self):
        number = 'letters'
        message = 'open me'
        # receive message
        self.main_view.receive_sms(number, message)
        self.assertThat(self.thread_list.count, Eventually(Equals(1)))
        # click message thread
        mess_thread = self.thread_list.wait_select_single(
            'Label',
            text='letters@'  # phonesim sends text with number as letters@
        )
        self.pointing_device.click_object(mess_thread)
        self.main_view.get_message(message)
        # send new message
        self.main_view.type_message('{} 2'.format(message))
        self.main_view.click_send_button()
        # verify both messages are seen in list
        self.main_view.get_message('{} 2'.format(message))
        self.main_view.get_message(message)

    def test_cancel_delete_thread_from_main_view(self):
        self.main_view.click_new_message_button()
        #verify the thread list page is not visible
        self.assertThat(self.thread_list.visible, Eventually(Equals(False)))

        # type contact/number
        phone_num = 123
        self.main_view.type_contact_phone_num(phone_num)

        # type message
        message = "hello from Ubuntu"
        self.main_view.type_message(message)

        # send
        self.main_view.click_send_button()

        # verify that we get a bubble with our message
        list_view = self.main_view.get_multiple_selection_list_view()
        self.assertThat(list_view.count, Eventually(Equals(1)))
        # verify label text
        self.main_view.get_message("hello from Ubuntu")

        # switch back to main page with thread list
        self.main_view.close_osk()
        self.main_view.go_back()

        # verify the main page with the contacts that have sent messages is
        # visible
        self.assertThat(self.thread_list.visible, Eventually(Equals(True)))

        # verify a message in the thread list
        self.assertThat(self.thread_list.count, Equals(1))
        # verify our number
        self.thread_list.select_single("Label", text="123")
        # verify our text
        self.thread_list.select_single("Label", text="hello from Ubuntu")
        # use select button in toolbar
        self.main_view.click_select_button()
        # click cancel button
        self.main_view.click_cancel_dialog_button()
        # wait for slow emulator
        time.sleep(5)
        # verify our number was not deleted
        self.thread_list.select_single("Label", text="123")
        # verify our text was not deleted
        self.thread_list.select_single("Label", text="hello from Ubuntu")

    def test_delete_thread_from_main_view(self):
        self.main_view.click_new_message_button()
        #verify the thread list page is not visible
        self.assertThat(self.thread_list.visible, Eventually(Equals(False)))

        # type contact/number
        phone_num = 123
        self.main_view.type_contact_phone_num(phone_num)

        # type message
        message = "hello from Ubuntu"
        self.main_view.type_message(message)

        # send
        self.main_view.click_send_button()

        # verify that we get a bubble with our message
        list_view = self.main_view.get_multiple_selection_list_view()
        self.assertThat(list_view.count, Eventually(Equals(1)))
        # verify label text
        self.main_view.get_message("hello from Ubuntu")

        # switch back to main page with thread list
        self.main_view.close_osk()
        self.main_view.go_back()

        # verify the main page with the contacts that have sent messages is
        # visible
        self.assertThat(self.thread_list.visible, Eventually(Equals(True)))

        # verify a message in the thread list
        self.assertThat(self.thread_list.count, Equals(1))
        # verify our number
        mess_thread = self.thread_list.select_single("Label", text="123")
        # verify our text
        self.thread_list.select_single("Label", text="hello from Ubuntu")
        # use select button in toolbar
        self.main_view.click_select_button()
        # click thread we want to delete
        self.pointing_device.click_object(mess_thread)
        # click cancel button
        self.main_view.click_delete_dialog_button()
        # verify our text was deleted
        mess_thread.wait_until_destroyed()

    def test_delete_message_thread_swipe_right(self):
        # receive an sms message
        self.main_view.receive_sms('0815', 'hello to Ubuntu')

        # verify that we got the message
        self.assertThat(self.thread_list.count, Eventually(Equals(1)))

        # delete thread by swiping
        self.main_view.delete_thread('0815')
        self.assertThat(self.thread_list.count, Eventually(Equals(0)))

    def test_delete_message_swipe_right(self):
        self.main_view.click_new_message_button()
        self.assertThat(self.thread_list.visible, Eventually(Equals(False)))

        # type address number
        phone_num = "555-555-4321"
        self.main_view.type_contact_phone_num(phone_num)
        # type message
        message = "delete me okay"
        self.main_view.type_message(message)

        # send
        self.main_view.click_send_button()

        # verify that we get a bubble with our message
        list_view = self.main_view.get_multiple_selection_list_view()
        self.assertThat(list_view.count, Eventually(Equals(1)))
        self.main_view.get_message(message)

        #delete message
        self.main_view.delete_message(message)
        self.assertThat(list_view.count, Eventually(Equals(0)))

    def test_delete_message_thread_swipe_left(self):
        # receive an sms message
        self.main_view.receive_sms('0815', 'hello to Ubuntu')

        # verify that we got the message
        self.assertThat(self.thread_list.count, Eventually(Equals(1)))

        # delete thread by swiping
        self.main_view.delete_thread('0815', direction='left')
        self.assertThat(self.thread_list.count, Eventually(Equals(0)))

    def test_delete_message_swipe_left(self):
        self.main_view.click_new_message_button()
        self.assertThat(self.thread_list.visible, Eventually(Equals(False)))

        # type address number
        phone_num = "555-555-4321"
        self.main_view.type_contact_phone_num(phone_num)
        # type message
        message = "delete me okay"
        self.main_view.type_message(message)

        # send
        self.main_view.click_send_button()

        # verify that we get a bubble with our message
        list_view = self.main_view.get_multiple_selection_list_view()
        self.assertThat(list_view.count, Eventually(Equals(1)))
        self.main_view.get_message(message)

        #delete message
        self.main_view.delete_message(message, direction='left')
        self.assertThat(list_view.count, Eventually(Equals(0)))

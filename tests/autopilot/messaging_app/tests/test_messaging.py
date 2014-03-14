# -*- Mode: Python; coding: utf-8; indent-tabs-mode: nil; tab-width: 4 -*-
# Copyright 2012, 2014 Canonical
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

from autopilot.matchers import Eventually
from testtools.matchers import Equals, HasLength
from testtools import skipIf

from messaging_app import emulators
from messaging_app.tests import MessagingAppTestCase


@skipIf(os.uname()[2].endswith('maguro'),
        'tests cause Unity crashes on maguro')
class BaseMessagingTestCase(MessagingAppTestCase):

    def setUp(self):

        # determine whether we are running with phonesim
        try:
            out = subprocess.check_output(
                ['/usr/share/ofono/scripts/list-modems'],
                stderr=subprocess.PIPE
            )
            have_phonesim = out.startswith('[ /phonesim ]')
        except subprocess.CalledProcessError:
            have_phonesim = False

        self.assertTrue(have_phonesim)

        # provide clean history
        self.history = os.path.expanduser(
            '~/.local/share/history-service/history.sqlite')
        if os.path.exists(self.history):
            os.rename(self.history, self.history + '.orig')
        subprocess.call(['pkill', 'history-daemon'])
        subprocess.call(['pkill', '-f', 'telephony-service-handler'])

        super(BaseMessagingTestCase, self).setUp()

        # no initial messages
        self.thread_list = self.app.select_single(objectName='threadList')
        self.assertThat(self.thread_list.visible, Equals(True))
        self.assertThat(self.thread_list.count, Equals(0))

    def tearDown(self):
        super(BaseMessagingTestCase, self).tearDown()

        # restore history
        try:
            os.unlink(self.history)
        except OSError:
            pass
        if os.path.exists(self.history + '.orig'):
            os.rename(self.history + '.orig', self.history)
        subprocess.call(['pkill', 'history-daemon'])
        subprocess.call(['pkill', '-f', 'telephony-service-handler'])

        # on desktop, notify-osd may generate persistent popups (like for "SMS
        # received"), don't make that stay around for the tests
        subprocess.call(['pkill', '-f', 'notify-osd'])


class TestMessaging(BaseMessagingTestCase):
    """Tests for the communication panel."""

    def test_write_new_message_to_group(self):
        recipient_list = ["123", "321"]
        self.main_view.click_new_message_button()

        # type address number
        for number in recipient_list:
            self.main_view.type_contact_phone_num(number)
            self.keyboard.press_and_release("Enter")

        # check if recipients match
        multircpt_entry = self.main_view.get_newmessage_multirecipientinput()
        self.assertThat(
            multircpt_entry.get_properties()['recipientCount'],
            Eventually(Equals(len(recipient_list)))
        )

    def test_receive_message(self):
        """Verify that we can receive a text message"""
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
        """Verify we can write and send a new text message"""
        self.main_view.click_new_message_button()
        #verify the thread list page is not visible
        self.assertThat(self.thread_list.visible, Eventually(Equals(False)))

        # type contact/number
        phone_num = 123
        self.main_view.type_contact_phone_num(phone_num)

        # type message
        message = 'hello from Ubuntu'
        self.main_view.type_message(message)

        # send
        self.main_view.click_send_button()

        # verify that we get a bubble with our message
        list_view = self.main_view.get_multiple_selection_list_view()
        self.assertThat(list_view.count, Eventually(Equals(1)))
        # verify label text
        self.main_view.get_message('hello from Ubuntu')

        # switch back to main page with thread list
        self.main_view.close_osk()
        self.main_view.go_back()

        # verify the main page with the contacts that have sent messages is
        # visible
        self.assertThat(self.thread_list.visible, Eventually(Equals(True)))

        # verify a message in the thread list
        self.assertThat(self.thread_list.count, Equals(1))
        # verify our number
        self.thread_list.select_single('Label', text='123')
        # verify our text
        self.thread_list.select_single('Label', text='hello from Ubuntu')

    def test_deleting_message_long_press(self):
        """Verify we can delete a message with a long press on the message"""
        self.main_view.click_new_message_button()
        self.assertThat(self.thread_list.visible, Eventually(Equals(False)))

        # type address number
        phone_num = '555-555-4321'
        self.main_view.type_contact_phone_num(phone_num)
        # type message
        message = 'delete me'
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
        """Verify we can cancel deleting a message with a long press"""
        self.main_view.click_new_message_button()
        self.assertThat(self.thread_list.visible, Eventually(Equals(False)))

        # type address number
        phone_num = '5555551234'
        self.main_view.type_contact_phone_num(phone_num)

        # type message
        message = 'do not delete'
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
        """Verify we can open a txt message we have received"""
        number = '5555555678'
        message = 'open me'
        # receive message
        self.main_view.receive_sms(number, message)
        self.assertThat(self.thread_list.count, Eventually(Equals(1)))
        # click message thread
        mess_thread = self.thread_list.wait_select_single('Label', text=number)
        self.pointing_device.click_object(mess_thread)
        self.main_view.get_message(message)
        # send new message
        self.main_view.type_message('{} 2'.format(message))
        self.main_view.click_send_button()
        # verify both messages are seen in list
        self.main_view.get_message('{} 2'.format(message))
        self.main_view.get_message(message)

    def test_toolbar_delete_message(self):
        """Verify we can use the toolbar to delete a message"""
        self.main_view.click_new_message_button()
        self.assertThat(self.thread_list.visible, Eventually(Equals(False)))

        # type address number
        phone_num = '555-555-4321'
        self.main_view.type_contact_phone_num(phone_num)
        # type message
        message = 'delete me'
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
        """Verify we only delete messages that have been selected"""
        self.main_view.click_new_message_button()
        self.assertThat(self.thread_list.visible, Eventually(Equals(False)))

        # type address number
        phone_num = '555-555-4321'
        self.main_view.type_contact_phone_num(phone_num)
        # type message
        message = 'dont delete me'
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
        """verify we can receive a text message with letters for a phone #"""
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
        """Verify we can cancel deleting a message thread"""
        self.main_view.click_new_message_button()
        #verify the thread list page is not visible
        self.assertThat(self.thread_list.visible, Eventually(Equals(False)))

        # type contact/number
        phone_num = 123
        self.main_view.type_contact_phone_num(phone_num)

        # type message
        message = 'hello from Ubuntu'
        self.main_view.type_message(message)

        # send
        self.main_view.click_send_button()

        # verify that we get a bubble with our message
        list_view = self.main_view.get_multiple_selection_list_view()
        self.assertThat(list_view.count, Eventually(Equals(1)))
        # verify label text
        self.main_view.get_message('hello from Ubuntu')

        # switch back to main page with thread list
        self.main_view.close_osk()
        self.main_view.go_back()

        # verify the main page with the contacts that have sent messages is
        # visible
        self.assertThat(self.thread_list.visible, Eventually(Equals(True)))

        # verify a message in the thread list
        self.assertThat(self.thread_list.count, Equals(1))
        # verify our number
        self.thread_list.select_single('Label', text='123')
        # verify our text
        self.thread_list.select_single('Label', text='hello from Ubuntu')
        # use select button in toolbar
        self.main_view.click_select_button()
        # click cancel button
        self.main_view.click_cancel_dialog_button()
        # wait for slow emulator
        time.sleep(5)
        # verify our number was not deleted
        self.thread_list.select_single('Label', text='123')
        # verify our text was not deleted
        self.thread_list.select_single('Label', text='hello from Ubuntu')

    def test_delete_thread_from_main_view(self):
        """Verify we can delete a message thread"""
        self.main_view.click_new_message_button()
        #verify the thread list page is not visible
        self.assertThat(self.thread_list.visible, Eventually(Equals(False)))

        # type contact/number
        phone_num = 123
        self.main_view.type_contact_phone_num(phone_num)

        # type message
        message = 'hello from Ubuntu'
        self.main_view.type_message(message)

        # send
        self.main_view.click_send_button()

        # verify that we get a bubble with our message
        list_view = self.main_view.get_multiple_selection_list_view()
        self.assertThat(list_view.count, Eventually(Equals(1)))
        # verify label text
        self.main_view.get_message('hello from Ubuntu')

        # switch back to main page with thread list
        self.main_view.close_osk()
        self.main_view.go_back()

        # verify the main page with the contacts that have sent messages is
        # visible
        self.assertThat(self.thread_list.visible, Eventually(Equals(True)))

        # verify a message in the thread list
        self.assertThat(self.thread_list.count, Equals(1))
        # verify our number
        mess_thread = self.thread_list.select_single('Label', text='123')
        # verify our text
        self.thread_list.select_single('Label', text='hello from Ubuntu')
        # use select button in toolbar
        self.main_view.click_select_button()
        # click thread we want to delete
        self.pointing_device.click_object(mess_thread)
        # click cancel button
        self.main_view.click_delete_dialog_button()
        # verify our text was deleted
        mess_thread.wait_until_destroyed()

    def test_delete_message_thread_swipe_right(self):
        """Verify we can delete a message thread by swiping right"""
        # receive an sms message
        self.main_view.receive_sms('0815', 'hello to Ubuntu')

        # verify that we got the message
        self.assertThat(self.thread_list.count, Eventually(Equals(1)))

        # delete thread by swiping
        self.main_view.delete_thread('0815')
        self.assertThat(self.thread_list.count, Eventually(Equals(0)))

    def test_delete_message_swipe_right(self):
        """Verify we can delete a message by swiping right"""
        self.main_view.click_new_message_button()
        self.assertThat(self.thread_list.visible, Eventually(Equals(False)))

        # type address number
        phone_num = '555-555-4321'
        self.main_view.type_contact_phone_num(phone_num)
        # type message
        message = 'delete me okay'
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
        """Verify we can delete a message thread by swiping left"""
        # receive an sms message
        self.main_view.receive_sms('0815', 'hello to Ubuntu')

        # verify that we got the message
        self.assertThat(self.thread_list.count, Eventually(Equals(1)))

        # delete thread by swiping
        self.main_view.delete_thread('0815', direction='left')
        self.assertThat(self.thread_list.count, Eventually(Equals(0)))

    def test_delete_message_swipe_left(self):
        """Verify we can delete a message by swiping left"""
        self.main_view.click_new_message_button()
        self.assertThat(self.thread_list.visible, Eventually(Equals(False)))

        # type address number
        phone_num = '555-555-4321'
        self.main_view.type_contact_phone_num(phone_num)
        # type message
        message = 'delete me okay'
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


class MessagingTestCaseWithExistingThread(BaseMessagingTestCase):

    def setUp(self):
        super(MessagingTestCaseWithExistingThread, self).setUp()
        self.main_page = self.main_view.select_single(emulators.MainPage)
        self.number = '5555559876'
        self.messages = self.receive_messages()

    def receive_messages(self):
        # send 3 messages. Reversed because on the QML, the one with the
        # 0 index is the latest received.
        messages = []
        message_indexes = list(reversed(range(3)))
        for index in message_indexes:
            message_text = 'test message {}'.format(index)
            self.main_view.receive_sms(
                self.number, message_text)
            time.sleep(1)
            messages.append(message_text)
        # Wait for the thread.
        self.assertThat(
            self.main_page.get_thread_count, Eventually(Equals(1)))
        return messages

    def test_delete_multiple_messages(self):
        """Verify we can delete multiple messages"""
        messages_page = self.main_page.open_thread(self.number)

        messages_page.select_messages(1, 2)
        messages_page.delete()

        remaining_messages = messages_page.get_messages()
        self.assertThat(remaining_messages, HasLength(1))
        _, remaining_message_text = remaining_messages[0]
        self.assertEqual(
            remaining_message_text, self.messages[0])

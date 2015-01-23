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

import subprocess
import time

from autopilot.matchers import Eventually
from testtools.matchers import Equals, HasLength

from messaging_app import emulators
from messaging_app import fixture_setup
from messaging_app import helpers
from messaging_app.tests import MessagingAppTestCase

import ubuntuuitoolkit


class BaseMessagingTestCase(MessagingAppTestCase):

    def setUp(self):

        test_setup = fixture_setup.MessagingTestEnvironment()
        self.useFixture(test_setup)

        super(BaseMessagingTestCase, self).setUp()

        # no initial messages
        self.thread_list = self.app.select_single(objectName='threadList')
        self.assertThat(self.thread_list.visible, Equals(True))
        self.assertThat(self.thread_list.count, Equals(0))

    def tearDown(self):
        super(BaseMessagingTestCase, self).tearDown()

        # on desktop, notify-osd may generate persistent popups (like for "SMS
        # received"), don't make that stay around for the tests
        subprocess.call(['pkill', '-f', 'notify-osd'])


class TestMessaging(BaseMessagingTestCase):
    """Tests for the communication panel."""

    def test_helper_get_contact_list_view(self):
        """test get_contact_list_view() helper is working"""
        # open the chat window
        self.main_view.start_new_message()
        self.main_view.click_add_contact_icon()

        # pop up the contact list to choose recipient
        contact_view = self.main_view.get_contact_list_view()
        self.assertThat(contact_view.visible, Eventually(Equals(True)))

    def test_write_new_message_to_group(self):
        recipient_list = ["123", "321"]
        self.main_view.start_new_message()

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
        helpers.receive_sms('0815', 'hello to Ubuntu')

        # verify that we got the message
        self.assertThat(self.thread_list.count, Eventually(Equals(1)))

        # verify number
        self.thread_list.select_single('Label', text='0815')
        time.sleep(1)  # make it visible to human users for a sec
        # verify text
        self.thread_list.select_single('Label', text='hello to Ubuntu')

    def test_write_new_message(self):
        """Verify we can write and send a new text message"""
        phone_num = '123'
        message = 'hello from Ubuntu'
        self.main_view.send_message(phone_num, message)

        # switch back to main page with thread list
        self.main_view.close_osk()
        self.main_view.go_back()

        # verify the main page with the contacts that have sent messages is
        # visible
        self.assertThat(self.thread_list.visible, Eventually(Equals(True)))

        # verify a message in the thread list
        self.assertThat(self.thread_list.count, Equals(1))
        # verify our number
        thread = self.main_view.get_thread_from_number(phone_num)
        self.assertThat(thread.phoneNumber, Equals(phone_num))
        # verify our text
        thread.wait_select_single('Label', text=message)

    def test_deleting_message_long_press(self):
        """Verify we can delete a message with a long press on the message"""
        phone_num = '555-555-4321'
        message = 'delete me'
        bubble = self.main_view.send_message(phone_num, message)

        self.main_view.close_osk()

        # long press on bubble
        self.main_view.long_press(bubble)

        # select delete button
        self.main_view.click_messages_header_delete()

        # verify message is deleted
        bubble.wait_until_destroyed()

    def test_cancel_deleting_message_long_press(self):
        """Verify we can cancel deleting a message with a long press"""
        phone_num = '5555551234'
        message = 'do not delete'
        bubble = self.main_view.send_message(phone_num, message)

        self.main_view.close_osk()

        # long press on bubble and verify cancel button does not delete message
        self.main_view.long_press(bubble)
        self.main_view.click_messages_header_cancel()
        time.sleep(5)  # on a slow machine it might return a false positive
        # the bubble must exist
        bubble = self.main_view.get_message(message)

    def test_open_received_message(self):
        """Verify we can open a txt message we have received"""
        number = '5555555678'
        message = 'open me'
        # receive message
        helpers.receive_sms(number, message)
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

    def test_header_delete_message(self):
        """Verify we can use the toolbar to delete a message"""
        phone_num = '555-555-4321'
        message = 'delete me'
        bubble = self.main_view.send_message(phone_num, message)

        self.main_view.close_osk()

        # press on select button and message then delete
        self.main_view.enable_messages_selection_mode()
        self.pointing_device.click_object(bubble)
        self.main_view.click_messages_header_delete()
        # verify messsage is gone
        bubble.wait_until_destroyed()

    def test_delete_message_without_selecting_a_message(self):
        """Verify we only delete messages that have been selected"""
        phone_num = '555-555-4321'
        message = 'delete me'
        self.main_view.send_message(phone_num, message)

        self.main_view.close_osk()

        # press on select button then delete
        self.main_view.enable_messages_selection_mode()

        # click the delete button
        self.main_view.click_messages_header_delete()

        # verify messsage is not gone
        time.sleep(5)  # wait 5 seconds, the emulator is slow
        list_view = self.main_view.get_multiple_selection_list_view()
        list_view.select_single("Label", text=message)

    def test_receive_text_with_letters_in_phone_number(self):
        """verify we can receive a text message with letters for a phone #"""
        number = 'letters'
        message = 'open me'
        # receive message
        helpers.receive_sms(number, message)
        self.assertThat(self.thread_list.count, Eventually(Equals(1)))
        # click message thread
        search_thread = self.thread_list.wait_select_single(
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
        phone_num = '123'
        message = 'hello from Ubuntu'
        self.main_view.send_message(phone_num, message)

        # switch back to main page with thread list
        self.main_view.close_osk()
        self.main_view.go_back()

        # verify the main page with the contacts that have sent messages is
        # visible
        self.assertThat(self.thread_list.visible, Eventually(Equals(True)))

        # verify a message in the thread list
        self.assertThat(self.thread_list.count, Equals(1))
        # verify our number
        thread = self.main_view.get_thread_from_number(phone_num)
        self.assertThat(thread.phoneNumber, Equals(phone_num))
        # verify our text
        thread.select_single('Label', text=message)
        # use select button in toolbar
        self.main_view.enable_threads_selection_mode()
        # click cancel button
        self.main_view.click_threads_header_cancel()
        # verify our number was not deleted
        thread = self.main_view.get_thread_from_number(phone_num)
        self.assertThat(thread.phoneNumber, Equals(phone_num))
        # verify our text was not deleted
        thread.select_single('Label', text=message)

    def test_delete_thread_from_main_view(self):
        """Verify we can delete a message thread"""
        phone_num = '123'
        message = 'hello from Ubuntu'
        self.main_view.send_message(phone_num, message)

        # switch back to main page with thread list
        self.main_view.close_osk()
        self.main_view.go_back()

        # verify the main page with the contacts that have sent messages is
        # visible
        self.assertThat(self.thread_list.visible, Eventually(Equals(True)))

        # verify a message in the thread list
        self.assertThat(self.thread_list.count, Equals(1))
        # verify our number
        mess_thread = self.main_view.get_thread_from_number(phone_num)
        # verify our text
        self.thread_list.select_single('Label', text=message)
        # use select button in toolbar
        self.main_view.enable_threads_selection_mode()
        # click thread we want to delete
        self.pointing_device.click_object(mess_thread)
        # click cancel button
        self.main_view.click_threads_header_delete()
        # verify our text was deleted
        mess_thread.wait_until_destroyed()

    def test_delete_message_thread_swipe_right(self):
        """Verify we can delete a message thread by swiping right"""
        # receive an sms message
        helpers.receive_sms('0815', 'hello to Ubuntu')

        # verify that we got the message
        self.assertThat(self.thread_list.count, Eventually(Equals(1)))

        # delete thread by swiping
        self.main_view.delete_thread('0815')
        self.assertThat(self.thread_list.count, Eventually(Equals(0)))

    def test_delete_message_swipe_right(self):
        """Verify we can delete a message by swiping right"""
        phone_num = '555-555-4321'
        message = 'delete me okay'
        self.main_view.send_message(phone_num, message)

        # delete message
        self.main_view.delete_message(message)
        list_view = self.main_view.get_multiple_selection_list_view()
        self.assertThat(list_view.count, Eventually(Equals(0)))

    def test_search_for_message(self):
        # receive an sms message
        helpers.receive_sms('08151', 'Ubuntu')
        helpers.receive_sms('08152', 'Ubuntu1')
        helpers.receive_sms('08153', 'Ubuntu2')
        helpers.receive_sms('08154', 'Ubuntu22')
        helpers.receive_sms('08155', 'Ubuntu23')


        # verify that we got the message
        self.assertThat(self.thread_list.count, Eventually(Equals(5)))
        threads = self.thread_list.select_many('ThreadDelegate')

        self.main_view.click_header_action('searchAction')
        text_field = self.main_view.select_single(
            ubuntuuitoolkit.TextField,
            objectName='searchField')
 
        #self.keyboard.type(str("Ubuntu2"), delay=0.2)
        text_field.write('Ubuntu2')

        # time to perform the search
        time.sleep(2)
        count = 0
        for thread in threads:
            if thread.height != 0:
                count+=1

        self.assertThat(count, Equals(3))

        text_field.clear()

        text_field.write('Ubuntu1')

        # time to perform the search
        time.sleep(2)
        count = 0
        for thread in threads:
            if thread.height != 0:
                count+=1

        self.assertThat(count, Equals(1))

        text_field.clear()

        text_field.write('Ubuntu')

        # time to perform the search
        time.sleep(2)
        count = 0
        for thread in threads:
            if thread.height != 0:
                count+=1

        self.assertThat(count, Equals(5))


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
            helpers.receive_sms(
                self.number, message_text)
            time.sleep(1)
            # Prepend to make sure that the indexes match.
            messages.insert(0, message_text)
        # Wait for the thread.
        self.assertThat(
            self.main_page.get_thread_count, Eventually(Equals(1)))
        return messages

    def test_delete_multiple_messages(self):
        """Verify we can delete multiple messages"""
        messages_page = self.main_page.open_thread(self.number)

        self.main_view.enable_messages_selection_mode()
        messages_page.select_messages(1, 2)

        # Wait a few seconds before clicking the header
        # to make sure the OSD is already gone
        # FIXME: check if there is a better way to detect OSD visibility
        time.sleep(10)
        self.main_view.click_messages_header_delete()

        remaining_messages = messages_page.get_messages()
        self.assertThat(remaining_messages, HasLength(1))
        _, remaining_message_text = remaining_messages[0]
        self.assertEqual(
            remaining_message_text, self.messages[0])


class MessagingTestCaseWithArgument(MessagingAppTestCase):

    def setUp(self):
        test_setup = fixture_setup.MessagingTestEnvironment()
        self.useFixture(test_setup)

        super(MessagingTestCaseWithArgument, self).setUp(
            parameter="message:///5555559876?text=text%20message")

    def test_launch_app_with_predefined_text(self):
        self.messages_view = self.main_view.select_single(
            emulators.Messages,
            text='text message')

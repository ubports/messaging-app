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

import time
import dbus
import os

from autopilot.matchers import Eventually
from testtools.matchers import Equals, HasLength, Not
from testtools import skip

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
        phone_num = '0815'
        message = 'hello to Ubuntu'
        helpers.receive_sms(phone_num, message)

        # verify that we got the message
        self.assertThat(self.thread_list.count, Eventually(Equals(1)))

        self.verify_thread(phone_num, message)

    def test_write_new_message(self):
        """Verify we can write and send a new text message"""
        phone_num = '123'
        message = 'hello from Ubuntu'
        self.main_view.send_message([phone_num], message)

        # switch back to main page with thread list
        self.main_view.close_osk()
        self.main_view.go_back()

        # verify the main page with the contacts that have sent messages is
        # visible
        self.assertThat(self.thread_list.visible, Eventually(Equals(True)))

        # verify a message in the thread list
        self.assertThat(self.thread_list.count, Equals(1))
        # verify the thread
        self.verify_thread(phone_num, message)

    def test_deleting_message_long_press(self):
        """Verify we can delete a message with a long press on the message"""
        phone_num = '555-555-4321'
        message = 'delete me'
        self.main_view.send_message([phone_num], message)
        self.main_view.close_osk()

        # get bubble after close the osk to make sure that it has the
        # new position
        bubble = self.main_view.get_message(message)
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
        self.main_view.send_message([phone_num], message)

        self.main_view.close_osk()
        # get bubble after close the osk to make sure that it has the
        # new position
        bubble = self.main_view.get_message(message)

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
        mess_thread = self.verify_thread(number, message)
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
        bubble = self.main_view.send_message([phone_num], message)

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
        self.main_view.send_message([phone_num], message)

        self.main_view.close_osk()

        # press on select button then delete
        self.main_view.enable_messages_selection_mode()

        # click the delete button
        self.main_view.click_messages_header_delete()

        # verify messsage is not gone
        time.sleep(5)  # wait 5 seconds, the emulator is slow
        self.main_view.get_message(message)

    def test_receive_text_with_letters_in_phone_number(self):
        """verify we can receive a text message with letters for a phone #"""
        number = 'letters'
        message = 'open me'
        # receive message
        helpers.receive_sms(number, message)
        self.assertThat(self.thread_list.count, Eventually(Equals(1)))
        # click message thread
        # phonesim sends text with number as letters@
        mess_thread = self.main_view.get_thread_from_number('letters@')
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
        self.main_view.send_message([phone_num], message)

        # switch back to main page with thread list
        self.main_view.close_osk()
        self.main_view.go_back()

        # verify the main page with the contacts that have sent messages is
        # visible
        self.assertThat(self.thread_list.visible, Eventually(Equals(True)))

        # verify a message in the thread list
        self.assertThat(self.thread_list.count, Equals(1))
        # verify our number
        self.verify_thread(phone_num, message)
        # use select button in toolbar
        self.main_view.enable_threads_selection_mode()
        # click cancel button
        self.main_view.click_threads_header_cancel()
        # verify the thread was not deleted
        self.verify_thread(phone_num, message)

    def test_delete_thread_from_main_view(self):
        """Verify we can delete a message thread"""
        phone_num = '123'
        message = 'hello from Ubuntu'
        self.main_view.send_message([phone_num], message)

        # switch back to main page with thread list
        self.main_view.close_osk()
        self.main_view.go_back()

        # verify the main page with the contacts that have sent messages is
        # visible
        self.assertThat(self.thread_list.visible, Eventually(Equals(True)))

        # verify a message in the thread list
        self.assertThat(self.thread_list.count, Equals(1))
        # verify the thread
        mess_thread = self.verify_thread(phone_num, message)
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
        self.main_view.send_message([phone_num], message)

        # delete message
        self.main_view.delete_message(message)
        list_view = self.main_view.get_multiple_selection_list_view()
        self.assertThat(list_view.count, Eventually(Equals(0)))

    # FIXME: copy and use MockNotificationSystem fixture from dialer-app
    # once bug #1453958 is fixed
    @skip("Disabled due to bug #1453958")
    def test_check_multiple_messages_received(self):
        """Verify that received messages are correctly displayed"""
        main_page = self.main_view.select_single(emulators.MainPage)
        recipient = '123456'
        helpers.receive_sms(recipient, 'first message')

        # wait for the thread
        main_page.get_thread_from_number(recipient)
        messages_page = main_page.open_thread(recipient)

        for i in list(reversed(range(10))):
            helpers.receive_sms(recipient, 'message %s' % i)

        list_view = messages_page.get_list_view()
        self.assertThat(list_view.count, Eventually(Equals(11)))

        messages = messages_page.get_messages()

        for i in range(10):
            expectedMessage = 'message %s' % i
            self.assertThat(messages[i][1], Equals(expectedMessage))

    def test_open_new_conversation_with_group_participant(self):
        recipient_list = ["123", "321"]
        self.main_view.send_message(recipient_list, "hello from Ubuntu")
        self.main_view.click_header_action('groupChatAction')

        participant = self.main_view.select_single(
            objectName='participant1')
        self.pointing_device.click_object(participant)

        # We use 'title' here because participants is variant and not
        # accessible from here
        self.main_view.wait_select_single(emulators.Messages,
                                          title=recipient_list[1])

    def test_messages_with_color_name_ids(self):
        """Verify that we can open threads with numbers matching color names"""
        # receive an sms message
        phone_num = 'Orange'
        message = 'hello to Ubuntu'
        helpers.receive_sms(phone_num, message)

        # verify that we got the message
        self.assertThat(self.thread_list.count, Eventually(Equals(1)))

        # verify thread
        self.verify_thread(phone_num, message)


class MessagingTestCaseWithExistingThread(MessagingAppTestCase):

    def setUp(self):
        test_setup = fixture_setup.MessagingTestEnvironment(
            use_testdata_db=True)
        self.useFixture(test_setup)

        super(MessagingTestCaseWithExistingThread, self).setUp()
        self.main_page = self.main_view.select_single(emulators.MainPage)
        self.number = '08154'

    def receive_messages(self, count=3):
        # send the required number of messages. Reversed because on the QML,
        # the one with the 0 index is the latest received.
        messages = []
        message_indexes = list(reversed(range(count)))
        for index in message_indexes:
            message_text = 'test message {}'.format(index)
            helpers.receive_sms(
                self.number, message_text)
            time.sleep(1)
            # Prepend to make sure that the indexes match.
            messages.insert(0, message_text)
        # Wait for the thread.
        self.main_page.get_thread_from_number(self.number)
        return messages

    def test_delete_multiple_messages(self):
        """Verify we can delete multiple messages"""
        messages_page = self.main_page.open_thread(self.number)
        messages = messages_page.get_messages()

        self.main_view.enable_messages_selection_mode()
        messages_page.select_messages(1, 2)

        self.main_view.click_messages_header_delete()

        remaining_messages = messages_page.get_messages()
        self.assertThat(remaining_messages, HasLength(1))
        remaining_message = remaining_messages[0]
        self.assertEqual(
            remaining_message, messages[0])

    def test_scroll_to_new_message(self):
        """Verify that the view is scrolled to display a new message"""
        # use the number of an existing thread to avoid OSD problems
        self.number = '08155'
        messages_page = self.main_page.open_thread(self.number)

        # scroll the list to display older messages
        messages_page.scroll_list()

        # now receive a new message
        self.receive_messages(1)

        # and make sure that the list gets scrolled to the new message again
        list_view = messages_page.get_list_view()
        self.assertThat(list_view.atYEnd, Eventually(Equals(True)))


class MessagingTestSearch(MessagingAppTestCase):

    def setUp(self):
        test_setup = fixture_setup.MessagingTestEnvironment(
            use_testdata_db=True)
        self.useFixture(test_setup)

        super(MessagingTestSearch, self).setUp()
        self.thread_list = self.app.select_single(objectName='threadList')

    def test_search_for_message(self):
        def count_visible_threads(threads):
            count = 0
            for thread in threads:
                if thread.height != 0:
                    count += 1
            return count

        # verify that we got the messages
        self.assertThat(self.thread_list.count, Eventually(Equals(5)))
        threads = self.thread_list.select_many('ThreadDelegate')

        # tap search
        self.main_view.click_header_action('searchAction')
        text_field = self.main_view.select_single(
            ubuntuuitoolkit.TextField,
            objectName='searchField')

        text_field.write('Ubuntu2')
        self.assertThat(
            lambda: count_visible_threads(threads), Eventually(Equals(3)))

        text_field.clear()
        text_field.write('Ubuntu1')
        self.assertThat(
            lambda: count_visible_threads(threads), Eventually(Equals(2)))

        text_field.clear()
        text_field.write('Ubuntu')
        self.assertThat(
            lambda: count_visible_threads(threads), Eventually(Equals(5)))

        text_field.clear()
        text_field.write('08154')
        self.assertThat(
            lambda: count_visible_threads(threads), Eventually(Equals(1)))

        text_field.clear()
        text_field.write('%')
        # as we are testing for items NOT to appear, there is no other way
        # other than sleeping for awhile before checking if the threads are
        # visible
        time.sleep(5)
        self.assertThat(count_visible_threads(threads), Equals(0))


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


class MessagingTestCaseWithArgumentNoSlashes(MessagingAppTestCase):

    def setUp(self):
        test_setup = fixture_setup.MessagingTestEnvironment()
        self.useFixture(test_setup)

        super(MessagingTestCaseWithArgumentNoSlashes, self).setUp(
            parameter="message:5555559876?text=text%20message")

    def test_launch_app_with_predefined_text_no_slashes(self):
        self.messages_view = self.main_view.select_single(
            emulators.Messages,
            firstParticipantId='5555559876',
            text='text message')


class MessagingTestSettings(MessagingAppTestCase):

    def setUp(self):
        test_setup = fixture_setup.MessagingTestEnvironment(
            use_temporary_user_conf=False)
        self.useFixture(test_setup)

        super(MessagingTestSettings, self).setUp()

    def test_mms_enabled_settings(self):
        settingsPage = self.main_view.open_settings_page()
        self.assertThat(settingsPage.visible, Eventually(Equals(True)))
        option = settingsPage.get_mms_enabled()

        proxy = dbus.SystemBus().get_object(
            'org.freedesktop.Accounts',
            '/org/freedesktop/Accounts/User%d' % os.getuid())

        properties_manager = dbus.Interface(proxy,
                                            'org.freedesktop.DBus.Properties')

        # read the current value and make sure the checkbox reflects it
        settingsValue = properties_manager.Get(
            'com.ubuntu.touch.AccountsService.Phone',
            'MmsEnabled')

        self.assertThat(option.checked, Eventually(Equals(settingsValue)))

        # now toggle it and check that the value changes
        oldValue = settingsValue
        settingsPage.toggle_mms_enabled()
        time.sleep(2)
        option = settingsPage.get_mms_enabled()
        self.assertThat(option.checked, Eventually(Not(Equals(oldValue))))

        # give it some time
        time.sleep(2)

        settingsValue = properties_manager.Get(
            'com.ubuntu.touch.AccountsService.Phone',
            'MmsEnabled'
        )
        self.assertThat(option.checked,
                        Eventually(Equals(settingsValue)))

        # just reset it to the previous value
        settingsPage.toggle_mms_enabled()


class MessagingTestSwipeToDeleteDemo(MessagingAppTestCase):

    def setUp(self):
        test_setup = fixture_setup.MessagingTestEnvironment(
            use_empty_config=True)
        self.useFixture(test_setup)

        super(MessagingTestSwipeToDeleteDemo, self).setUp()

    def test_write_new_message_with_tutorial(self):
        """Verify if the tutorial appears after send a message"""
        phone_num = '123'
        message = 'hello from Ubuntu'
        self.main_view.send_message([phone_num], message)
        self.main_view.close_osk()

        swipe_item_demo = self.main_view.get_swipe_item_demo()
        self.assertThat(swipe_item_demo.enabled, Eventually(Equals(True)))
        self.assertThat(swipe_item_demo.necessary, Eventually(Equals(True)))
        got_it_button = swipe_item_demo.select_single(
            'Button',
            objectName='gotItButton')
        self.pointing_device.click_object(got_it_button)
        self.assertThat(swipe_item_demo.enabled, Eventually(Equals(False)))
        self.assertThat(swipe_item_demo.necessary, Eventually(Equals(False)))

    def test_receive_new_message_with_tutorial(self):
        """Verify if the tutorial appears after receive a message"""
        thread_list = self.app.select_single(objectName='threadList')
        self.assertThat(thread_list.visible, Equals(True))
        self.assertThat(thread_list.count, Equals(0))

        number = '5555555678'
        message = 'open me'
        # receive message
        helpers.receive_sms(number, message)
        # verify that we got the message
        self.assertThat(thread_list.count, Eventually(Equals(1)))

        # click message thread
        mess_thread = self.verify_thread(number, message)
        self.pointing_device.click_object(mess_thread)

        swipe_item_demo = self.main_view.get_swipe_item_demo()
        self.assertThat(swipe_item_demo.enabled, Eventually(Equals(True)))
        self.assertThat(swipe_item_demo.necessary, Eventually(Equals(True)))
        got_it_button = swipe_item_demo.select_single(
            'Button',
            objectName='gotItButton')
        self.pointing_device.click_object(got_it_button)
        self.assertThat(swipe_item_demo.enabled, Eventually(Equals(False)))
        self.assertThat(swipe_item_demo.necessary, Eventually(Equals(False)))

    def test_write_new_message_with_tutorial_no_network(self):
        """Verify if the tutorial appears and is not stuck by the popup"""
        helpers.set_network_status("unregistered")
        phone_num = '123'
        message = 'hello from Ubuntu'
        self.main_view.send_message([phone_num], message, False)
        self.main_view.close_osk()

        closeButton = self.main_view.wait_select_single(
            'Button',
            objectName='closeNoNetworkDialog')
        self.pointing_device.click_object(closeButton)

        closeButton.wait_until_destroyed()

        swipe_item_demo = self.main_view.get_swipe_item_demo()
        self.assertThat(swipe_item_demo.enabled, Eventually(Equals(True)))
        self.assertThat(swipe_item_demo.necessary, Eventually(Equals(True)))
        got_it_button = swipe_item_demo.select_single(
            'Button',
            objectName='gotItButton')
        self.pointing_device.click_object(got_it_button)
        self.assertThat(swipe_item_demo.enabled, Eventually(Equals(False)))
        self.assertThat(swipe_item_demo.necessary, Eventually(Equals(False)))


class MessagingTestSendAMessageFromContactView(MessagingAppTestCase):

    def setUp(self):
        test_setup = fixture_setup.MessagingTestEnvironment()
        self.useFixture(test_setup)

        qcontact_memory = fixture_setup.UseMemoryContactBackend()
        self.useFixture(qcontact_memory)

        preload_vcards = fixture_setup.PreloadVcards()
        self.useFixture(preload_vcards)

        super(MessagingTestSendAMessageFromContactView, self).setUp()

    def test_message_a_contact_from_contact_view(self):
        # start a new message
        self.main_view.start_new_message()
        self.main_view.click_add_contact_icon()

        # select the first phone from first contact in the list
        new_recipient_page = self.main_view.get_new_recipient_page()
        contact_view_page = new_recipient_page.open_contact(0)
        contact_view_page.message_phone(0)

        # message page became active again
        messages_page = self.main_view.get_messages_page()
        self.assertThat(messages_page.active, Eventually(Equals(True)))

        # check if the contact was added in the recipient list
        multircpt_entry = self.main_view.get_newmessage_multirecipientinput()
        self.assertThat(
            multircpt_entry.get_properties()['recipientCount'],
            Eventually(Equals(1))
        )

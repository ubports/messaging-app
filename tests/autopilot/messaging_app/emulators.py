# -*- Mode: Python; coding: utf-8; indent-tabs-mode: nil; tab-width: 4 -*-
# Copyright 2013, 2014 Canonical
#
# This file is part of messaging-app.
#
# messaging-app is free software: you can redistribute it and/or modify it
# under the terms of the GNU General Public License version 3, as published
# by the Free Software Foundation.


"""Messaging app autopilot emulators."""

import logging
import subprocess
import time

from autopilot import logging as autopilot_logging
from autopilot.input import Keyboard
from autopilot.platform import model
from autopilot.introspection.dbus import StateNotFoundError
from ubuntuuitoolkit import emulators as toolkit_emulators
from ubuntuuitoolkit._custom_proxy_objects import _common
from address_book_app import address_book


logger = logging.getLogger(__name__)


class EmulatorException(Exception):
        """Exception raised when there is an error with the emulator."""


class MainView(toolkit_emulators.MainView):
    def __init__(self, *args):
        super(MainView, self).__init__(*args)
        self.pointing_device = toolkit_emulators.get_pointing_device()
        self.keyboard = Keyboard.create()
        self.logger = logging.getLogger(__name__)

    def get_pagestack(self):
        """Return PageStack with objectName mainStack"""
        return self.select_single("PageStack", objectName="mainStack")

    def get_thread_from_number(self, phone_number):
        """Return thread from number

        :parameter phone_number: the phone_number of message thread

        """
        return self.wait_select_single(ThreadDelegate,
                                       phoneNumber=phone_number)

    def get_message(self, text):
        """Return message from text

        :parameter text: the text or date of the label in the message

        """

        time.sleep(2)  # message is not always found on slow emulator
        for message in self.select_many(MessageDelegateFactory):
            for item in message.select_many('Label'):
                if "text" in item.get_properties():
                    if item.get_properties()['text'] == text:
                        return message
        raise EmulatorException('Could not find message with the text '
                                '{}'.format(text))

    def get_label(self, text):
        """Return label from text

        :parameter text: the text of the label to return
        """

        return self.select_single('Label', visible=True, text=text)

    def get_main_page(self):
        """Return messages with objectName messagesPage"""

        return self.wait_select_single("MainPage", objectName="")

    def go_back(self):
        """Click back button from toolbar on messages page"""
        self.get_header().click_custom_back_button()

    def click_header_action(self, action):
        """Click the action 'action' on the header"""
        self.get_header().click_action_button(action)

    # messages page
    def get_messages_page(self):
        """Return messages with objectName messagesPage"""

        return self.wait_select_single("Messages", objectName="messagesPage",
                                       active=True)

    def get_newmessage_textfield(self):
        """Return TextField with objectName newPhoneNumberField"""

        return self.select_single(
            "TextField",
            objectName="contactSearchInput",
        )

    def get_multiple_selection_list_view(self):
        """Return MultipleSelectionListView from the messages page"""

        page = self.get_messages_page()
        return page.select_single('MessagesListView')

    def get_newmessage_multirecipientinput(self):
        """Return MultiRecipientInput from the messages page"""
        return self.select_single(
            "MultiRecipientInput",
            objectName="multiRecipient",
        )

    def get_newmessage_textarea(self):
        """Return TextArea with blank objectName"""

        return self.get_messages_page().select_single(
            'TextArea',
            objectName='messageTextArea')

    def get_send_button(self):
        """Return Button with text Send"""

        return self.get_messages_page().select_single('Button',
                                                      objectName='sendButton')

    def get_toolbar_back_button(self):
        """Return toolbar button with objectName back_toolbar_button"""

        return self.select_single(
            'ActionItem',
            objectName='back_toolbar_button',
        )

    def get_toolbar_select_messages_button(self):
        """Return toolbar button with objectName selectMessagesButton"""

        return self.select_single(
            'ActionItem',
            objectName='selectMessagesButton',
        )

    def get_toolbar_add_contact_button(self):
        """Return toolbar button with objectName addContactButton"""

        return self.select_single(
            'ActionItem',
            objectName='addContactButton',
        )

    def get_toolbar_add_contact_icon(self):
        """Return toolbar icon to add contact"""

        return self.select_single(
            'PageHeadButton',
            objectName='contactList_header_button',
        )

    def click_add_contact_icon(self):
        """Click the add contact icon"""

        icon = self.get_toolbar_add_contact_icon()
        self.pointing_device.click_object(icon)

    def get_contact_list_view(self):
        """Returns the ContactListView object"""
        return self.select_single(
            'ContactListView',
            objectName='newRecipientList'
        )

    def get_toolbar_contact_profile_button(self):
        """Return toolbar button with objectName contactProfileButton"""

        return self.select_single(
            'ActionItem',
            objectName='contactProfileButton',
        )

    def get_toolbar_contact_call_button(self):
        """Return toolbar button with objectName contactCallButton"""

        return self.select_single(
            'ActionItem',
            objectName='contactCallButton',
        )

    def get_dialog_buttons(self, visible=True):
        """Return DialogButtons

        :parameter visible: the visible state of the dialog button
        """

        if visible:
            return self.wait_select_single('DialogButtons', visible=True)
        else:
            return self.select_many('DialogButtons', visible=False)

    def long_press(self, obj):
        """long press on object because press_duration is not honored on touch
        see bug #1268782

        :parameter obj: the object to long press on
        """

        self.pointing_device.move_to_object(obj)
        self.pointing_device.press()
        time.sleep(3)
        self.pointing_device.release()

    def type_message(self, message):
        """Select and type message in new message text area in messages page

        :parameter message: the message to type
        """

        text_entry = self.get_newmessage_textarea()
        self.pointing_device.click_object(text_entry)
        text_entry.focus.wait_for(True)
        time.sleep(.3)
        self.keyboard.type(str(message), delay=0.2)
        self.logger.info(
            'typed: "{}" expected: "{}"'.format(text_entry.text, message))

    def type_contact_phone_num(self, num_or_contact):
        """Select and type phone number or contact

        :parameter num_or_contact: number or contact to type
        """

        text_entry = self.get_newmessage_multirecipientinput()
        self.pointing_device.click_object(text_entry)
        text_entry.focus.wait_for(True)
        time.sleep(.3)
        self.keyboard.type(str(num_or_contact), delay=0.2)
        self.keyboard.press_and_release("Enter")
        self.logger.info(
            'typed "{}" expected "{}"'.format(
                self.get_newmessage_textfield().text, num_or_contact))

    def click_send_button(self):
        """Click the send button on the message page"""

        button = self.get_send_button()
        button.enabled.wait_for(True)
        self.pointing_device.click_object(button)
        button.enabled.wait_for(False)

    def start_new_message(self):
        """Reveal the bottom edge page to start composing a new message"""
        self.get_main_page().reveal_bottom_edge_page()

    def enable_messages_selection_mode(self):
        """Enable the selection mode on the messages page by pressing and
        holding the first item"""
        message = self.wait_select_single("MessageDelegateFactory",
                                          objectName="message0")
        self.long_press(message)

        # FIXME: there should be a better way to detect when the popover is
        # gone
        time.sleep(2)

        # and now click the message again to start with it unselected
        self.pointing_device.click_object(message)

    def enable_threads_selection_mode(self):
        """Enable the selection mode on the threads page by pressing and
        holding the first item"""
        # FIXME: there is probably a better way to do this
        thread = self.select_many("ThreadDelegate")[0]
        self.long_press(thread)
        # and now click to unselect it
        self.pointing_device.click_object(thread)

    def close_osk(self):
        """Swipe down to close on-screen keyboard"""

        # killing the maliit-server closes the OSK
        if model() is not 'Desktop':
            subprocess.call(["pkill", "maliit-server"])
            # wait for server to respawn
            time.sleep(2)

    def click_add_button(self):
        """Click add button from toolbar on messages page"""
        header = self.get_header()
        header.click_action_button("addContactAction")

    def click_call_button(self):
        """Click call button from toolbar on messages page"""
        header = self.get_header()
        header.click_action_button("contactCallAction")

    def click_back_button(self):
        """Click back button from toolbar on messages page"""

        toolbar = self.open_toolbar()
        button = toolbar.wait_select_single("ActionItem", text=u"Back")
        self.pointing_device.click_object(button)
        toolbar.animating.wait_for(False)

    def click_add_to_contact_button(self):
        """
        Click the 'Add to existing contact' button
        in the 'Save Contact' dialog.
        """
        button = self.wait_select_single('Button',
                                         objectName="addToExistingContact")
        self.pointing_device.click_object(button)

    def click_create_new_contact_button(self):
        """
        Click the 'Create new contact' button
        in the 'Save Contact' dialog
        """
        button = self.wait_select_single('Button',
                                         objectName="createNewContact")
        self.pointing_device.click_object(button)

    def click_cancel_save_button(self):
        " Click the 'Cancel' button in the 'Save Contact' dialog """
        button = self.wait_select_single('Button',
                                         objectName="cancelSave")
        self.pointing_device.click_object(button)

    def click_threads_header_delete(self):
        """Click the header action 'Delete' on Messages view"""
        self.click_header_action('selectionModeDeleteAction')

    def click_threads_header_cancel(self):
        """Click the header action 'Cancel' on Messages view"""
        self.get_header().click_custom_back_button()

    def click_messages_header_delete(self):
        """Click the header action 'Delete' on Messages view"""
        self.click_header_action('selectionModeDeleteAction')

    def click_messages_header_cancel(self):
        """Click the header action 'Cancel' on Messages view"""
        self.get_header().click_custom_back_button()

    def delete_thread(self, phone_number):
        """Delete thread containing specified phone number.

        :parameter phone_number: phone number of thread to delete
        :parameter direction: right or left, the direction to swipe to delete
        """
        thread = self.get_thread_from_number(phone_number)
        thread.swipe_to_delete()
        # wait for the animation to end
        time.sleep(1)
        thread.confirm_removal()

    def delete_message(self, text):
        """Deletes message with specified text.

        :parameter text: the text of the message you want to delete.
        :parameter direction: right or left, the direction to swipe to delete.

        """
        message = self.get_message(text)
        message.swipe_to_delete()
        message.confirm_removal()

    @autopilot_logging.log_action(logger.info)
    def send_message(self, number, message):
        """Write a new message and send it.

        :param number: number of the contact to send message to.
        :param message: the message to be sent.

        """
        self.start_new_message()
        self.type_contact_phone_num(number)
        self.type_message(message)
        old_message_count = self.get_multiple_selection_list_view().count
        self.click_send_button()

        self.get_multiple_selection_list_view().count.wait_for(
            old_message_count + 1)
        thread_bubble = self.get_message(message)

        return thread_bubble

    def _get_page(self, page_type, page_name):
        page = self.wait_select_single(
            page_type, objectName=page_name, active=True)
        return page

    def get_new_recipient_page(self):
        return self._get_page(NewRecipientPage, 'newRecipientPage')

    def get_swipe_item_demo(self):
        return self.wait_select_single(
            'SwipeItemDemo', objectName='swipeItemDemo', parentActive=True)


class PageWithBottomEdge(MainView):
    """An emulator class that makes it easy to interact with the bottom edge
       swipe page"""
    def __init__(self, *args):
        super(PageWithBottomEdge, self).__init__(*args)

    def reveal_bottom_edge_page(self):
        """Bring the bottom edge page to the screen"""
        self.bottomEdgePageLoaded.wait_for(True)
        try:
            action_item = self.wait_select_single(objectName='bottomEdgeTip')
            start_x = (action_item.globalRect.x +
                       (action_item.globalRect.width * 0.5))
            start_y = (action_item.globalRect.y +
                       (action_item.height * 0.5))
            stop_y = start_y - (self.height * 0.7)
            self.pointing_device.drag(start_x, start_y,
                                      start_x, stop_y, rate=2)
            self.isReady.wait_for(True)
        except StateNotFoundError:
            logger.error('BottomEdge element not found.')
            raise


class MainPage(PageWithBottomEdge):
    """Autopilot helper for the Main Page."""

    def get_thread_count(self):
        """Return the number of message threads."""
        return self.select_single(
            'MultipleSelectionListView', objectName='threadList').count

    @autopilot_logging.log_action(logger.info)
    def open_thread(self, participants):
        thread = self.select_single(
            ThreadDelegate, objectName='thread{}'.format(participants))
        self.pointing_device.click_object(thread)
        root = self.get_root_instance()
        return root.wait_select_single(Messages, participants=participants)


class Messages(toolkit_emulators.UbuntuUIToolkitEmulatorBase):
    """Autopilot helper for the Messages Page."""

    def get_messages_count(self):
        """Return the number of meesages."""
        return self.get_list_view().count

    @autopilot_logging.log_action(logger.info)
    def select_messages(self, *indexes):
        """Select messages.

        :param indexes: The indexes of the messages to select. The most
            recently received message has the 0 index, and the oldest message
            has the higher index.

        """
        for index in indexes:
            message_delegate = self._get_message_delegate(index)
            self.pointing_device.click_object(message_delegate)

    def scroll_list(self):
        list_view = self.get_list_view()
        x, y, width, height = list_view.globalRect
        start_x = stop_x = x + (width / 2)
        start_y = y + 10
        stop_y = y + height - 10
        self.pointing_device.drag(start_x, start_y, stop_x, stop_y)

    def _get_message_delegate(self, index):
        return self.wait_select_single(
            'MessageDelegateFactory', objectName='message{}'.format(index))

    def _long_press_to_select_message(self, message):
        # XXX We used to leave the pointing device pressed for three seconds,
        # but that failed some times on Jenkins. So now we are leaving it
        # pressed until we are in selection mode. The behavior is almost the
        # same, and if it keeps failing in Jenkins we will get more
        # information to understand the error. --elopio - 2014-03-24
        self.pointing_device.move_to_object(message)
        self.pointing_device.press()
        self.selectionMode.wait_for(True)
        self.pointing_device.release()

    def get_messages(self):
        """Return a list with the information of the messages.

        Each item of the returned list is a tuple of (date, text).

        """
        messages = []
        # TODO return the messages in the same order that they are displayed.
        # --elopio - 2014-03-14
        for index in range(self.get_messages_count()):
            message_delegate = self._get_message_delegate(index)
            date = message_delegate.select_single(
                'Label', objectName='messageDate').text
            text = message_delegate.select_single(
                'Label', objectName='messageText').text
            messages.append((date, text))
        return messages

    def get_text_area_text(self):
        return self.wait_select_single(
            'TextArea', objectName='messageTextArea').text

    def get_list_view(self):
        """Returns the messages list view"""
        return self.wait_select_single(
            'MessagesListView', objectName='messageList')


class ListItemWithActions(_common.UbuntuUIToolkitCustomProxyObjectBase):

    def confirm_removal(self):
        deleteButton = self.wait_select_single(name='delete')
        self.pointing_device.click_object(deleteButton)

    def swipe_to_delete(self):
        x, y, width, height = self.globalRect
        start_x = x + (width * 0.2)
        stop_x = x + (width * 0.8)
        start_y = stop_y = y + (height // 2)

        self.pointing_device.drag(start_x, start_y, stop_x, stop_y)

    def active_action(self, action_index):
        action_margin = ((self.actionWidth / 5) * 2)
        x_offset = ((self.actionWidth + action_margin) * action_index)
        x_offset += self.actionThreshold

        x, y, width, height = self.globalRect
        start_x = x + (width * 0.5)
        stop_x = start_x - x_offset
        start_y = stop_y = y + (height // 2)

        self.pointing_device.drag(start_x, start_y, stop_x, stop_y)


class ThreadDelegate(ListItemWithActions):
    """Autopilot helper for ThreadDelegate."""


class MessageDelegateFactory(ListItemWithActions):
    """Autopilot helper for the MessageDelegateFactory."""


class MessagingContactViewPage(address_book.ContactViewPage):
    """Autopilot custom proxy object for MessagingContactViewPage component."""

    def message_phone(self, index):
        phone_group = self.select_single(
            'ContactDetailGroupWithTypeView',
            objectName='phones')

        call_buttons = phone_group.select_many(
            "ActionButton",
            objectName="message-contact")
        self.pointing_device.click_object(call_buttons[index])


class NewRecipientPage(toolkit_emulators.UbuntuUIToolkitEmulatorBase):
    """Autopilot custom proxy object for NewRecipientPage components."""

    def _click_button(self, button):
        """Generic way to click a button"""
        self.visible.wait_for(True)
        button.visible.wait_for(True)
        self.pointing_device.click_object(button)
        return button

    def open_contact(self, index):
        contact_delegate = self._get_contact_delegate(index)
        self.pointing_device.click_object(contact_delegate)
        contact_delegate.state.wait_for('expanded')
        details_button = contact_delegate.wait_select_single(
            objectName='infoIcon')
        self.pointing_device.click_object(details_button)
        return self.get_root_instance().select_single(
            MessagingContactViewPage, objectName='contactViewPage')

    def _get_contact_delegate(self, index):
        contact_delegates = self._get_sorted_contact_delegates()
        return contact_delegates[index]

    def _get_sorted_contact_delegates(self):
        contact_delegates = self.select_many('ContactDelegate', visible=True)
        return sorted(
            contact_delegates, key=lambda delegate: delegate.globalRect.y)

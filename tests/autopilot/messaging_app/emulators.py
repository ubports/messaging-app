# -*- Mode: Python; coding: utf-8; indent-tabs-mode: nil; tab-width: 4 -*-
# Copyright 2013 Canonical
#
# This file is part of messaging-app.
#
# messaging-app is free software: you can redistribute it and/or modify it
# under the terms of the GNU General Public License version 3, as published
# by the Free Software Foundation.


"""Messaging app autopilot emulators."""

import dbus
import logging
import os
import shutil
import subprocess
import tempfile
import time

from autopilot.input import Keyboard
from autopilot.platform import model
from ubuntuuitoolkit import emulators as toolkit_emulators


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

        time.sleep(2)  # message is not always found on slow emulator
        for thread in self.select_many('ThreadDelegate'):
            for item in self.select_many('QQuickItem'):
                if "phoneNumber" in item.get_properties():
                    if item.get_properties()['phoneNumber'] == phone_number:
                        return thread
        raise EmulatorException('Could not find thread with the phone number '
                                '{}'.format(phone_number))

    def get_message(self, text):
        """Return message from text

        :parameter text: the text or date of the label in the message

        """

        time.sleep(2)  # message is not always found on slow emulator
        for message in self.select_many('MessageDelegate'):
            for item in self.select_many('Label'):
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

    #messages page
    def get_messages_page(self):
        """Return messages with objectName messagesPage"""

        return self.wait_select_single("Messages", objectName="messagesPage")

    def get_newmessage_textfield(self):
        """Return TextField with objectName newPhoneNumberField"""

        return self.select_single(
            "TextField",
            objectName="contactSearchInput",
        )

    def get_multiple_selection_list_view(self):
        """Return MultipleSelectionListView from the messages page"""

        page = self.get_messages_page()
        return page.select_single('MultipleSelectionListView')

    def get_newmessage_multirecipientinput(self):
        """Return MultiRecipientInput from the messages page"""
        return self.select_single(
            "MultiRecipientInput",
            objectName="multiRecipient",
        )

    def get_newmessage_textarea(self):
        """Return TextArea with blank objectName"""

        return self.select_single('TextArea', objectName='')

    def get_send_button(self):
        """Return Button with text Send"""

        return self.select_single('Button', text='Send')

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

    def get_header(self):
        """return header object"""

        return self.select_single('Header', objectName='MainView_Header')

    def get_dialog_buttons(self, visible=True):
        """Return DialogButtons

        :parameter visible: the visible state of the dialog button
        """

        if visible:
            return self.wait_select_single('DialogButtons', visible=True)
        else:
            return self.select_many('DialogButtons', visible=False)

    def get_visible_cancel_dialog_button(self):
        """Return dialog Button with text Cancel"""

        dialog_buttons = self.get_dialog_buttons()
        return dialog_buttons.select_single('Button', text='Cancel')

    def get_visible_delete_dialog_button(self):
        """Return dialog Button with text Delete"""

        dialog_buttons = self.get_dialog_buttons()
        return dialog_buttons.select_single('Button', text='Delete')

    def click_cancel_dialog_button(self):
        """Click on dialog button cancel"""

        button = self.get_visible_cancel_dialog_button()
        self.pointing_device.click_object(button)
        button.visible.wait_for(False)

    def click_delete_dialog_button(self):
        """Click on dialog button delete"""

        button = self.get_visible_delete_dialog_button()
        self.pointing_device.click_object(button)
        button.visible.wait_for(False)

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

    def click_new_message_button(self):
        """Click "Compose/ new message" button from toolbar on main page"""

        toolbar = self.open_toolbar()
        toolbar.click_button("newMessageButton")
        toolbar.animating.wait_for(False)

    def click_select_button(self):
        """Click select button from toolbar on main page"""

        toolbar = self.open_toolbar()
        toolbar.click_button("selectButton")
        toolbar.animating.wait_for(False)

    def click_select_messages_button(self):
        """Click select messages button from toolbar on messages page"""

        toolbar = self.open_toolbar()
        toolbar.click_button("selectMessagesButton")
        toolbar.animating.wait_for(False)

    def close_osk(self):
        """Swipe down to close on-screen keyboard"""

        # killing the maliit-server closes the OSK
        if model() is not 'Desktop':
            subprocess.call(["pkill", "maliit-server"])
            #wait for server to respawn
            time.sleep(2)

    def click_add_button(self):
        """Click add button from toolbar on messages page"""

        toolbar = self.open_toolbar()
        button = toolbar.wait_select_single("ActionItem", text=u"Add")
        self.pointing_device.click_object(button)
        toolbar.animating.wait_for(False)

    def click_call_button(self):
        """Click call button from toolbar on messages page"""

        toolbar = self.open_toolbar()
        button = toolbar.wait_select_single("ActionItem", text=u"Call")
        self.pointing_device.click_object(button)
        toolbar.animating.wait_for(False)

    def click_back_button(self):
        """Click back button from toolbar on messages page"""

        toolbar = self.open_toolbar()
        button = toolbar.wait_select_single("ActionItem", text=u"Back")
        self.pointing_device.click_object(button)
        toolbar.animating.wait_for(False)

    def delete_thread(self, phone_number, direction='right'):
        """Delete thread containing specified phone number

        :parameter phone_number: phone number of thread to delete
        :parameter direction: right or left, the direction to swipe to delete
        """

        thread = self.get_thread_from_number(phone_number)
        delete = self.swipe_to_delete(thread, direction=direction)
        delete_button = delete.wait_select_single('QQuickImage', visible=True)
        self.pointing_device.click_object(delete_button)
        thread.wait_until_destroyed()

    def delete_message(self, text, direction='right'):
        """Deletes message with specified text

        :parameter text: the text of the message you want to delete
        :parameter direction: right or left, the direction to swipe to delete
        """

        message = self.get_message(text)
        delete = self.swipe_to_delete(message, direction=direction)
        delete_button = delete.wait_select_single('QQuickImage', visible=True)
        self.pointing_device.click_object(delete_button)
        message.wait_until_destroyed()

    def swipe_to_delete(self, obj, direction='right', offset=.1):
        """Swipe and objet left or right

        :parameter direction: right or left, the direction to swipe
        :parameter offset: the ammount of space to offset at start of swipe
        """

        x, y, w, h = obj.globalRect

        s_rx = x + (w * offset)
        e_rx = w

        s_lx = w - (w * offset)
        e_lx = w * offset

        sy = y + (h / 2)

        if (direction == 'right'):
            self.pointing_device.drag(s_rx, sy, e_rx, sy)
            # wait for animation
            time.sleep(.5)
            return self.wait_select_single('QQuickItem',
                                           objectName='confirmRemovalDialog',
                                           visible=True)
        elif (direction == 'left'):
            self.pointing_device.drag(s_lx, sy, e_lx, sy)
            # wait for animation
            time.sleep(.5)
            return self.wait_select_single('QQuickItem',
                                           objectName='confirmRemovalDialog',
                                           visible=True)
        else:
            raise EmulatorException(
                'Invalid direction "{0}" used on swipe to delete function '
                'direction can be right or left'.format(direction)
            )

    def receive_sms(self, sender, text):
        """Receive an SMS based on sender number and text

        :parameter sender: phone number the message is from
        :parameter text: text you want to send in the message
        """

        # prepare and send a Qt GUI script to phonesim, over its private D-BUS
        # set up by ofono-phonesim-autostart
        script_dir = tempfile.mkdtemp(prefix="phonesim_script")
        os.chmod(script_dir, 0o755)
        with open(os.path.join(script_dir, "sms.js"), "w") as f:
            f.write("""tabSMS.gbMessage1.leMessageSender.text = "%s";
tabSMS.gbMessage1.leSMSClass.text = "1";
tabSMS.gbMessage1.teSMSText.setPlainText("%s");
tabSMS.gbMessage1.pbSendSMSMessage.click();
""" % (sender, text))

        with open("/run/lock/ofono-phonesim-dbus.address") as f:
            phonesim_bus = f.read().strip()
        bus = dbus.bus.BusConnection(phonesim_bus)
        script_proxy = bus.get_object("org.ofono.phonesim", "/")
        script_proxy.SetPath(script_dir)
        script_proxy.Run("sms.js")
        shutil.rmtree(script_dir)

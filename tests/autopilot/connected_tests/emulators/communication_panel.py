# -*- Mode: Python; coding: utf-8; indent-tabs-mode: nil; tab-width: 4 -*-
# Copyright 2012 Canonical
#
# This file is part of messaging-app.
#
# messaging-app is free software: you can redistribute it and/or modify it
# under the terms of the GNU General Public License version 3, as published
# by the Free Software Foundation.

#from connected_tests.tests import MessagingAppTestCase
from time import sleep


class CommunicationPanel(object):
    """An emulator class that makes it easy to interact with the communication
    panel.

    """
    retry_delay = 0.2
    SMS_POLLING_TIME = 5

    def __init__(self, app):
        self.app = app

    def select_single_retry(self, object_type, **kwargs):
        item = self.app.select_single(object_type, **kwargs)
        tries = 10
        while item is None and tries > 0:
            sleep(self.retry_delay)
            item = self.app.select_single(object_type, **kwargs)
            tries = tries - 1
        return item

    def select_many_retry(self, object_type, **kwargs):
        items = self.app.select_many(object_type, **kwargs)
        tries = 10
        while len(items) < 1 and tries > 0:
            sleep(self.retry_delay)
            items = self.app.select_many(object_type, **kwargs)
            tries = tries - 1
        return items

    def get_communication_searchbox(self):
        """Returns the main searchbox attached to the communication panel."""
        return self.app.select_single("TextField", objectName="messageSearchBox")

    def get_communication_searchbox_clear_button(self):
        """Returns the clear button in the main searchbox attached to the communication panel."""
        return self.get_communication_searchbox().get_children_by_type("AbstractButton")[0]

    def get_tool_bar(self):
        """Returns the toolbar in the main events view."""
        return self.app.select_single("Toolbar")

    def get_tool_button(self, index):
        """Returns the toolbar button at position `index`"""
        tool_bar = self.get_tool_bar()
        buttons = tool_bar.select_many("Button")
        return buttons[index+1]

    def get_new_message_button(self):
        """Returns 'New Message' list item."""
        tool_bar = self.get_tool_bar()
        return self.get_tool_button(0)

    def get_communication_view(self):
        """Returns the CommunicationView."""
        return self.select_single_retry("CommunicationView", objectName="communicationView")

    def get_communication_page(self):
        """Returns the Communication page"""
        return self.app.select_single('Tab', objectName='communicationsTab')

    def get_new_message_send_to_box(self):
        """Return the "To" input box for sending an sms."""
        return self.app.select_single("NewMessageHeader")

    def get_message_send_button(self):
        """Returns the send button."""
        return self.app.select_single("Button", objectName='sendMessageButton')

    def get_new_message_text_box(self):
        """Returns main message box for sending an sms."""
        return self.app.select_single("TextArea", objectName="newMessageText")

    def get_sms_item(self, index):
        """Returns the message item in the communication logs."""
        view = self.app.select_single("CommunicationView", objectName="communicationView")
        items = view.select_single("QQuickListView")
        retries = 3
        while items.count < 1 and retries != 0:
            sleep(self.retry_delay)
            items = view.select_single("QQuickListView")
            retries = retries - 1

        return items.select_many(
            "CommunicationDelegate", objectName="messageDetailItem")[items.count-index]

    def get_sms_list_item(self, index):
        """Returns the message item in the main communication view."""
        communication_panel = self.app.select_single(
            "CommunicationsPanel", objectName="communicationPanel")
        items = communication_panel.select_single("QQuickListView")
        retries = 15
        while items.count < 1 and retries != 0:
            sleep(self.SMS_POLLING_TIME)
            items = communication_panel.select_single("QQuickListView")
            retries = retries - 1

        loader = items.select_many("QQuickLoader")[items.count-index]
        return loader.select_single("CommunicationDelegate")

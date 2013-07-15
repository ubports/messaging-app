# -*- Mode: Python; coding: utf-8; indent-tabs-mode: nil; tab-width: 4 -*-
# Copyright 2012 Canonical
#
# This file is part of messaging-app.
#
# messaging-app is free software: you can redistribute it and/or modify it
# under the terms of the GNU General Public License version 3, as published
# by the Free Software Foundation.

from messaging_app.emulators.utils import Utils

class CommunicationPanel(Utils):
    """An emulator class that makes it easy to interact with the communication
    panel.

    """
    def __init__(self, app):
        Utils.__init__(self, app)

    def get_communication_searchbox(self):
        """Returns the main searchbox attached to the communication panel."""
        return self.app.select_single("TextField", objectName="messageSearchBox")

    def get_communication_searchbox_clear_button(self):
        """Returns the clear button in the main searchbox attached to the communication panel."""
        return self.get_communication_searchbox().get_children_by_type("AbstractButton")[0]

    def get_new_message_button(self):
        """Returns 'New Message' list item."""
        tool_bar = self.get_tool_bar()
        return self.get_tool_button(0)

    def get_communication_view(self):
        """Returns the CommunicationView."""
        return self.app.select_single("CommunicationView")

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

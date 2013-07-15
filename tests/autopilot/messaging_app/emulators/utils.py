# -*- Mode: Python; coding: utf-8; indent-tabs-mode: nil; tab-width: 4 -*-
# Copyright 2012 Canonical
#
# This file is part of messaging-app.
#
# messaging-app is free software: you can redistribute it and/or modify it
# under the terms of the GNU General Public License version 3, as published
# by the Free Software Foundation.

class Utils(object):
    """Utility functions to write tests for messaging-app"""

    def __init__(self, app):
        self.app = app

    def get_tool_bar(self):
        """Returns the toolbar in the main events view."""
        return self.app.select_single("Toolbar")

    def get_tool_button(self, index):
        """Returns the toolbar button at position `index`"""
        tool_bar = self.get_tool_bar()
        buttons = tool_bar.select_many("Button")
        return buttons[index+1]

    def get_conversations_tab_button(self):
        return self.app.select_single("AbstractButton", buttonIndex=4)

    def get_conversations_pane(self):
        return self.app.select_single(
            "PageStack", objectName="communicationsStack")


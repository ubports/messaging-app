# -*- Mode: Python; coding: utf-8; indent-tabs-mode: nil; tab-width: 4 -*-
# Copyright 2012 Canonical
#
# This file is part of messaging-app.
#
# messaging-app is free software: you can redistribute it and/or modify it
# under the terms of the GNU General Public License version 3, as published
# by the Free Software Foundation.

"""Messaging App sms testing."""

from autopilot.input import Mouse, Touch, Pointer
from autopilot.matchers import Eventually
from autopilot.platform import model
from autopilot.testcase import AutopilotTestCase
from testtools.matchers import Equals, GreaterThan

from connected_tests.emulators.communication_panel import CommunicationPanel

import os
import shutil
import ConfigParser

config_file = os.path.expanduser('~/.testnumbers.cfg')


class MessagingAppTestCase(AutopilotTestCase):
    """A common test case class that provides several useful methods for
    Messaging App tests.

    """

    config = ConfigParser.ConfigParser()
    config.read(config_file)

    PHONE_NUMBER = config.get('connected_variables', 'dial_number')
    SEND_SMS_NUMBER = config.get('connected_variables', 'sms_send_number')
    RECEIVED_SMS_NUMBER = config.get('connected_variables', 'sms_receive_num')
    CALL_WAIT = config.getint('connected_variables', 'call_wait_time')
    CALL_DURATION = config.getint('connected_variables', 'outgoing_call_duration')
    SEND_SMS_TEXT = config.get('connected_variables', 'sms_send_text')
    RECEIVED_SMS_TEXT = config.get('connected_variables', 'sms_expect_text')
    TYPING_DELAY=0.01
    HOME = os.path.expanduser("~")
    BACKUP = HOME + "/.local/share/TpLogger/logs/ofono_ofono_account0.backup/"
    ORIGINAL = HOME + "/.local/share/TpLogger/logs/ofono_ofono_account0"
    SMS_POLLING_TIME = 5

    if model() == 'Desktop':
        scenarios = [('with mouse', dict(input_device_class=Mouse))]
    else:
        scenarios = [('with touch', dict(input_device_class=Touch))]

    local_location = "../../src/messaging-app"

    def setUp(self):
        self.pointing_device = Pointer(self.input_device_class.create())
        super(MessagingAppTestCase, self).setUp()
        self.delete_call_sms_logs()

        self.addCleanup(self.restore_call_sms_logs)

        if os.path.exists(self.local_location):
            self.launch_test_local()
        else:
            self.launch_test_installed()

        main_view = self.get_main_view()
        self.assertThat(main_view.visible, Eventually(Equals(True)))

    def launch_test_local(self):
        self.app = self.launch_test_application(
            self.local_location,
            app_type='qt')

    def launch_test_installed(self):
        if model() == 'Desktop':
            self.app = self.launch_test_application(
                "messaging-app",
                app_type='qt')
        else:
            self.app = self.launch_test_application(
                "messaging-app",
                "--desktop_file_hint=/usr/share/applications/messaging-app.desktop",
                app_type='qt')

    def get_main_view(self):
        return self.app.select_single("QQuickView")

    def get_tabs(self):
        """Returns the top tabs bar."""
        return self.app.select_single("NewTabBar")

    def get_conversations_tab_button(self):
        return self.app.select_single("AbstractButton", buttonIndex=4)

    def get_conversations_pane(self):
        return self.app.select_single(
            "PageStack", objectName="communicationsStack")

    def switch_to_conversation_tab(self):
        tabs_bar = self.get_tabs()
        conversation_pane = self.get_conversations_pane()
        self.pointing_device.click_object(tabs_bar)

        conversations_tab_button = self.get_conversations_tab_button()
        self.assertThat(conversations_tab_button.opacity,
                        Eventually(GreaterThan(0.35)))
        self.pointing_device.click_object(conversations_tab_button)

        self.assertThat(conversation_pane.isCurrent, Eventually(Equals(True)))

    def number_to_object_name(self, string):

        keys = {
            'buttonOne' : '1',
            'buttonTwo' : '2',
            'buttonThree' : '3',
            'buttonFour' : '4',
            'buttonFive' : '5',
            'buttonSix' : '6',
            'buttonSeven' : '7',
            'buttonEight' : '8',
            'buttonNine' : '9',
            'buttonZero' : '0',
            'buttonHash' : '#',
            'buttonAsterisk' : '*'
        }
        for key, value in keys.items():
            if value == string:
                return key

    def dial_number(self, number):
        for keys in str(number):
            objectName = self.number_to_object_name(keys)
            button = self.communication_panel.select_single_retry("KeypadButton", objectName=objectName)
            self.pointing_device.click_object(button)

    def reveal_toolbar(self):
        main_view = self.get_main_view()
        x_line = main_view.x + main_view.width * 0.5
        start_y = main_view.y + main_view.height - 1
        stop_y = start_y - 200
        self.pointing_device.drag(x_line, start_y, x_line, stop_y)

    def delete_call_sms_logs(self):
        if os.path.exists(self.ORIGINAL):
            shutil.move(self.ORIGINAL, self.BACKUP)
            self.assertThat(
                lambda: os.path.exists(self.BACKUP), Eventually(Equals(True)))
        else:
            pass

    def restore_call_sms_logs(self):
        if os.path.exists(self.BACKUP):
            shutil.rmtree(self.ORIGINAL)
            self.assertThat(lambda: os.path.exists(self.ORIGINAL), Eventually(Equals(False)))
            shutil.move(self.BACKUP, self.ORIGINAL)
            self.assertTrue(lambda: os.path.exists(self.ORIGINAL), Eventually(Equals(True)))
        else:
            pass
            
    @property
    def communication_panel(self):
        return CommunicationPanel(self.app)

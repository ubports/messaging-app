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

from messaging_app.tests import MessagingAppTestCase

import os
import shutil
import subprocess
import ConfigParser

# determine whether we are running with phonesim
try:
    out = subprocess.check_output(["/usr/share/ofono/scripts/list-modems"],
                                  stderr=subprocess.PIPE)
    if out.startswith("[ /phonesim ]"):
        print("ofono-phonesim is currently running, but this test is meant "
              "to run against real hardware. Please uninstall "
              "ofono-phonesim-autostart or run 'sudo stop ofono-phonesim'.")
except subprocess.CalledProcessError:
    pass

config_file = os.path.expanduser('~/.testnumbers.cfg')


class MessagingAppConnectedTestCase(MessagingAppTestCase):
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
        #self.delete_call_sms_logs()

        #self.addCleanup(self.restore_call_sms_logs)

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

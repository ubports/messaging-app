# -*- Mode: Python; coding: utf-8; indent-tabs-mode: nil; tab-width: 4 -*-
# Copyright 2012 Canonical
#
# This file is part of messaging-app.
#
# messaging-app is free software: you can redistribute it and/or modify it
# under the terms of the GNU General Public License version 3, as published
# by the Free Software Foundation.

"""Messaging App autopilot tests."""

from autopilot.input import Mouse, Touch, Pointer
from autopilot.matchers import Eventually
from autopilot.platform import model
from autopilot.testcase import AutopilotTestCase
from testtools.matchers import Equals, GreaterThan

from ubuntuuitoolkit import emulators as toolkit_emulators
from messaging_app import emulators

import os
import sys
from time import sleep
import logging
import subprocess

logger = logging.getLogger(__name__)

# ensure we have an ofono account; we assume that we have these tools,
# otherwise we consider this a test failure (missing dependencies)
def tp_has_ofono():
    mc_tool = subprocess.Popen(['mc-tool', 'list'], stdout=subprocess.PIPE,
                               universal_newlines=True)
    mc_accounts = mc_tool.communicate()[0]
    return 'ofono/ofono/account' in mc_accounts

if not tp_has_ofono():
    subprocess.check_call(['ofono-setup'])
    if not tp_has_ofono():
        sys.stderr.write('ofono-setup failed to create ofono account!\n')
        sys.exit(1)


class MessagingAppTestCase(AutopilotTestCase):
    """A common test case class that provides several useful methods for
    Messaging App tests.

    """

    if model() == 'Desktop':
        scenarios = [
            ('with mouse', dict(input_device_class=Mouse)),
        ]
    else:
        scenarios = [
            ('with touch', dict(input_device_class=Touch)),
        ]

    local_location = "../../src/messaging-app"

    def setUp(self):
        self.pointing_device = Pointer(self.input_device_class.create())
        super(MessagingAppTestCase, self).setUp()

        if os.path.exists(self.local_location):
            self.launch_test_local()
        else:
            self.launch_test_installed()

        self.assertThat(self.main_view.visible, Eventually(Equals(True)))

    def launch_test_local(self):
        self.app = self.launch_test_application(
            self.local_location,
            "--test-contacts",
            app_type='qt',
            emulator_base=toolkit_emulators.UbuntuUIToolkitEmulatorBase)

    def launch_test_installed(self):
        if model() == 'Desktop':
            self.app = self.launch_test_application(
                "messaging-app",
                "--test-contacts",
                emulator_base=toolkit_emulators.UbuntuUIToolkitEmulatorBase)
        else:
            self.app = self.launch_test_application(
               "messaging-app", 
               "--test-contacts",
               "--desktop_file_hint=/usr/share/applications/messaging-app.desktop",
               app_type='qt',
               emulator_base=toolkit_emulators.UbuntuUIToolkitEmulatorBase)

    @property
    def main_view(self):
        return self.app.select_single(emulators.MainView)

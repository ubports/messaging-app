# -*- Mode: Python; coding: utf-8; indent-tabs-mode: nil; tab-width: 4 -*-
# Copyright 2012-2014 Canonical
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
from testtools.matchers import Equals

from ubuntuuitoolkit import emulators as toolkit_emulators
from messaging_app import emulators, helpers

import os
import logging
import subprocess

logger = logging.getLogger(__name__)

# ensure we have an ofono account; we assume that we have these tools,
# otherwise we consider this a test failure (missing dependencies)
helpers.ensure_ofono_account()


class MessagingAppTestCase(AutopilotTestCase):
    """A common test case class that provides several useful methods for
    Messaging App tests.

    """

    # Don't use keyboard on desktop
    if model() == 'Desktop':
        try:
            subprocess.call(['/sbin/initctl', 'stop', 'maliit-server'])
        except:
            pass

    if model() == 'Desktop':
        scenarios = [
            ('with mouse', dict(input_device_class=Mouse)),
        ]
    else:
        scenarios = [
            ('with touch', dict(input_device_class=Touch)),
        ]

    local_location = '../../src/messaging-app'

    def setUp(self, parameter=""):
        self.pointing_device = Pointer(self.input_device_class.create())
        super(MessagingAppTestCase, self).setUp()

        subprocess.call(['pkill', 'messaging-app'])

        if os.path.exists(self.local_location):
            self.launch_test_local(parameter)
        else:
            self.launch_test_installed(parameter)

        self.assertThat(self.main_view.visible, Eventually(Equals(True)))

    def launch_test_local(self, parameter):
        self.app = self.launch_test_application(
            self.local_location,
            parameter,
            app_type='qt',
            emulator_base=toolkit_emulators.UbuntuUIToolkitEmulatorBase)

    def launch_test_installed(self, parameter):
        if model() == 'Desktop':
            self.app = self.launch_test_application(
                'messaging-app',
                parameter,
                emulator_base=toolkit_emulators.UbuntuUIToolkitEmulatorBase)
        else:
            self.app = self.launch_upstart_application(
                'messaging-app',
                parameter,
                emulator_base=toolkit_emulators.UbuntuUIToolkitEmulatorBase)

    @property
    def main_view(self):
        return self.app.select_single(emulators.MainView)

    def verify_thread(self, phone_num, message):
        """Check that the thread with given number and message exists"""
        # verify our number
        mess_thread = self.main_view.get_thread_from_number(phone_num)
        self.assertThat(mess_thread.phoneNumber, Equals(phone_num))
        # verify our text
        self.assertThat(mess_thread.textMessage, Equals(message))
        return mess_thread

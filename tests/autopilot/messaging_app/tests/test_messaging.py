# -*- Mode: Python; coding: utf-8; indent-tabs-mode: nil; tab-width: 4 -*-
# Copyright 2012 Canonical
#
# This file is part of messaging-app.
#
# messaging-app is free software: you can redistribute it and/or modify it
# under the terms of the GNU General Public License version 3, as published
# by the Free Software Foundation.

"""Tests for the Messaging App"""

from __future__ import absolute_import

from autopilot.matchers import Eventually
from testtools.matchers import Equals

from messaging_app.tests import MessagingAppTestCase


class TestMessaging(MessagingAppTestCase):
    """Tests for the communication panel."""

    def setUp(self):
        super(TestMessaging, self).setUp()

    def test_dummy(self):
        self.assertThat(True, Equals(True))

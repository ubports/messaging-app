# -*- Mode: Python; coding: utf-8; indent-tabs-mode: nil; tab-width: 4 -*-
# Copyright 2014 Canonical
#
# This file is part of messaging-app.
#
# messaging-app is free software: you can redistribute it and/or modify it
# under the terms of the GNU General Public License version 3, as published
# by the Free Software Foundation.

import dbus
import os
import subprocess
import shutil
import tempfile
import dbusmock
from autopilot.platform import model

import fixtures
from ubuntuuitoolkit import fixture_setup
from messaging_app import helpers


class MessagingTestEnvironment(fixtures.Fixture):

    def __init__(self, use_testdata_db=False, use_empty_config=False):
        self.use_testdata_db = use_testdata_db
        self.use_empty_config = use_empty_config

    def setUp(self):
        super(MessagingTestEnvironment, self).setUp()
        self.useFixture(OfonoPhoneSIM())
        if self.use_testdata_db:
            self.useFixture(FillCustomSmsHistory())
        else:
            self.useFixture(UseEmptySmsHistory())
        # check for the configuration file
        if self.use_empty_config:
            self.useFixture(UseEmptyConfiguration())
        else:
            self.useFixture(UseDefaultConfiguration())
        self.useFixture(RespawnService())
        self.useFixture(MockNotificationSystem())
        telephonyProtocolsDir = '/usr/share/telephony-service/protocols'
        self.useFixture(
            fixture_setup.InitctlEnvironmentVariable(
                TELEPHONY_SERVICE_PROTOCOLS_DIR=telephonyProtocolsDir)
        )
        self.useFixture(
            fixtures.EnvironmentVariable(
                'TELEPHONY_SERVICE_PROTOCOLS_DIR',
                newvalue=telephonyProtocolsDir)
        )


class FillCustomSmsHistory(fixtures.Fixture):

    history_service_dir = os.path.expanduser("~/.local/share/history-service/")
    history_db = "history.sqlite"
    testdata_sys = "/usr/lib/python3/dist-packages/messaging_app/testdata/"
    testdata_local = "messaging_app/testdata/"
    database_path = '/tmp/' + history_db

    prefilled_history_local = os.path.join(testdata_local, history_db)
    prefilled_history_system = os.path.join(testdata_sys, history_db)

    def setUp(self):
        super(FillCustomSmsHistory, self).setUp()
        self.addCleanup(self._clear_test_data)
        self.addCleanup(self._kill_service_to_respawn)
        self._clear_test_data()
        self._prepare_history_data()
        self._kill_service_to_respawn()
        self._start_service_with_custom_data()

    def _prepare_history_data(self):
        if os.path.exists(self.prefilled_history_local):
            shutil.copy(self.prefilled_history_local, self.database_path)
        else:
            shutil.copy(self.prefilled_history_system, self.database_path)

    def _clear_test_data(self):
        if os.path.exists(self.database_path):
            os.remove(self.database_path)

    def _kill_service_to_respawn(self):
        subprocess.call(['pkill', 'history-daemon'])

    def _start_service_with_custom_data(self):
        os.environ['HISTORY_SQLITE_DBPATH'] = self.database_path
        with open(os.devnull, 'w') as devnull:
            subprocess.Popen(['history-daemon'], stderr=devnull)


class UseEmptySmsHistory(FillCustomSmsHistory):
    database_path = ':memory:'

    def setUp(self):
        super(UseEmptySmsHistory, self).setUp()

    def _prepare_history_data(self):
        # just avoid doing anything
        self.database_path = ':memory:'

    def _clear_test_data(self):
        # don't do anything
        self.database_path = ''


class UseEmptyConfiguration(fixtures.Fixture):

    def setUp(self):
        super(UseEmptyConfiguration, self).setUp()
        self.user_config_dir = tempfile.mkdtemp(
            suffix='', prefix='messaging-app')
        self.app_config_dir = (
            self.user_config_dir + '/com.ubuntu.messaging-app/')
        os.makedirs(self.app_config_dir)
        self.useFixture(
            fixtures.EnvironmentVariable(
                'XDG_CONFIG_HOME', newvalue=self.user_config_dir)
        )
        self.useFixture(
            fixture_setup.InitctlEnvironmentVariable(
                XDG_CONFIG_HOME=self.user_config_dir)
        )

    def tearDown(self):
        super(UseEmptyConfiguration, self).tearDown()
        shutil.rmtree(self.user_config_dir)


class UseDefaultConfiguration(UseEmptyConfiguration):

    def setUp(self):
        super(UseDefaultConfiguration, self).setUp()
        config_file_path = (self.app_config_dir + '/MessagingApp.conf')
        with open(config_file_path, 'w') as config_file:
            config_file.write('[General]\nhintNecessary=false\n')


class RespawnService(fixtures.Fixture):

    def setUp(self):
        super(RespawnService, self).setUp()
        self.addCleanup(self._kill_services_to_respawn)
        self._kill_services_to_respawn()

    def _kill_services_to_respawn(self):
        subprocess.call(['pkill', '-f', 'telephony-service-handler'])
        # on desktop, notify-osd may generate persistent popups (like for "SMS
        # received"), don't make that stay around for the tests
        subprocess.call(['pkill', '-f', 'notify-osd'])


class OfonoPhoneSIM(fixtures.Fixture):

    def setUp(self):
        super(OfonoPhoneSIM, self).setUp()
        if not self._is_phonesim_running():
            raise RuntimeError('ofono-phonesim is not setup')
        self.addCleanup(self._restore_sim_connection)
        self._set_modem_on_phonesim()
        helpers.set_network_status("registered")

    def _is_phonesim_running(self):
        try:
            bus = dbus.SystemBus()
            manager = dbus.Interface(bus.get_object('org.ofono', '/'),
                                     'org.ofono.Manager')
            modems = manager.GetModems()
            for path, properties in modems:
                if path == '/phonesim':
                    return True
            return False
        except dbus.exceptions.DBusException:
            return False

    def _set_modem_on_phonesim(self):
        subprocess.call(
            ['mc-tool', 'update', 'ofono/ofono/account0',
             'string:modem-objpath=/phonesim'])
        subprocess.call(['mc-tool', 'reconnect', 'ofono/ofono/account0'])

    def _restore_sim_connection(self):
        subprocess.call(
            ['mc-tool', 'update', 'ofono/ofono/account0',
             'string:modem-objpath=/ril_0'])
        subprocess.call(['mc-tool', 'reconnect', 'ofono/ofono/account0'])


class MockNotificationSystem(fixtures.Fixture):

    def setUp(self):
        super().setUp()

        # only mock the notification system on desktop, on ubuntu touch the
        # notification dbus service is embedded into unity
        if model() == 'Desktop':
            self.addCleanup(self._stop_mock)
            self._kill_notification_service()
            # start the mock service
            (self.process, self.obj) = \
                dbusmock.DBusTestCase.spawn_server_template(
                    'notification_daemon')
        else:
            self.addCleanup(self._clear_existing_notifications)

    def _stop_mock(self):
        self.process.terminate()
        self.process.wait()

    def _kill_notification_service(self):
        """Kill the notification daemon."""
        subprocess.call(['pkill', '-f', 'notify-osd'])

    def _clear_existing_notifications(self):
        """Kill processes that might be displaying notifications"""
        bus = dbus.SessionBus()
        indicator = bus.get_object('com.canonical.TelephonyServiceIndicator',
                                   '/com/canonical/TelephonyServiceIndicator')
        indicator.ClearNotifications()


class UseMemoryContactBackend(fixtures.Fixture):

    def setUp(self):
        super().setUp()
        self.useFixture(
            fixtures.EnvironmentVariable(
                'QTCONTACTS_MANAGER_OVERRIDE', newvalue='memory')
        )
        self.useFixture(
            fixture_setup.InitctlEnvironmentVariable(
                QTCONTACTS_MANAGER_OVERRIDE='memory')
        )


class PreloadVcards(fixtures.Fixture):
    AUTOPILOT_DIR = "/usr/lib/python3/dist-packages/messaging_app"
    VCARD_PATH_BIN = ("%s/testdata/vcard.vcf" % AUTOPILOT_DIR)
    VCARD_PATH_DEV = os.path.abspath("../data/vcard.vcf")

    def setUp(self):
        super().setUp()
        vcard_full_path = PreloadVcards.VCARD_PATH_BIN
        if os.path.isfile(PreloadVcards.VCARD_PATH_DEV):
            vcard_full_path = PreloadVcards.VCARD_PATH_DEV

        self.useFixture(
            fixtures.EnvironmentVariable(
                'QTCONTACTS_PRELOAD_VCARD', newvalue=vcard_full_path)
        )
        self.useFixture(
            fixture_setup.InitctlEnvironmentVariable(
                QTCONTACTS_PRELOAD_VCARD=vcard_full_path)
        )

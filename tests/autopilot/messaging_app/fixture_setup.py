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

import fixtures


class MessagingTestEnvironment(fixtures.Fixture):

    def __init__(self, use_testdata_db=False):
        self.use_testdata_db = use_testdata_db

    def setUp(self):
        super(MessagingTestEnvironment, self).setUp()
        self.useFixture(OfonoPhoneSIM())
        self.useFixture(BackupHistory())
        if self.use_testdata_db:
            self.useFixture(FillCustomSmsHistory())
        self.useFixture(RespawnService())


class BackupHistory(fixtures.Fixture):

    def setUp(self):
        super(BackupHistory, self).setUp()
        self.addCleanup(self._restore_history)
        self._backup_history()

    def _backup_history(self):
        self.history = os.path.expanduser(
            '~/.local/share/history-service/history.sqlite')
        if os.path.exists(self.history):
            os.rename(self.history, self.history + '.orig')

    def _restore_history(self):
        try:
            os.unlink(self.history)
        except OSError:
            pass
        if os.path.exists(self.history + '.orig'):
            os.rename(self.history + '.orig', self.history)


class FillCustomSmsHistory(fixtures.Fixture):

    history_service_dir = os.path.expanduser("~/.local/share/history-service/")
    history_db = "history.sqlite"
    testdata_sys = "/usr/share/python3/dist-packages/messaging_app/testdata/"
    testdata_local = "messaging_app/testdata/"

    prefilled_history_local = os.path.join(testdata_local, history_db)
    prefilled_history_system = os.path.join(testdata_sys, history_db)

    def setUp(self):
        super(FillCustomSmsHistory, self).setUp()
        self.addCleanup(self._clear_test_data())
        self._copy_test_data_history()

    def _copy_test_data_history(self):
        if os.path.exists(self.prefilled_history_local):
            shutil.copy(
                self.prefilled_history_local, self.history_service_dir)
        else:
            shutil.copy(
                self.prefilled_history_system, self.history_service_dir)

    def _clear_test_data(self):
        test_data = os.path.join(self.history_service_dir, self.history_db)
        if os.path.exists(test_data):
            os.remove(test_data)


class RespawnService(fixtures.Fixture):

    def setUp(self):
        super(RespawnService, self).setUp()
        self.addCleanup(self._kill_services_to_respawn)
        self._kill_services_to_respawn()

    def _kill_services_to_respawn(self):
        subprocess.call(['pkill', 'history-daemon'])
        subprocess.call(['pkill', '-f', 'telephony-service-handler'])


class OfonoPhoneSIM(fixtures.Fixture):

    def setUp(self):
        super(OfonoPhoneSIM, self).setUp()
        if not self._is_phonesim_running():
            raise RuntimeError('ofono-phonesim is not setup')
        self.addCleanup(self._restore_sim_connection)
        self._set_modem_on_phonesim()

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

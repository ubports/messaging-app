# -*- Mode: Python; coding: utf-8; indent-tabs-mode: nil; tab-width: 4 -*-
# Copyright 2013, 2014 Canonical
#
# This file is part of messaging-app.
#
# messaging-app is free software: you can redistribute it and/or modify it
# under the terms of the GNU General Public License version 3, as published
# by the Free Software Foundation.


import fixtures
import subprocess
import os


class MessagingFixture(fixtures.Fixture):

    def setUp(self):
        super(MessagingFixture, self).setUp()
        self.setup_test_environment()
        self.addCleanup(self.cleanup_test_environment)

    def setup_test_environment(self):
        if self._is_phonesim_running():
            self._backup_history()
            self._kill_services_to_respawn()
            self._set_modem_on_phonesim()
        else:
            raise RuntimeError('ofono-phonesim not setup')

    def cleanup_test_environment(self):
        self._restore_history()
        self._kill_services_to_respawn()
        self._restore_sim_connection()

    def _is_phonesim_running(self):
        try:
            out = subprocess.check_output(
                ['/usr/share/ofono/scripts/list-modems'],
                stderr=subprocess.PIPE
            )
            return out.startswith('[ /phonesim ]')
        except subprocess.CalledProcessError:
            return False

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

    def _kill_services_to_respawn(self):
        subprocess.call(['pkill', 'history-daemon'])
        subprocess.call(['pkill', '-f', 'telephony-service-handler'])

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

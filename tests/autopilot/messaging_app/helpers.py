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
import shutil
import tempfile
import subprocess
import sys
import time

from dbus import exceptions


def set_network_status(status):
    status_number = 0
    if status == "registered":
        status_number = 1

    # prepare and send a Qt GUI script to phonesim, over its private D-BUS
    # set up by ofono-phonesim-autostart
    script_dir = tempfile.mkdtemp(prefix="phonesim_script")
    os.chmod(script_dir, 0o755)
    with open(os.path.join(script_dir, "registration.js"), "w") as f:
        f.write("""
tabRegistration.gbNetworkRegistration.cbRegistrationStatus.currentIndex = "%s";
tabRegistration.gbNetworkRegistration.pbRegistration.click();
""" % (status_number))

    with open("/run/lock/ofono-phonesim-dbus.address") as f:
        phonesim_bus = f.read().strip()
    bus = dbus.bus.BusConnection(phonesim_bus)
    script_proxy = bus.get_object("org.ofono.phonesim", "/")
    script_proxy.SetPath(script_dir)
    script_proxy.Run("registration.js")
    shutil.rmtree(script_dir)


def receive_sms(sender, text):
    """Receive an SMS based on sender number and text

    :parameter sender: phone number the message is from
    :parameter text: text you want to send in the message
    """

    # prepare and send a Qt GUI script to phonesim, over its private D-BUS
    # set up by ofono-phonesim-autostart
    script_dir = tempfile.mkdtemp(prefix="phonesim_script")
    os.chmod(script_dir, 0o755)
    with open(os.path.join(script_dir, "sms.js"), "w") as f:
        f.write("""tabSMS.gbMessage1.leMessageSender.text = "%s";
tabSMS.gbMessage1.leSMSClass.text = "1";
tabSMS.gbMessage1.teSMSText.setPlainText("%s");
tabSMS.gbMessage1.pbSendSMSMessage.click();
""" % (sender, text))

    with open("/run/lock/ofono-phonesim-dbus.address") as f:
        phonesim_bus = f.read().strip()
    bus = dbus.bus.BusConnection(phonesim_bus)
    script_proxy = bus.get_object("org.ofono.phonesim", "/")
    script_proxy.SetPath(script_dir)
    script_proxy.Run("sms.js")
    shutil.rmtree(script_dir)


def get_phonesim():
    bus = dbus.SystemBus()
    try:
        manager = dbus.Interface(bus.get_object('org.ofono', '/'),
                                 'org.ofono.Manager')
    except dbus.exceptions.DBusException:
        return False

    modems = manager.GetModems()

    for path, properties in modems:
        if path == '/phonesim':
            return properties

    return None


def is_phonesim_running():
    """Determine whether we are running with phonesim."""
    phonesim = get_phonesim()
    return phonesim is not None


def ensure_ofono_account():
    # oFono modems are now set online by NetworkManager, so for the tests
    # we need to manually put them online.
    subprocess.check_call(['/usr/share/ofono/scripts/enable-modem',
                           '/phonesim'])
    subprocess.check_call(['/usr/share/ofono/scripts/online-modem',
                           '/phonesim'])

    # wait until the modem is actually online
    for index in range(10):
        phonesim = get_phonesim()
        if phonesim['Online'] == 1:
            break
        time.sleep(1)
    else:
        raise exceptions.RuntimeError("oFono simulator didn't get online.")

    # this is a bit drastic, but sometimes mission-control-5 won't recognize
    # clients installed after it was started, so, we make sure it gets
    # restarted
    subprocess.check_call(['pkill', '-9', 'mission-control'])

    if not _is_ofono_account_set():
        subprocess.check_call(['ofono-setup'])
        if not _is_ofono_account_set():
            sys.stderr.write('ofono-setup failed to create ofono account!\n')
            sys.exit(1)


def _is_ofono_account_set():
    mc_tool = subprocess.Popen(
        [
            'mc-tool',
            'list'
        ], stdout=subprocess.PIPE, universal_newlines=True)
    mc_accounts = mc_tool.communicate()[0]
    return 'ofono/ofono/account' in mc_accounts

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


def tp_has_ofono():
    mc_tool = subprocess.Popen(['mc-tool', 'list'], stdout=subprocess.PIPE,
                                universal_newlines=True)
    mc_accounts = mc_tool.communicate()[0]
    return 'ofono/ofono/account' in mc_accounts


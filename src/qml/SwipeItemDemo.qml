/*
 * Copyright 2012-2016 Canonical Ltd.
 *
 * This file is part of dialer-app.
 *
 * dialer-app is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; version 3.
 *
 * dialer-app is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

import QtQuick 2.0
import QtQuick.Layouts 1.1
import Qt.labs.settings 1.0

import Ubuntu.Components 1.3
import Ubuntu.Contacts 0.1


Loader {
    id: root

    property bool necessary: true
    property bool enabled: false


    function enable() {
        root.enabled = true;
    }

    function disable() {
        if (root.enabled) {
            root.necessary = false;
            root.enabled = false;
        }
    }

    source: necessary && enabled ? Qt.resolvedUrl("ListItemDemo.qml") : ""
    asynchronous: true

    Binding {
        target: root.item
        property: "enabled"
        value: root.enabled
    }

    Connections {
        target: root.item
        onDisable: root.disable()
    }

    Settings {
        property alias hintNecessary: root.necessary
    }
}

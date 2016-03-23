/*
 * Copyright 2012-2015 Canonical Ltd.
 *
 * This file is part of messaging-app.
 *
 * messaging-app is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; version 3.
 *
 * messaging-app is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

import QtQuick 2.0
import Ubuntu.Components 1.3

UbuntuShape {
    id: thumbnail
    property string filePath

    signal pressAndHold()

    width: units.gu(8)
    height: units.gu(8)

    Icon {
        anchors.centerIn: parent
        width: units.gu(6)
        height: units.gu(6)
        name: "attachment"
    }
    MouseArea {
        anchors.fill: parent
        onPressAndHold: {
            mouse.accept = true
            thumbnail.pressAndHold()
        }
    }
}

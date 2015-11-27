/*
 * Copyright 2015 Canonical Ltd.
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

Item {
    id: button

    width: icon.width
    height: icon.height + label.height + spacing

    property alias iconName: icon.name
    property alias iconSource: icon.source
    property alias iconColor: icon.color
    property int iconSize: units.gu(2)
    property alias iconRotation: icon.rotation
    property alias text: label.text
    property alias textSize: label.font.pixelSize
    property int spacing: 0

    signal clicked()
    signal pressed()
    signal released()

    Icon {
        id: icon

        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
        }

        height: iconSize
        width: iconSize
        color: "gray"
        Behavior on rotation {
            UbuntuNumberAnimation { }
        }
    }

    MouseArea {
        anchors {
            fill: parent
            margins: units.gu(-2)
        }
        onClicked: {
            mouse.accepted = true
            button.clicked()
        }

        onPressed: button.pressed()
        onReleased: button.released()
    }

    Text {
        id: label
        color: "gray"
        height: text !== "" ? paintedHeight : 0
        anchors {
            left: parent.left
            right: parent.right
            bottom: parent.bottom
        }
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignBottom
        font.family: "Ubuntu"
        font.pixelSize: FontUtils.sizeToPixels("small")
    }
}

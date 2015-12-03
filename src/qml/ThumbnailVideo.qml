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
import Ubuntu.Thumbnailer 0.1

UbuntuShape {
    id: thumbnail
    property int index
    property string filePath

    signal pressAndHold()

    width: childrenRect.width
    height: childrenRect.height

    image: Image {
        id: videoImage
        width: units.gu(8)
        height: units.gu(8)
        sourceSize.width: width
        sourceSize.height: height
        fillMode: Image.PreserveAspectCrop
        source: "image://thumbnailer/" + filePath
        asynchronous: true

        onStatusChanged:  {
            if (status === Image.Error) {
                source = "image://theme/image-missing"
            }
        }
    }

    Icon {
        width: units.gu(3)
        height: units.gu(3)
        anchors.centerIn: parent
        name: "media-playback-start"
        color: "white"
        opacity: 0.8
    }

    MouseArea {
        anchors.fill: parent
        onPressAndHold: {
            mouse.accept = true
            thumbnail.pressAndHold()
        }
    }
}

/*
 * Copyright 2012, 2013, 2014 Canonical Ltd.
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
import Ubuntu.Components 1.1
import Ubuntu.Contacts 0.1
import ".."

MMSBase {
    id: imageDelegate
    property var attachment
    property bool incoming
    property string previewer: "MMS/PreviewerImage.qml"

    state: incoming ? "incoming" : "outgoing"
    states: [
        State {
            name: "incoming"
            AnchorChanges {
                target: bubble
                anchors.left: parent.left
                anchors.right: undefined
            }
            PropertyChanges {
                target: bubble
                anchors.leftMargin: units.gu(1)
                anchors.rightMargin: 0
            }
        },
        State {
            name: "outgoing"
            AnchorChanges {
                target: bubble
                anchors.left: undefined
                anchors.right: parent.right
            }
            PropertyChanges {
                target: bubble
                anchors.leftMargin: 0
                anchors.rightMargin: units.gu(1)
            }
        }
    ]

    height: imageAttachment.height
    UbuntuShape {
        id: bubble
        anchors {
            top: parent.top
            bottom: parent.bottom
            bottomMargin: units.gu(1) * -1
        }
        width: image.width
        height: image.height

        image: Image {
            id: imageAttachment

            readonly property bool portrait: sourceSize.height > sourceSize.width
            readonly property double deisiredHeight: portrait ?  units.gu(18) :  units.gu(14)

            height: sourceSize.height < deisiredHeight ? sourceSize.height : deisiredHeight
            fillMode: Image.PreserveAspectFit
            smooth: true
            source: attachment.filePath
            visible: false
        }
    }
}

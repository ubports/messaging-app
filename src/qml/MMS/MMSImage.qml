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
import Ubuntu.Components.ListItems 0.1 as ListItem
import ".."

ListItem.Empty {
    id: imageDelegate
    property var attachment
    property bool incoming
    property string previewer: "MMS/PreviewerImage.qml"
    anchors.left: parent.left
    anchors.right: parent.right
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
                anchors.rightMargin: units.gu(1)
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
                anchors.leftMargin: units.gu(1)
                anchors.rightMargin: units.gu(1)
            }
        }
    ]
    removable: true
    confirmRemoval: true
    height: bubble.height
    clip: true
    showDivider: false
    highlightWhenPressed: false
    MessageBubble {
        id: bubble
        incoming: imageDelegate.incoming
        anchors.top: parent.top
        width: image.width + units.gu(3)
        height: image.height + units.gu(2)

        Image {
            id: image
            anchors.centerIn: parent
            anchors.horizontalCenterOffset: incoming ? units.gu(0.5) : -units.gu(0.5)
            height: sourceSize.height < units.gu(20) ? sourceSize.height : units.gu(20)
            fillMode: Image.PreserveAspectFit
            asynchronous: true
            smooth: true
            source: attachment.filePath
        }
    }
}

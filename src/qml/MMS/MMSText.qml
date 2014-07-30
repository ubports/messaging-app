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
import Ubuntu.Components 0.1
import ".."

MMSBase {
    id: textDelegate
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
    height: bubble.height + units.gu(2)
    MessageBubble {
        id: bubble
        incoming: textDelegate.incoming
        anchors.top: parent.top
        messageText: attachment ? application.readTextFile(attachment.filePath) : ""
        messageTimeStamp: timestamp
    }
}

/*
 * Copyright 2012-2013 Canonical Ltd.
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

Item {
    id: messageDelegate
    property string message
    property bool incoming: false
    property variant timestamp
    property bool selected: false

    signal clicked(var mouse)

    anchors.left: parent ? parent.left : undefined
    anchors.right: parent ? parent.right: undefined

    height: bubble.height + units.gu(1)

    // FIXME: temporary solution to display selected messages
    Rectangle {
        anchors.fill: parent
        height: units.gu(2)
        width: units.gu(2)
        color: "gray"
        opacity: 0.3
        visible: selected
    }

    BorderImage {
        id: bubble

        anchors.left: incoming ? undefined : parent.left
        anchors.leftMargin: units.gu(1)
        anchors.right: incoming ? parent.right : undefined
        anchors.rightMargin: units.gu(1)
        anchors.top: parent.top

        function selectBubble() {
            var fileName = "assets/conversation_";
            if (incoming) {
                fileName += "incoming.sci";
            } else {
                fileName += "outgoing.sci";
            }
            return fileName;
        }

        source: selectBubble()

        height: messageText.height + units.gu(3)

        Label {
            id: messageText

            anchors.verticalCenter: parent.verticalCenter
            anchors.left: bubble.left
            anchors.leftMargin: bubble.border.left
            anchors.right: bubble.right
            anchors.rightMargin: bubble.border.right
            height: paintedHeight

            wrapMode: Text.WrapAtWordBoundaryOrAnywhere
            fontSize: "medium"
            color: incoming ? "#ffffff" : "#333333"
            opacity: incoming ? 1 : 0.9
            text: messageDelegate.message
        }
    }
}

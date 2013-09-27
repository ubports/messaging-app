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
import Ubuntu.Components.ListItems 0.1 as ListItem
import "dateUtils.js" as DateUtils

ListItem.Empty {
    id: messageDelegate
    property bool incoming: false
    property string textColor: incoming ? "#333333" : "#ffffff"

    anchors.left: parent ? parent.left : undefined
    anchors.right: parent ? parent.right: undefined
    height: bubble.height
    showDivider: false
    highlightWhenPressed: false

    backgroundIndicator: Rectangle {
        anchors.fill: parent
        color: Theme.palette.selected.base
        Label {
            text: i18n.tr("Delete")
            anchors {
                fill: parent
                margins: units.gu(2)
            }
            verticalAlignment: Text.AlignVCenter
            horizontalAlignment:  messageDelegate.swipingState === "SwipingLeft" ? Text.AlignLeft : Text.AlignRight
        }
    }

    onItemRemoved: {
        eventModel.removeEvent(accountId, threadId, eventId, type)
    }

    BorderImage {
        id: bubble

        anchors.left: incoming ? parent.left : undefined
        anchors.leftMargin: units.gu(1)
        anchors.right: incoming ? undefined : parent.right
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

        height: messageContents.height + units.gu(4)

        Item {
            id: messageContents
            anchors {
                top: parent.top
                topMargin: units.gu(2)
                left: parent.left
                leftMargin: incoming ? units.gu(3) : units.gu(2)
                right: parent.right
                rightMargin: units.gu(3)
            }
            height: childrenRect.height

            // TODO: to be used only on multiparty chat
            Label {
                id: senderName
                anchors.top: parent.top
                height: text == "" ? 0 : paintedHeight
                fontSize: "large"
                color: textColor
                text: ""
            }

            Label {
                id: date
                anchors.top: senderName.bottom
                height: paintedHeight
                fontSize: "x-small"
                color: textColor
                text: DateUtils.friendlyDay(timestamp) + " " + Qt.formatDateTime(timestamp, "hh:mm AP")
            }

            Label {
                id: messageText
                anchors.top: date.bottom
                anchors.topMargin: units.gu(1)
                anchors.left: parent.left
                anchors.right: parent.right
                height: paintedHeight
                wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                fontSize: "medium"
                color: textColor
                opacity: incoming ? 1 : 0.9
                text: textMessage
            }
        }
    }
}

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
import QtQuick 2.2
import Ubuntu.Components 1.1
import Ubuntu.Contacts 0.1

ListItemWithActions {
    id: baseDelegate

    property var attachment
    property bool parentSelected: false
    property bool incoming
    property bool showInfo: false

    signal itemRemoved()
    signal attachmentClicked()

    Component.onCompleted: {
        visibleAttachments++
    }
    Component.onDestruction:  {
        visibleAttachments--
    }

    leftSideAction: Action {
        iconName: "delete"
        text: i18n.tr("Delete")
        onTriggered: baseDelegate.itemRemoved()
    }

    color: parentSelected ? selectedColor : Theme.palette.normal.background
    states: [
        State {
            when: incoming
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
            when: !incoming
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

    onSwippingChanged: messageList.updateSwippedItem(baseDelegate)
    onSwipeStateChanged: messageList.updateSwippedItem(baseDelegate)
}

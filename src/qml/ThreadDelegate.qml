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
import Ubuntu.Components.Popups 0.1
import Ubuntu.Telephony 0.1

ListItem.Subtitled {
    //property bool selected: false
    property bool unknownContact: delegateHelper.contactId == ""
    property bool selectionMode: false
    anchors.left: parent.left
    anchors.right: parent.right
    height: units.gu(10)
    text: unknownContact ? delegateHelper.phoneNumber : delegateHelper.alias
    subText: eventTextMessage == undefined ? "" : eventTextMessage
    removable: !selectionMode
    icon: UbuntuShape {
        id: avatar
        height: units.gu(6)
        width: units.gu(6)
        image: Image {
            anchors.fill: parent
            source: {
                if(!unknownContact) {
                    if (delegateHelper.avatar != "") {
                        return delegateHelper.avatar
                    }
                }
                return Qt.resolvedUrl("assets/avatar-default.png")
            }
        }
        MouseArea {
            anchors.fill: avatar
            onClicked: {
                mainView.newPhoneNumber = delegateHelper.phoneNumber
                !selectionMode && PopupUtils.open(newcontactPopover, avatar)
            }
            enabled: unknownContact
        }
    }
    onClicked: {
        if (mainView.selectionMode) {
            selected = !selected
            if (selected) {
                selectionCount = selectionCount + 1
            } else {
                selectionCount = selectionCount - 1
            }
        } else {
            var properties = {}
            properties["threadId"] = threadId
            properties["number"] = participants[0]
            mainStack.push(Qt.resolvedUrl("Messages.qml"), properties)
        }
    }
    onPressAndHold: {
        mainView.selectionMode = true
        selected = true
        selectionCount = 1
    }

    Item {
        id: delegateHelper
        property alias phoneNumber: watcherInternal.phoneNumber
        property alias alias: watcherInternal.alias
        property alias avatar: watcherInternal.avatar
        property alias contactId: watcherInternal.contactId

        ContactWatcher {
            id: watcherInternal
            phoneNumber: participants[0]
        }

        Connections {
            target: mainView
            onSelectionModeChanged: {
                if (!selectionMode) {
                    selected = false
                }
            }
        }
    }
}

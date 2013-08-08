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
    id: delegate
    //property bool selected: false
    property bool unknownContact: delegateHelper.contactId == ""
    property bool selectionMode: false
    anchors.left: parent.left
    anchors.right: parent.right
    height: units.gu(10)
    text: unknownContact ? delegateHelper.phoneNumber : delegateHelper.alias
    subText: eventTextMessage == undefined ? "" : eventTextMessage
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
                if (selectionMode) {
                    delegate.clicked()
                } else {
                    PopupUtils.open(newcontactPopover, avatar)
                }
            }
            enabled: unknownContact
        }
    }

    onItemRemoved: {
        threadModel.removeThread(accountId, threadId, type)
    }

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
            horizontalAlignment:  delegate.swipingState === "SwipingLeft" ? Text.AlignLeft : Text.AlignRight
        }
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
    }
}

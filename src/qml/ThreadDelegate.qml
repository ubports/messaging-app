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
import Ubuntu.Contacts 0.1
import QtContacts 5.0

ListItem.Empty {
    id: delegate
    property bool unknownContact: delegateHelper.isUnknown
    property bool selectionMode: false
    anchors.left: parent.left
    anchors.right: parent.right
    height: units.gu(10)

    UbuntuShape {
        id: avatar
        height: units.gu(7)
        width: units.gu(7)
        radius: "medium"
        anchors {
            left: parent.left
            leftMargin: units.gu(1)
            verticalCenter: parent.verticalCenter
        }

        image: Image {
            anchors.fill: parent
            source: {
                if(!unknownContact) {
                    if (delegateHelper.avatar != "") {
                        return delegateHelper.avatar
                    }
                    return Qt.resolvedUrl("assets/avatar-default.png")
                }
                return Qt.resolvedUrl("assets/new-contact.svg")
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
            onPressAndHold: {
                mainView.newPhoneNumber = delegateHelper.phoneNumber
                if (!selectionMode) {
                    PopupUtils.open(newcontactPopover, avatar)
                }
            }
            enabled: unknownContact
        }
    }

    Label {
        id: contactName
        anchors {
            top: avatar.top
            left: avatar.right
            leftMargin: units.gu(2)
        }
        text: unknownContact ? delegateHelper.phoneNumber : delegateHelper.alias
    }

    Label {
        id: time
        anchors {
            verticalCenter: contactName.verticalCenter
            right: parent.right
            rightMargin: units.gu(3)
        }
        fontSize: "x-small"
        color: "gray"
        text: Qt.formatDateTime(eventTimestamp,"hh:mm AP")
    }

    Label {
        id: phoneType
        anchors {
            top: contactName.bottom
            left: contactName.left
        }
        text: delegateHelper.phoneNumberSubTypeLabel
        color: "gray"
        fontSize: "x-small"
    }

    Label {
        id: latestMessage
        height: units.gu(3)
        anchors {
            top: phoneType.bottom
            topMargin: units.gu(0.5)
            left: phoneType.left
            right: parent.right
            rightMargin: units.gu(3)
        }
        elide: Text.ElideRight
        maximumLineCount: 2
        fontSize: "x-small"
        wrapMode: Text.WordWrap
        text: eventTextMessage == undefined ? "" : eventTextMessage
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
        property alias subTypes: phoneDetail.subTypes
        property alias contexts: phoneDetail.contexts
        property alias isUnknown: watcherInternal.isUnknown
        property string phoneNumberSubTypeLabel: ""

        function updateSubTypeLabel() {
            phoneNumberSubTypeLabel = isUnknown ? "" : phoneTypeModel.get(phoneTypeModel.getTypeIndex(phoneDetail)).label
        }

        onSubTypesChanged: updateSubTypeLabel();
        onContextsChanged: updateSubTypeLabel();
        onIsUnknownChanged: updateSubTypeLabel();

        ContactWatcher {
            id: watcherInternal
            phoneNumber: participants[0]
        }

        PhoneNumber {
            id: phoneDetail
            contexts: watcherInternal.phoneNumberContexts
            subTypes: watcherInternal.phoneNumberSubTypes
        }

        ContactDetailPhoneNumberTypeModel {
            id: phoneTypeModel
        }
    }
}

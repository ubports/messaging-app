/*
 * Copyright 2012-2016 Canonical Ltd.
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
import Ubuntu.Components 1.3
import Ubuntu.Components.ListItems 1.3 as ListItem
import Ubuntu.Components.Popups 1.3
import Ubuntu.Contacts 0.1
import Ubuntu.Telephony 0.1

import "dateUtils.js" as DateUtils

Popover {
    id: participantsPopover

    property variant participants: []

    anchorToKeyboard: false
    Column {
        id: containerLayout
        anchors {
            left: parent.left
            top: parent.top
            right: parent.right
        }
        Repeater {
            model: participants
            Item {
                height: childrenRect.height
                width: participantsPopover.width
                ListItem.Standard {
                    id: participant
                    objectName: "participant%1".arg(index)
                    text: contactWatcher.isUnknown ? contactWatcher.identifier : contactWatcher.alias
                    onClicked: {
                        PopupUtils.close(participantsPopover)
                        mainView.startChat(contactWatcher.identifier)
                    }
                }
                ContactWatcher {
                    id: contactWatcher
                    identifier: modelData.identifier
                    contactId: modelData.contactId
                    alias: modelData.alias
                    avatar: modelData.avatar
                    detailProperties: modelData.detailProperties
                    
                    addressableFields: messages.account.addressableVCardFields
                }
            }
        }
    }
}

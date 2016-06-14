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
import Ubuntu.History 0.1
import Ubuntu.Telephony 0.1
import "dateUtils.js" as DateUtils

Column {
    id: regularDelegate
    height: childrenRect.height
    property var messageData: null
    property Item delegateItem
    property var timestamp: messageData.timestamp
    property string senderId: messageData.senderId
    property var textReadTimestamp: messageData.textReadTimestamp
    property int textMessageStatus: messageData.textMessageStatus
    property var textMessageAttachments: messageData.textMessageAttachments
    property bool newEvent: messageData.newEvent
    property var textMessage: messageData.textMessage
    property string accountId: messageData.accountId
    property int index: -1

    // WORKAROUND: we can not use sections because the verticalLayoutDirection is ListView.BottomToTop the sections will appear
    // bellow the item
    MessageDateSection {
        text: visible ? DateUtils.friendlyDay(timestamp) : ""
        anchors {
            left: parent.left
            right: parent.right
            leftMargin: units.gu(2)
            rightMargin: units.gu(2)
        }
        visible: (index === root.count) || !DateUtils.areSameDay(eventModel.get(index+1).timestamp, timestamp)
    }

    MessageDelegate {
        objectName: "message%1".arg(index)
        messageData: regularDelegate.messageData

        incoming: senderId != "self"
        // TODO: we have several items inside
        selected: root.isSelected(delegateItem)
        selectionMode: root.isInSelectionMode
        accountLabel: {
            var account = telepathyHelper.accountForId(accountId)
            if (account && (account.type == AccountEntry.PhoneAccount || account.type == AccountEntry.MultimediaAccount)) {
                if (multiplePhoneAccounts) {
                    return account.displayName
                }
            }
            return ""
        }

        // TODO: need select only the item
        onItemClicked: {
            if (root.isInSelectionMode) {
                if (!root.selectItem(delegateItem)) {
                    root.deselectItem(delegateItem)
                }
            }
        }
        onItemPressAndHold: {
            root.startSelection()
            root.selectItem(delegateItem)
        }
        Component.onCompleted: {
            if (newEvent) {
                messages.markMessageAsRead(accountId, threadId, eventId, type);
            }
        }
    }
}

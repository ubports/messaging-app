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
import Ubuntu.History 0.1
import "dateUtils.js" as DateUtils

Column {
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

    onIndexChanged: {
        messageData = listModel.get(index)
        if (newEvent) {
            messages.markMessageAsRead(accountId, threadId, eventId, type);
        }
    }
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

    MessageDelegateFactory {
        objectName: "message%1".arg(index)

        incoming: senderId != "self"
        // TODO: we have several items inside
        selected: root.isSelected(delegateItem)
        selectionMode: root.isInSelectionMode
        accountLabel: multipleAccounts ? telepathyHelper.accountForId(accountId).displayName : ""
        rightSideActions: {
            var actions = []
            if (textMessageStatus === HistoryThreadModel.MessageStatusPermanentlyFailed) {
                actions.push(reloadAction)
            }
            var hasTextAttachments = false
            for (var i=0; i < textMessageAttachments.length; i++) {
                if (startsWith(textMessageAttachments[i].contentType, "text/plain")) {
                    hasTextAttachments = true
                    break
                }
            }
            if (messageData.textMessage !== "" || hasTextAttachments) {
                actions.push(copyAction)
            }
            actions.push(infoAction)
            return actions
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

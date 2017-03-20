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
import Ubuntu.History 0.1
import Ubuntu.Telephony 0.1
import "dateUtils.js" as DateUtils

Item {
    id: regularDelegate
    height: messageDelegate.height + (headerLoader.active ? headerLoader.height : 0)
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
    property alias account: messageDelegate.account

    // WORKAROUND: we can not use sections because the verticalLayoutDirection is ListView.BottomToTop the sections will appear
    // bellow the item
    Loader {
        id: headerLoader
        anchors {
            left: parent.left
            right: parent.right
            leftMargin: units.gu(2)
            rightMargin: units.gu(2)
        }
        height: units.gu(3)
        // FIXME: for some reason eventModel.get() is pretty slow: around 4ms on krillin
        property var nextEventModel: eventModel.get(index+1)
        active: (index === root.count) || !DateUtils.areSameDay(nextEventModel.timestamp, timestamp)
        Component.onCompleted: setSource(Qt.resolvedUrl("MessageDateSection.qml"),
                                         {"text": Qt.binding(function () {return DateUtils.friendlyDay(timestamp, i18n)})})
    }

    MessageDelegate {
        id: messageDelegate
        objectName: "message%1".arg(index)
        anchors {
            top: headerLoader.active ? headerLoader.bottom : parent.top
            left: parent.left
            right: parent.right
        }

        messageData: regularDelegate.messageData

        incoming: senderId != "self"
        // TODO: we have several items inside
        selected: root.isSelected(delegateItem)
        selectMode: root.isInSelectionMode
        accountLabel: {
            var account = telepathyHelper.accountForId(accountId)
            // we only show those labels when using phone + fallback and when having multiple phone accounts
            if (account && (account.type == AccountEntry.PhoneAccount || account.protocolInfo.fallbackProtocol == "ofono")) {
                if (multiplePhoneAccounts) {
                    return account.displayName
                }
            }
            return ""
        }
        isMultimedia: {
            var account = telepathyHelper.accountForId(accountId)
            return account && account.type != AccountEntry.PhoneAccount
        }

        // TODO: need select only the item
        onClicked: {
            if (root.isInSelectionMode) {
                if (!root.selectItem(delegateItem)) {
                    root.deselectItem(delegateItem)
                }
            }
        }
        onPressAndHold: {
            root.startSelection()
            root.selectItem(delegateItem)
        }
    }
}

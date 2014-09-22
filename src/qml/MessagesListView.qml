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
import Ubuntu.History 0.1

import "dateUtils.js" as DateUtils

MultipleSelectionListView {
    id: root

    property var _currentSwipedItem: null
    property list<Action> _availableActions

    function updateSwippedItem(item)
    {
        if (item.swipping) {
            return
        }

        if (item.swipeState !== "Normal") {
            if (_currentSwipedItem !== item) {
                if (_currentSwipedItem) {
                    _currentSwipedItem.resetSwipe()
                }
                _currentSwipedItem = item
            }
        } else if (item.swipeState !== "Normal" && _currentSwipedItem === item) {
            _currentSwipedItem = null
        }
    }

    // fake bottomMargin
    header: Item {
        height: units.gu(1)
    }
    listModel: participants.length > 0 ? eventModel : null
    verticalLayoutDirection: ListView.BottomToTop
    highlightFollowsCurrentItem: true
    // this is to keep the scrolling smooth
    cacheBuffer: units.gu(10)*20
    currentIndex: 0
    _availableActions: [
        Action {
            id: reloadAction

            iconName: "reload"
            text: i18n.tr("Retry")
            onTriggered: value.resendMessage()
        },
        Action {
            id: copyAction

            iconName: "edit-copy"
            text: i18n.tr("Copy")
            onTriggered: value.copyMessage()
        },
        Action {
            id: infoAction

            iconName: "info"
            text: i18n.tr("Info")
            onTriggered: {
                var messageData = listModel.get(value._index)
                var messageType = messageData.textMessageAttachments.length > 0 ? i18n.tr("MMS") : i18n.tr("SMS")
                var messageInfo = {"type": messageType,
                                   "senderId": messageData.senderId,
                                   "timestamp": messageData.timestamp,
                                   "textReadTimestamp": messageData.textReadTimestamp,
                                   "status": messageData.textMessageStatus,
                                   "participants": messages.participants}
                messageInfoDialog.showMessageInfo(messageInfo)
            }
        }
    ]

    listDelegate: Loader {
        id: loader
        anchors.left: parent.left
        anchors.right: parent.right
        height: status == Loader.Ready ? item.height : 0
        
        sourceComponent: textMessageType == 2 ? sectionDelegate : regularMessageDelegate
        Binding {
            target: loader.item
            property: "messageData"
            value: listModel.get(index)
            when: (loader.status === Loader.Ready)
        }
        Binding {
            target: loader.item
            property: "index"
            value: index
            when: (loader.status === Loader.Ready)
        }
    }

    Component {
        id: sectionDelegate
        Label {
            property var messageData: null
            property int index: -1

            text: i18n.tr(messageData.textMessage).arg(TelepathyHelper.accountForId(accountId).displayName) + " @ " + DateUtils.formatLogDate(messageData.timestamp)
        }
    }

    Component {
        id: regularMessageDelegate
        Column {
        id: messageDelegate
        anchors.left: parent.left
        anchors.right: parent.right
        property var messageData: null
        property var timestamp: messageData.timestamp
        property string senderId: messageData.senderId
        property var textReadTimestamp: messageData.textReadTimestamp
        property int textMessageStatus: messageData.textMessageStatus
        property var textMessageAttachments: messageData.textMessageAttachments
        property bool newEvent: messageData.newEvent
        property string textMessage: messageData.textMessage
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

        MessageDelegateFactory {
            objectName: "message%1".arg(index)

            incoming: senderId != "self"
            // TODO: we have several items inside
            selected: root.isSelected(messageDelegate)
            selectionMode: root.isInSelectionMode
            accountLabel: multipleAccounts ? telepathyHelper.accountForId(accountId).displayName : ""
            rightSideActions: {
                var actions = []
                if (textMessageStatus === HistoryThreadModel.MessageStatusPermanentlyFailed) {
                    actions.push(reloadAction)
                }
                actions.push(copyAction)
                actions.push(infoAction)
                return actions
            }

            // TODO: need select only the item
            onItemClicked: {
                if (root.isInSelectionMode) {
                    if (!root.selectItem(messageDelegate)) {
                        root.deselectItem(messageDelegate)
                    }
                }
            }
            onItemPressAndHold: {
                root.startSelection()
                root.selectItem(messageDelegate)
            }
            Component.onCompleted: {
                if (newEvent) {
                    messages.markMessageAsRead(accountId, threadId, eventId, type);
                }
            }
        }
    }
    }

    onSelectionDone: {
        for (var i=0; i < items.count; i++) {
            var event = items.get(i).model
            eventModel.removeEvent(event.accountId, event.threadId, event.eventId, event.type)
        }
    }

    onCountChanged: {
        // list is in the bootom we should scroll to the new message
        if (Math.abs(height + contentY) < units.gu(3)) {
            currentIndex = 0
            positionViewAtBeginning()
        }
    }
}

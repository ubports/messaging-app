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
    listModel: participants.length > 0 ? sortProxy : null
    verticalLayoutDirection: ListView.BottomToTop
    highlightFollowsCurrentItem: true
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
                console.debug("Value:" + value._index)
                // FIXME: Is that the corect way to do that?
                var messageData = listModel.get(value._index)
                var messageType = messageData.textMessageAttachments.length > 0 ? i18n.tr("MMS") : i18n.tr("SMS")
                var messageInfo = {"type": messageType,
                                   "senderId": messageData.senderId,
                                   "timestamp": messageData.timestamp,
                                   "textReadTimestamp": messageData.textReadTimestamp,
                                   "status": messageData.textMessageStatus}
                messageInfoDialog.showMessageInfo(messageInfo)
            }
        }
    ]

    listDelegate: MessageDelegateFactory {
            id: messageDelegate
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
//                Component.onCompleted: {
//                    if (newEvent) {
//                        console.debug("New eventttttt")
//                        messages.markMessageAsRead(accountId, threadId, eventId, type);
//                    }
//                }
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

    SortProxyModel {
        id: sortProxy
        sourceModel: eventModel.filter ? eventModel : null
        sortRole: HistoryEventModel.TimestampRole
        ascending: false
    }
}

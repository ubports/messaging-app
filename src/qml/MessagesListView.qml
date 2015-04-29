/*
 * Copyright 2012-2015 Canonical Ltd.
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
import Ubuntu.Components.ListItems 0.1 as ListItem
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
        },
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
        }
    ]

    listDelegate: Loader {
        id: loader
        anchors.left: parent.left
        anchors.right: parent.right
        height: status == Loader.Ready ? item.height : 0
        
        Component.onCompleted: {
            var properties = {"messageData": model}
            var sourceFile = textMessageType == HistoryThreadModel.MessageTypeInformation ? "AccountSectionDelegate.qml" : "RegularMessageDelegate.qml"
            loader.setSource(sourceFile, properties)
        }

        Binding {
            target: loader.item
            property: "index"
            value: index
            when: (loader.status === Loader.Ready)
        }

        Binding {
            target: loader.item
            property: "delegateItem"
            value: loader
            when: (loader.status === Loader.Ready)
        }
    }

    onSelectionDone: {
        var removeDividers = (items.count == eventModel.count)
        var events = [];
        for (var i=0; i < items.count; i++) {
            var event = items.get(i).model
            if (!removeDividers && event.textMessageType == HistoryThreadModel.MessageTypeInformation) {
                continue;
            }
            events.push(event.properties);
        }
        if (events.length > 0) {
            eventModel.removeEvents(events);
        }
    }

    onCountChanged: {
        // list is in the bottom we should scroll to the new message
        if (Math.abs(height + contentY) < units.gu(3)) {
            currentIndex = 0
            positionViewAtBeginning()
        }
    }
}
